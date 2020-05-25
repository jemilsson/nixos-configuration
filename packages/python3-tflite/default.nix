{ python37, python37Packages  }:

#with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "tflite";
  version = "2.2.0";

  disabled = !python37.pkgs.isPy3k;

  src = python37.pkgs.fetchPypi {
    format = "wheel";
    inherit pname version;
    sha256 = "1mxy08lvmpqqrbnzh8hd7614hk7fvmplszmviyhrg3hb77j8gs0v";
  };

  buildInputs = [ python37Packages.requests python37Packages.requests ];
  doCheck = false;
}
