{ python36, python36Packages  }:

#with import <nixpkgs> {};

python36.pkgs.buildPythonPackage rec {
  pname = "pydeconz";
  version = "43";

  disabled = !python36.pkgs.isPy3k;

  src = python36.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "03qwba8qn3939jwm79jmc8s8lpirdbwdl6chah79544l0lh0vvbf";
  };

  buildInputs = [ python36Packages.aiohttp ];
  doCheck = false;
}
