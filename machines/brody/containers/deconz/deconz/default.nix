{ pkgs, config, stdenv, fetchurl, dpkg, autoPatchelfHook, lib, qt5, sqlite, ... }:
#with import <nixpkgs> {};

stdenv.mkDerivation rec {
  name = "deconz-${version}";
  version = "2.05.30";

  src = fetchurl {
    url = "https://www.dresden-elektronik.de/deconz/ubuntu/beta/${name}-qt5.deb";
    sha256 = "00s9g1hwpgpw4j94g9kc1v3d1naml1mnwcv6l8hdr6k7w7vla1xv";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ dpkg qt5 sqlite ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  unpackPhase = "dpkg-deb -x $src .";
  installPhase = ''
    mv usr/bin .
    cp -r . $out
  '';

  meta = with stdenv.lib; {
  };
}
