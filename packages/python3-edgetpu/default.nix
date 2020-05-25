#{ stdenv, fetchurl, dpkg   }:
with import <nixpkgs> {};
stdenv.mkDerivation{
  name = "libedgetpu-max_14";
  src = fetchurl {
    url = "https://packages.cloud.google.com/apt/pool/python3-edgetpu_14.0_amd64_1131406b35ed7ea4c478aa8953250bd271a0a4218ef15641b4bc8bc1becaae42.deb";
    sha256 = "1131406b35ed7ea4c478aa8953250bd271a0a4218ef15641b4bc8bc1becaae42";
  };
  buildInputs = [ dpkg ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
  cp -r usr/* .
  cp -r . $out
  '';
  doCheck = false;
}
