{ stdenv, fetchurl }:
#with import <nixpkgs> { };
let
  inherit (stdenv.lib) optional;
  owner = "vacuumlabs";
  pname = "cardano-hw-cli";
  version = "v1.9.1";
in
stdenv.mkDerivation rec {
  inherit pname version;
  src = fetchurl {
    url = "https://github.com/vacuumlabs/cardano-hw-cli/releases/download/${version}/cardano-hw-cli-1.9.1_linux-x64.tar.gz";
    sha256 = "e08CKVdvMWdmM/qhtH9xRusWfkxp52B2fYt30+Su9G0=";
  };
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    gcc-unwrapped
    libusb
  ];

  sourceRoot = "cardano-hw-cli/";
  buildInputs = [ ];

  installPhase = ''
    mkdir -p $out/bin/
    cp -r ./  $out/bin/
  '';

}
