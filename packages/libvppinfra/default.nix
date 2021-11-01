{ config, pkgs, stdenv, dpkg, fetchurl}:
#with import <nixpkgs> {};
let
version = "21.10";
name = "libvppinfra-${version}";

in
stdenv.mkDerivation {
    #builder = ./builder.sh;
    inherit name;
    dpkg = dpkg;
    src = fetchurl {
      url = "https://packagecloud.io/fdio/release/packages/ubuntu/focal/libvppinfra_21.10-release_arm64.deb/download.deb";
      sha256 = "ad19ec3e87237e7e2402b1e69d9496c953a71a9a744ec69dcc98ab5d418963de";
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    buildInputs = [ dpkg] ; # qt5.qtbase qt5.qtserialport qt5.qtwebsockets ];

    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      cp -r usr/* .
      cp -r . $out
    '';

}
