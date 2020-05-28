{ stdenv, lib, python37, fetchurl, python37Packages, zlib, pkgs }:
#with import <nixpkgs> {};
let
  python3-edgetpu = pkgs.callPackage ../python3-edgetpu/default.nix {};
  libedgetpu-dev = pkgs.callPackage ../libedgetpu-dev/default.nix {};
  libedgetpu-max = pkgs.callPackage ../libedgetpu-max/default.nix {};
in
python37.pkgs.buildPythonPackage rec {
  pname = "tflite";
  version = "2.2.0";
  format = "wheel";

  disabled = !python37.pkgs.isPy3k;

  src = fetchurl {
    url = "https://dl.google.com/coral/python/tflite_runtime-2.1.0.post1-cp37-cp37m-linux_x86_64.whl";
    sha256 = "17g13d42dy4xxchryc67spqj7i14ilzclvar6g8b7ypz50adkb9d";
  };

  buildInputs = [ python37Packages.numpy ];

  propagatedBuildInputs = [
    python37Packages.numpy python3-edgetpu
    libedgetpu-dev
    libedgetpu-max
  ];

  checkPhase = ''
    python -c 'import tflite_runtime.interpreter'
  '';

  postFixup = let
    rpath = stdenv.lib.makeLibraryPath
      (
        [ stdenv.cc.cc.lib zlib python3-edgetpu libedgetpu-dev libedgetpu-max]
      );
  in
  ''
    rrPath="$out/${python37.sitePackages}/tflite_runtime/:${rpath}"
    internalLibPath="$out/${python37.sitePackages}/tensorflow/python/_pywrap_tensorflow_internal.so"
    find $out -name '*.so' -exec patchelf --set-rpath "$rrPath" {} \;
  '';

}
