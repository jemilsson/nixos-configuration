{ config, pkgs, stdenv, fetchurl, dpkg}:
#with import <nixpkgs> {};
let
version = "21.10";
name = "vpp-${version}";
libvppinfra = pkgs.callPackage ../libvppinfra/default.nix {};
in
stdenv.mkDerivation {
    #builder = ./builder.sh;
    inherit name;
    dpkg = dpkg;
    src = fetchurl {
      url = "https://packagecloud.io/fdio/release/packages/ubuntu/focal/vpp_21.10-release_amd64.deb/download.deb";
      sha256 = "a90589b6783b3c00c0638361e1407fc39c4c99a56b0975a40e1f8d3b906668aa";
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    buildInputs = [ dpkg libvppinfra gcc libnl libuuid] ; # qt5.qtbase qt5.qtserialport qt5.qtwebsockets ];

    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      cp -r usr/* .
      cp -r . $out
    '';

}
