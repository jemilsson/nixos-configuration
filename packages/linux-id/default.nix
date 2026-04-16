{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule {
  pname = "linux-id";
  version = "0-unstable-2026-04-17";

  src = fetchFromGitHub {
    owner = "jemilsson";
    repo = "linux-id";
    rev = "dae70b83796592fa9b11c505baeb34a236cfb6f0";
    hash = "sha256-oPwFFixkzEpvNA91/vFOT+YUAZ8tDYvSRQXHlGya3zo=";
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
