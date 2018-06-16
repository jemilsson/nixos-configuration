{ pkgs, config, stdenv, fetchurl, dpkg, patchelf, ... }:
#with import <nixpkgs> {};

stdenv.mkDerivation rec {
  name = "deconz-${version}";
  version = "2.05.30";

  src = fetchurl {
    url = "https://www.dresden-elektronik.de/deconz/ubuntu/beta/${name}-qt5.deb";
    sha256 = "1hjw3mq2kjbl7k9vccxl7f2alglxg0y1c4d1znvq1a4m478af57j";
  };

  buildInputs = [ dpkg ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = "dpkg-deb -x $src .";
  installPhase = ''
    mv usr/bin .
    cp -r . $out

    ${patchelf}/bin/patchelf \
      --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${lib.makeLibraryPath [  ]}" \
      $out/bin/deCONZ
  '';

  meta = with stdenv.lib; {
  };
}
