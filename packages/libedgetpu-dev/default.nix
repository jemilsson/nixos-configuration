{ stdenv, fetchurl, dpkg   }:
#with import <nixpkgs> {};
stdenv.mkDerivation{
  name = "libedgetpu-dev_14";
  src = fetchurl {
    url = "https://packages.cloud.google.com/apt/pool/libedgetpu-dev_14.0_amd64_97847d5e56210d615eedd6386014bd3ddc982aaab876be5461fa8c5027a648f3.deb";
    sha256 = "97847d5e56210d615eedd6386014bd3ddc982aaab876be5461fa8c5027a648f3";
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
