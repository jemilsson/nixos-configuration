#{ config, pkgs, stdenv, fetchurl, dpkg, gcc, libnl, libuuid, autoPatchelfHook, glibc, gcc-unwrapped}:
with import <nixpkgs> {};
let
version = "21.10";
name = "vpp-${version}";
libvppinfra = pkgs.callPackage ../libvppinfra/default.nix {};
vpp-plugin-core = pkgs.callPackage ../vpp-plugin-core/default.nix {};
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

    nativeBuildInputs = [
    autoPatchelfHook
    libvppinfra
    
    
  ];

    propagatedBuildInputs = [ 
      gcc 
      #libvppinfra 
    ];
    buildInputs = [ dpkg  gcc libnl libuuid  glibc gcc-unwrapped libvppinfra vpp-plugin-core] ; # qt5.qtbase qt5.qtserialport qt5.qtwebsockets ];

    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      rm usr/bin/vapi_cpp_test
      rm usr/bin/vapi_c_test
      cp -r usr/* .
      cp -r . $out
      
    '';

}
