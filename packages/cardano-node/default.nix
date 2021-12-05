# https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux
{ stdenv, fetchurl}:
#with import <nixpkgs> {};
let
  inherit (stdenv.lib) optional;
  hydra_build = "8674953";
in
stdenv.mkDerivation rec {
    version = "1.31.0";
    pname = "cardano-node";

    src = fetchurl {
      url = "https://hydra.iohk.io/build/${hydra_build}/download/1/${pname}-${version}-linux.tar.gz";
      sha256 = "519df3fe364c6aec75b4c727857d5c0a0211b945c1b47d96bd09b27ebc212b33";
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
