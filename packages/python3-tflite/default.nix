{ stdenv, python37, fetchurl, python37Packages  }:

#with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "tflite";
  version = "2.2.0";
  format = "wheel";

  disabled = !python37.pkgs.isPy3k;

  src = fetchurl {
    url = "https://dl.google.com/coral/python/tflite_runtime-2.1.0.post1-cp37-cp37m-linux_x86_64.whl";
    sha256 = "17g13d42dy4xxchryc67spqj7i14ilzclvar6g8b7ypz50adkb9d";
  };

  buildInputs = [ python37Packages.numpy python37Packages.pip ];
  doCheck = false;



  preConfigure = ''
      patchShebangs configure
      # dummy ldconfig
      mkdir dummy-ldconfig
      echo "#!${stdenv.shell}" > dummy-ldconfig/ldconfig

    '';

}
