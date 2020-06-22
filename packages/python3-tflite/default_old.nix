# { stdenv, lib, python37, fetchurl, python37Packages  }:
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

  buildInputs = [ python37Packages.numpy python37Packages.pip  glibcLocales];

  propagatedBuildInputs = [
    python37Packages.numpy
  ];

  checkPhase = ''
    python -c 'import tflite_runtime.interpreter'
  '';


  preConfigure = ''
      patchShebangs configure

      # dummy ldconfig
      mkdir dummy-ldconfig
      echo "#!${stdenv.shell}" > dummy-ldconfig/ldconfig
      chmod +x dummy-ldconfig/ldconfig
      export PATH="$PWD/dummy-ldconfig:$PATH"
      export PYTHON_LIB_PATH="$NIX_BUILD_TOP/site-packages"
      mkdir -p "$PYTHON_LIB_PATH"

      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}${stdenv.cc.cc.lib}/lib/libstdc++.so.6"
  '';

  postFixup = let
    rpath = stdenv.lib.makeLibraryPath
      (
        [ stdenv.cc.cc.lib zlib ]
      );
  in
  ''
    find $out -name '*.so' -exec patchelf --set-rpath "$rrPath" {} \;
  '';

}
