use std::env;
use std::io::{self, Read, Write};
use std::net::{Shutdown, TcpStream};
use std::thread;
use std::time::Duration;

use socket2::{Socket, TcpKeepalive};

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

    socket.connect(&addr.into())?;

    Ok(socket.into())
}

fn copy_stdin_to_tcp(mut stream: TcpStream) {
    let mut stdin = io::stdin().lock();
    let mut buf = [0u8; 8192];
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
    let mut stdout = io::stdout().lock();
    let mut buf = [0u8; 8192];
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
