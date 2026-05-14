use std::env;
use std::io::{self, Read, Write};
use std::mem::ManuallyDrop;
use std::net::{Shutdown, TcpStream};
use std::thread;
use std::time::Duration;

use socket2::{Socket, TcpKeepalive};

// 64 KB: reduces syscall overhead on large transfers and lowers the frequency
// of backpressure stalls that can delay SSH ClientAlive responses.
const BUF_SIZE: usize = 64 * 1024;

fn connect(host: &str, port: &str) -> io::Result<TcpStream> {
    use std::net::ToSocketAddrs;

    let addr = format!("{host}:{port}")
        .to_socket_addrs()?
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "could not resolve address"))?;

    let socket = Socket::new(socket2::Domain::for_address(addr), socket2::Type::STREAM, None)?;
    socket.set_nodelay(true)?;

    let keepalive = TcpKeepalive::new()
        .with_time(Duration::from_secs(60))
        .with_interval(Duration::from_secs(30))
        .with_retries(5);
    socket.set_tcp_keepalive(&keepalive)?;

    // 1 MB kernel socket buffers reduce write() blocking under burst traffic.
    // Linux doubles the value internally; 1 MB hint yields ~2 MB actual buffer.
    socket.set_send_buffer_size(1024 * 1024)?;
    socket.set_recv_buffer_size(1024 * 1024)?;

    socket.connect(&addr.into())?;

    Ok(socket.into())
}

fn copy_stdin_to_tcp(mut stream: TcpStream) {
    let mut stdin = io::stdin().lock();
    let mut buf = [0u8; BUF_SIZE];
    loop {
        match stdin.read(&mut buf) {
            Ok(0) => break,
            Ok(n) => {
                if stream.write_all(&buf[..n]).is_err() {
                    break;
                }
            }
            Err(_) => break,
        }
    }
    // Half-close: signals the remote end we are done sending, which causes
    // it to close its end and unblocks the TCP→stdout thread.
    let _ = stream.shutdown(Shutdown::Write);
}

fn copy_tcp_to_stdout(mut stream: TcpStream) {
    use std::os::unix::io::FromRawFd;
    // SAFETY: fd 1 is stdout, valid for the process lifetime.
    // ManuallyDrop prevents closing fd 1 on drop while still freeing File's heap allocations.
    // File::write_all calls write() directly, bypassing LineWriter's newline-flush buffering.
    let mut stdout = ManuallyDrop::new(unsafe { std::fs::File::from_raw_fd(1) });
    let mut buf = [0u8; BUF_SIZE];
    loop {
        match stream.read(&mut buf) {
            Ok(0) => break,
            Ok(n) => {
                if stdout.write_all(&buf[..n]).is_err() {
                    break;
                }
            }
            Err(_) => break,
        }
    }
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Usage: nix-tcp-proxy <host> <port>");
        std::process::exit(1);
    }

    let stream = connect(&args[1], &args[2])?;
    let stream_for_stdout = stream.try_clone()?;
    let stream_for_stdin = stream;

    let t1 = thread::spawn(move || copy_stdin_to_tcp(stream_for_stdin));
    let t2 = thread::spawn(move || copy_tcp_to_stdout(stream_for_stdout));

    t1.join().ok();
    t2.join().ok();

    Ok(())
}
