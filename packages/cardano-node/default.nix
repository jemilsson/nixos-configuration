# https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux
{ stdenv, fetchurl }:
#with import <nixpkgs> {};
let
  inherit (stdenv.lib) optional;
  hydra_build = "11955068";
in
stdenv.mkDerivation rec {
  version = "1.33.0";
  pname = "cardano-node";

  src = fetchurl {
    url = "https://hydra.iohk.io/build/${hydra_build}/download/1/${pname}-${version}-linux.tar.gz";
    sha256 = "1d357a8be28b157ef9e02c64fc0295259e1f2694cbb7316099edabb285c5a514";
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
