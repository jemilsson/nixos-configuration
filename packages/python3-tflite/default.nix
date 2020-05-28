#{ stdenv, lib, python37, fetchurl, python37Packages  }:
with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "tflite";
  version = "2.2.0";
  format = "wheel";

  disabled = !python37.pkgs.isPy3k;

  src = fetchurl {
    url = "https://dl.google.com/coral/python/tflite_runtime-2.1.0.post1-cp37-cp37m-linux_x86_64.whl";
    sha256 = "17g13d42dy4xxchryc67spqj7i14ilzclvar6g8b7ypz50adkb9d";
  };

  buildInputs = [ python37Packages.numpy];

  propagatedBuildInputs = [
    python37Packages.numpy
  ];

  checkPhase = ''
    python -c 'import tflite_runtime.interpreter'
  '';

  postFixup = let
    rpath = stdenv.lib.makeLibraryPath
      (
        [ stdenv.cc.cc.lib zlib ]
      );
  in
  ''
    rrPath="$out/${python.sitePackages}/tensorflow/:${rpath}"
    internalLibPath="$out/${python.sitePackages}/tensorflow/python/_pywrap_tensorflow_internal.so"
    find $out -name '*.so' -exec patchelf --set-rpath "$rrPath" {} \;
  '';

}
