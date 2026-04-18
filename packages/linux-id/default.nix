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
    rev = "a4261530919cba626819668322e72cd3921f7d5c";
    hash = "sha256-003UCeVi00I8VdBAE1JMEX63HnbOJm2kD3U+232GXmc=";
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
