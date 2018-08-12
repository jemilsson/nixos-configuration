{ buildPythonPackage, fetchPypi, python36Packages  }:

#with import <nixpkgs> {};

buildPythonPackage rec {
  pname = "pydeconz";
  version = "43";

  src = fetchPypi {
    inherit pname version;
    sha256 = "03qwba8qn3939jwm79jmc8s8lpirdbwdl6chah79544l0lh0vvbf";
  };

  buildInputs = [ python36Packages.aiohttp ];
  doCheck = false;
}
