{ config, pkgs, stdenv, buildFHSUserEnv, fetchurl, dpkg, qt5, sqlite, hicolor_icon_theme, libcap, libpng,   ... }:
#ith import <nixpkgs> {};
let
version = "2.05.30";
name = "deconz-${version}";
in
rec {
  deCONZ-deb = stdenv.mkDerivation {
    #builder = ./builder.sh;
    inherit name;
    dpkg = dpkg;
    src = fetchurl {
      url = "https://www.dresden-elektronik.de/deconz/ubuntu/beta/${name}-qt5.deb";
      sha256 = "00s9g1hwpgpw4j94g9kc1v3d1naml1mnwcv6l8hdr6k7w7vla1xv";
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    buildInputs = [ dpkg qt5.qtbase qt5.qtserialport qt5.qtwebsockets sqlite hicolor_icon_theme libcap libpng ];

    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mv usr/* .
      cp share/deCONZ/plugins/* lib/
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
