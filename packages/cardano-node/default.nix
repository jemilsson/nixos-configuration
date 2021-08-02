{ stdenv, fetchurl}:
#with import <nixpkgs> {};
let
  inherit (stdenv.lib) optional;
in
stdenv.mkDerivation rec {
    version = "1.27.0";
    pname = "cardano-node";

    src = fetchurl {
      url = "https://hydra.iohk.io/build/6263009/download/1/${pname}-${version}-linux.tar.gz";
      sha256 = "be764f62efacc0980db827da8d84c7c9d06f613bc371e1557309cce63692e2ac";
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
