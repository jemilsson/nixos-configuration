{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "nix-tcp-proxy";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  meta = with lib; {
    description = "TCP ProxyCommand for SSH with SO_KEEPALIVE, replacing nc";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "nix-tcp-proxy";
  };
}
