{ python36, python36Packages  }:

#with import <nixpkgs> {};

python36.pkgs.buildPythonPackage rec {
  pname = "faucet";
  version = "1.8.5";

  disabled = !python36.pkgs.isPy3k;

  src = python36.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "1ds9f5z3pp5g9rc1qj43nbwxpk8g6571jymb81k6z85jad1n365y";
  };

  buildInputs = [ python36Packages.requests python36Packages.requests ];
  doCheck = false;
}
