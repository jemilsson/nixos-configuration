# https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux
{ stdenv, fetchurl}:
#with import <nixpkgs> {};
let
  inherit (stdenv.lib) optional;
  hydra_build = "9808501";
in
stdenv.mkDerivation rec {
    version = "1.32.1";
    pname = "cardano-node";

    src = fetchurl {
      url = "https://hydra.iohk.io/build/${hydra_build}/download/1/${pname}-${version}-linux.tar.gz";
      sha256 = "b1d58b06daa011875098d9bc96ee5b42cf2ad9732c4e7b8254cd44b4ada46466";
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
