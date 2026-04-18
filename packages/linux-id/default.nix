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
    rev = "1d8d77bd455706ca41cf718b77c3fa1fefe6b858";
    hash = "sha256-4mN12QuwkdiXzieDSTSycsvbGcI92Rd+DT1fw+alEQY=";
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
