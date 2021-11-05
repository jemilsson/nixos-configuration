{ config, pkgs, stdenv, dpkg, fetchurl, autoPatchelfHook, gcc-unwrapped}:
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
      url = "https://packagecloud.io/fdio/release/packages/ubuntu/focal/libvppinfra_21.10-release_amd64.deb/download.deb";
      sha256 = "2bfce948b19c571bbd7ae4987fce71751419a5acc5066312f2d30c92f8a1c4f6";
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs = [
    autoPatchelfHook
  ];


    buildInputs = [ dpkg gcc-unwrapped] ; # qt5.qtbase qt5.qtserialport qt5.qtwebsockets  ];

    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir lib
      cp -r usr/lib/x86_64-linux-gnu/* lib/
      cp -r usr/* .
      cp -r . $out
    '';

}
