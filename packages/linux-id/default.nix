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
    rev = "b520a6b3456181f56b08c18e2a274b147ada2d52";
    hash = "sha256-0RiOcOJ/HsBfeTSPgWZSS+YGFJCo/JK/dWuRRtUy0Og=";
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
