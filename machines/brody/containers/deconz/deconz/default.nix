{ pkgs, config, stdenv, fetchurl, ... }:
#with import <nixpkgs> {};

stdenv.mkDerivation rec {
  name = "deconz-${version}";
  version = "2.05.29";

  src = fetchurl {
    url = "https://www.dresden-elektronik.de/deconz/ubuntu/beta/${name}-qt5.deb";
    sha256 = "1hjw3mq2kjbl7k9vccxl7f2alglxg0y1c4d1znvq1a4m478af57j";
  };

  buildInputs = [ dpkg ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = "dpkg-deb -x $src .";
  installPhase = "
    mv usr/bin .
    cp -r . $out
  ";

  meta = with stdenv.lib; {
  };
}
