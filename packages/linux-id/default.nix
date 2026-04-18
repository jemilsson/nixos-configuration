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
    rev = "045521650fd5b9eb28d0327ff8079f44f8ec0c49";
    hash = "sha256-Lc1Nu+gdRkPrf1VrGJOguTRs19n6640DP5NsGGiA0Wo=";
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
