{ pkgs, config, stdenv, fetchurl, dpkg, patchelf, lib, qt5, libXext, libX11, libXdmcp, libXdmcp, libxcb, ... }:
#with import <nixpkgs> {};

stdenv.mkDerivation rec {
  name = "deconz-${version}";
  version = "2.05.30";

  src = fetchurl {
    url = "https://www.dresden-elektronik.de/deconz/ubuntu/beta/${name}-qt5.deb";
    sha256 = "00s9g1hwpgpw4j94g9kc1v3d1naml1mnwcv6l8hdr6k7w7vla1xv";
  };

  buildInputs = [ dpkg ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  unpackPhase = "dpkg-deb -x $src .";
  installPhase = ''
    mv usr/bin .
    cp -r . $out

    ${patchelf}/bin/patchelf \
      --interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${lib.makeLibraryPath [ qt5.qtbase qt5.qtserialport.out stdenv.cc.cc.lib libXext libX11 libXdmcp libXdmcp libxcb ]}:$out/usr/lib" \
      $out/bin/deCONZ
  '';

  meta = with stdenv.lib; {
  };
}
