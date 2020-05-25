{ stdenv, fetchurl, dpkg   }:
#with import <nixpkgs> {};
stdenv.mkDerivation{
  name = "libedgetpu-max_14";
  src = fetchurl {
    url = "https://packages.cloud.google.com/apt/pool/libedgetpu1-max_14.0_amd64_fcccc7efe1c99f746efa3576e2484f0b23aa8164c7bebeda2d16c46e86985416.deb";
    sha256 = "fcccc7efe1c99f746efa3576e2484f0b23aa8164c7bebeda2d16c46e86985416";
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
