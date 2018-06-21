{ python36, python36Packages  }:

#with import <nixpkgs> {};

python36.pkgs.buildPythonPackage rec {
  pname = "pylgtv";
  version = "0.1.7";

  disabled = !python36.pkgs.isPy3k;

  src = python36.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "C61084F3CBA2179CD9D13472FF67AF302576A0E7438887D2656353E3BB3FE577";
  };

  buildInputs = [ ];
  doCheck = false;
}
