{ config, pkgs, stdenv, buildFHSUserEnv, fetchurl, dpkg, qt5, sqlite, hicolor_icon_theme, libcap, libpng,   ... }:
#ith import <nixpkgs> {};
let
version = "2.09.00";
name = "deconz-${version}";
in
rec {
  deCONZ-deb = stdenv.mkDerivation {
    #builder = ./builder.sh;
    inherit name;
    dpkg = dpkg;
    src = fetchurl {
      url = "https://deconz.dresden-elektronik.de/ubuntu/beta/${name}-qt5.deb";
      sha256 = "ed89af827266072957cb8e92d5ca9faee8d728d4b53fe00a6f599d4ebf89ba80";
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    buildInputs = [ dpkg qt5.qtbase qt5.qtserialport qt5.qtwebsockets sqlite hicolor_icon_theme libcap libpng ];

    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      cp -r usr/* .
      cp -r share/deCONZ/plugins/* lib/
      cp -r . $out
    '';

  };
  deCONZ = buildFHSUserEnv {
    name = "deCONZ";
    targetPkgs = pkgs: [
      deCONZ-deb
    ];
    multiPkgs = pkgs: [
      dpkg
      qt5.qtbase
      qt5.qtserialport
      qt5.qtwebsockets
      sqlite
      hicolor_icon_theme
      libcap
      libpng
    ];
    runScript = "deCONZ";
  };
}
