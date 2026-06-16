mod debounce;

use debounce::{ButtonDebouncer, DebounceAction};
use evdev::{Device, EventType, InputEventKind, Key};
use evdev::uinput::VirtualDeviceBuilder;
use libudev::Context as UdevContext;
use log::{error, info, warn};
use nix::poll::{poll, PollFd, PollFlags};
use std::collections::HashMap;
use std::os::fd::BorrowedFd;
use std::os::unix::io::AsRawFd;
use std::time::{Duration, Instant};

const DEVICE_NAME_SUBSTR: &str = "Logitech MX Anywhere 3S";
// Buttons to debounce
const DEBOUNCE_KEYS: &[Key] = &[Key::BTN_LEFT, Key::BTN_RIGHT];
// Log T adaptation every N bounce events
const LOG_EVERY_N_BOUNCES: u64 = 100;

fn find_mouse_device() -> Option<String> {
    let ctx = UdevContext::new().ok()?;
    let mut enumerator = libudev::Enumerator::new(&ctx).ok()?;
    enumerator.match_subsystem("input").ok()?;
    let devices = enumerator.scan_devices().ok()?;

    for device in devices {
        if let Some(name) = device.property_value("NAME") {
            let name_str = name.to_string_lossy();
            if name_str.contains(DEVICE_NAME_SUBSTR) {
                if let Some(devnode) = device.devnode() {
                    let path = devnode.to_string_lossy().to_string();
                    // We want event devices, not mice/js
                    if path.contains("/event") {
                        info!("Found device: {} at {}", name_str, path);
                        return Some(path);
                    }
                }
            }
        }
    }
    None
}

fn open_and_grab(path: &str) -> Result<Device, Box<dyn std::error::Error>> {
    let mut dev = Device::open(path)?;
    dev.grab()?;
    Ok(dev)
}

fn build_virtual_device(
    source: &Device,
) -> Result<evdev::uinput::VirtualDevice, Box<dyn std::error::Error>> {
    let mut builder = VirtualDeviceBuilder::new()?.name("mx-debounce-virtual");

    // Forward key capabilities
    if let Some(keys) = source.supported_keys() {
        builder = builder.with_keys(keys)?;
    }
    // Forward relative axes
    if let Some(rel) = source.supported_relative_axes() {
        builder = builder.with_relative_axes(rel)?;
    }

    Ok(builder.build()?)
}

struct State {
    debounce: HashMap<u16, ButtonDebouncer>,
    last_log_bounce_count: HashMap<u16, u64>,
}

impl State {
    fn new() -> Self {
        let mut debounce = HashMap::new();
        let mut last_log = HashMap::new();
        for key in DEBOUNCE_KEYS {
            debounce.insert(key.0, ButtonDebouncer::new());
            last_log.insert(key.0, 0u64);
        }
        Self {
            debounce,
            last_log_bounce_count: last_log,
        }
    }

    fn reset_all(&mut self) {
        for db in self.debounce.values_mut() {
            db.reset();
        }
    }
}

fn now_us() -> u64 {
    static START: std::sync::OnceLock<Instant> = std::sync::OnceLock::new();
    let start = START.get_or_init(Instant::now);
    start.elapsed().as_micros() as u64
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let ctx = UdevContext::new()?;
    let mut udev_monitor = libudev::Monitor::new(&ctx)?;
    udev_monitor.match_subsystem("input")?;
    let mut udev_socket = udev_monitor.listen()?;

    loop {
        // --- Find and open device ---
        let path = loop {
            match find_mouse_device() {
                Some(p) => break p,
                None => {
                    warn!("Device '{}' not found; waiting 2s...", DEVICE_NAME_SUBSTR);
                    std::thread::sleep(Duration::from_secs(2));
                }
            }
        };

        let mut src = match open_and_grab(&path) {
            Ok(d) => d,
            Err(e) => {
                error!("Failed to open {}: {}; retrying...", path, e);
                std::thread::sleep(Duration::from_secs(2));
                continue;
            }
        };

        let mut virt = match build_virtual_device(&src) {
            Ok(d) => d,
            Err(e) => {
                error!("Failed to create virtual device: {}; retrying...", e);
                std::thread::sleep(Duration::from_secs(2));
                continue;
            }
        };

        info!("Opened and grabbed {}; virtual device created.", path);

        let mut state = State::new();
        let mut pending_events: Vec<evdev::InputEvent> = Vec::new();

        let src_fd = src.as_raw_fd();
        let udev_fd = udev_socket.as_raw_fd();

        'event_loop: loop {
            // Compute timeout: nearest pending deadline across all debouncers
            let now = now_us();
            let deadline = state
                .debounce
                .values()
                .filter_map(|db| db.pending_deadline_us())
                .min();

            let timeout_ms: i32 = match deadline {
                Some(dl) => {
                    if dl <= now {
                        0
                    } else {
                        let diff_us = dl - now;
                        ((diff_us / 1000) as i32).min(1000)
                    }
                }
                None => 1000,
            };

            // SAFETY: fds are valid for the duration of poll()
            let src_borrowed = unsafe { BorrowedFd::borrow_raw(src_fd) };
            let udev_borrowed = unsafe { BorrowedFd::borrow_raw(udev_fd) };
            let mut fds = [
                PollFd::new(&src_borrowed, PollFlags::POLLIN),
                PollFd::new(&udev_borrowed, PollFlags::POLLIN),
            ];

            match poll(&mut fds, timeout_ms) {
                Ok(_) => {}
                Err(nix::errno::Errno::EINTR) => continue,
                Err(e) => {
                    error!("poll error: {}", e);
                    break 'event_loop;
                }
            }

            // Handle pending timer expirations first
            let now = now_us();
            for (&key_code, db) in state.debounce.iter_mut() {
                if db.pending_deadline_us().map(|dl| dl <= now).unwrap_or(false) {
                    if let Some(val) = db.check_pending(now) {
                        pending_events.push(evdev::InputEvent::new(
                            EventType::KEY,
                            key_code,
                            val,
                        ));
                        log_adaptation_if_needed(
                            key_code,
                            db,
                            &mut state.last_log_bounce_count,
                        );
                    }
                }
            }

            // Flush timer-fired events + SYN
            if !pending_events.is_empty() {
                let events: Vec<_> = pending_events.drain(..).collect();
                virt.emit(&events)?;
                virt.emit(&[evdev::InputEvent::new(EventType::SYNCHRONIZATION, 0, 0)])?;
            }

            // Handle udev events
            if fds[1].revents().map(|r| r.contains(PollFlags::POLLIN)).unwrap_or(false) {
                while let Some(event) = udev_socket.receive_event() {
                    if event.event_type() == libudev::EventType::Remove {
                        if let Some(name) = event.property_value("NAME") {
                            if name.to_string_lossy().contains(DEVICE_NAME_SUBSTR) {
                                info!("Device removed; waiting for reconnect...");
                                state.reset_all();
                                break 'event_loop;
                            }
                        }
                    }
                }
            }

            // Handle input events
            if fds[0].revents().map(|r| r.contains(PollFlags::POLLIN)).unwrap_or(false) {
                let events: Vec<evdev::InputEvent> = match src.fetch_events() {
                    Ok(iter) => iter.collect(),
                    Err(e) => {
                        error!("fetch_events error: {}; reconnecting...", e);
                        break 'event_loop;
                    }
                };

                let mut batch: Vec<evdev::InputEvent> = Vec::new();
                let now = now_us();

                for event in events {
                    match event.kind() {
                        InputEventKind::Synchronization(_) => {
                            // Flush batch + SYN
                            if !batch.is_empty() {
                                let to_emit: Vec<_> = batch.drain(..).collect();
                                virt.emit(&to_emit)?;
                            }
                            virt.emit(&[evdev::InputEvent::new(
                                EventType::SYNCHRONIZATION,
                                0,
                                0,
                            )])?;
                        }
                        InputEventKind::Key(key) => {
                            if let Some(db) = state.debounce.get_mut(&key.0) {
                                match db.feed(event.value(), now) {
                                    DebounceAction::Emit(val) => {
                                        batch.push(evdev::InputEvent::new(
                                            EventType::KEY,
                                            key.0,
                                            val,
                                        ));
                                        log_adaptation_if_needed(
                                            key.0,
                                            db,
                                            &mut state.last_log_bounce_count,
                                        );
                                    }
                                    DebounceAction::Defer => {} // timer will fire
                                    DebounceAction::Swallow => {}
                                }
                            } else {
                                // Non-debounced key — passthrough
                                batch.push(event);
                            }
                        }
                        _ => {
                            // All other events (rel axes, abs, etc.) — passthrough
                            batch.push(event);
                        }
                    }
                }

                // Flush any remaining
                if !batch.is_empty() {
                    let to_emit: Vec<_> = batch.drain(..).collect();
                    virt.emit(&to_emit)?;
                    virt.emit(&[evdev::InputEvent::new(EventType::SYNCHRONIZATION, 0, 0)])?;
                }
            }
        }

        // Device lost — loop back to re-find
        std::thread::sleep(Duration::from_millis(500));
    }
}

fn log_adaptation_if_needed(
    key_code: u16,
    db: &ButtonDebouncer,
    last_log: &mut HashMap<u16, u64>,
) {
    let prev = last_log.get(&key_code).copied().unwrap_or(0);
    if db.bounce_count >= prev + LOG_EVERY_N_BOUNCES {
        info!(
            "key={} bounce_count={} adaptive_T={}us",
            key_code, db.bounce_count, db.t_us
        );
        last_log.insert(key_code, db.bounce_count);
    }
}

fn main() {
    env_logger::init();
    info!("mx-debounce starting");
    if let Err(e) = run() {
        error!("Fatal: {}", e);
        std::process::exit(1);
    }
}
