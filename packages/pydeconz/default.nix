{ python36, python36Packages  }:

#with import <nixpkgs> {};

python36.pkgs.buildPythonPackage rec {
  pname = "pydeconz";
  version = "43";

  disabled = !python36.pkgs.isPy3k;

  src = python36.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "5bcccceb51a9e8a09d1c5d76e700b6660283876546e164b9fa579dd776ca19de";
  };

  buildInputs = [ python36Packages.aiohttp ];
  doCheck = false;
}
