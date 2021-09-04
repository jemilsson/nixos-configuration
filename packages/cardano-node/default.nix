{ stdenv, fetchurl}:
#with import <nixpkgs> {};
let
  inherit (stdenv.lib) optional;
  hydra_build = "7408438";
in
stdenv.mkDerivation rec {
    version = "1.29.0";
    pname = "cardano-node";

    src = fetchurl {
      url = "https://hydra.iohk.io/build/${hydra_build}/download/1/${pname}-${version}-linux.tar.gz";
      sha256 = "1q08bf0ndk6d0052fmjvra44jdsddkkszzgh3gxrqvnkx9fvc5av";
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
