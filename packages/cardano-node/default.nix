# https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux
{ stdenv, fetchurl }:
#with import <nixpkgs> {};
let
  inherit (stdenv.lib) optional;
  hydra_build = "13065769";
in
stdenv.mkDerivation rec {
  version = "1.34.1";
  pname = "cardano-node";

  src = fetchurl {
    url = "https://hydra.iohk.io/build/${hydra_build}/download/1/${pname}-${version}-linux.tar.gz";
    sha256 = "5621ca7229d1e4c0eeb2e8eb1230b7620eabe1788e3de43d88c1e86c68b341aa";
  };
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  sourceRoot = ".";
  buildInputs = [ ];

  installPhase = ''
    mkdir -p $out/bin/
    mv configuration/ $out/
    cp -r .  $out/bin/
  '';

}
