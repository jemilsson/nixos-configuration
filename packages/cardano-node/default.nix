# https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux
{ stdenv, fetchurl}:
#with import <nixpkgs> {};
let
  inherit (stdenv.lib) optional;
  hydra_build = "7501993";
in
stdenv.mkDerivation rec {
    version = "1.29.0";
    pname = "cardano-node";

    src = fetchurl {
      url = "https://hydra.iohk.io/build/${hydra_build}/download/1/${pname}-${version}-linux.tar.gz";
      sha256 = "0gqpw0la69mj4ax23bqqzgkmgb0c9f0y4ghj2ihn8ik4bcdjywr9";
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
