{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:

buildGoModule {
  pname = "linux-id";
  version = "0-unstable-2026-04-11";

  src = fetchFromGitHub {
    owner = "jemilsson";
    repo = "linux-id";
    rev = "9fe8143d59e420403116113967d5839da02c9189";
    hash = "sha256-kldjAlU+qLcpEqfwVlFQp7y0Wv25nmVm6cOqdseqBEs=";
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
