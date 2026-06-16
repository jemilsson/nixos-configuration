{ lib, rustPlatform, pkg-config, udev }:

rustPlatform.buildRustPackage {
  pname = "mx-debounce";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ udev ];

  meta = {
    description = "Adaptive evdev debounce daemon for Logitech MX Anywhere 3S";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "mx-debounce";
  };
}
