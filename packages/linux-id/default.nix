{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule {
  pname = "linux-id";
  version = "0-unstable-2026-04-18";

  src = fetchFromGitHub {
    owner = "jemilsson";
    repo = "linux-id";
    rev = "b761a31513d5305f5f2f0d5da5b2ba5551664580";
    hash = "sha256-f4bQI5MowjWwiE2iyiFABdMeNAMQoFSIAmZFXxCIv24=";
  };

  vendorHash = "sha256-HwLcsjzaFqc0aQrTCoSUdes6ZlnsNZJCdtjwucFyOQ4=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "FIDO2/U2F token with CTAP2 support, protected by a TPM";
    homepage = "https://github.com/jemilsson/linux-id";
    license = lib.licenses.mit;
    mainProgram = "linux-id";
  };
}
