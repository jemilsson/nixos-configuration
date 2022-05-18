{ config, pkgs, stdenv, dpkg, fetchurl, autoPatchelfHook, gcc-unwrapped, openssl, elfutils, mbedtls}:
#with import <nixpkgs> {};
let
version = "21.10";
name = "vpp-plugin-core_${version}";

in
stdenv.mkDerivation {
    #builder = ./builder.sh;
    inherit name;
    dpkg = dpkg;
    src = fetchurl {
      url = "https://packagecloud.io/fdio/release/packages/ubuntu/focal/${name}-release_amd64.deb/download.deb";
      #https://packagecloud.io/fdio/release/packages/ubuntu/focal/vpp-plugin-core_21.10-release_amd64.deb/download.deb
      sha256 = "fc37000564f862c264ac8a26e849530cfe14475f78bb58ba15db1ce5d1fd53a8";
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs = [
    autoPatchelfHook
    
  ];
  autoPatchelfIgnoreMissingDeps=true;



    buildInputs = [ dpkg gcc-unwrapped openssl elfutils mbedtls] ; # qt5.qtbase qt5.qtserialport qt5.qtwebsockets  ];

    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir lib
      cp -r usr/lib/x86_64-linux-gnu/* lib/
      cp -r usr/* .
      cp -r . $out
    '';

}
