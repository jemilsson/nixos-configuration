{ python37, python37Packages  }:

#with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "pydeconz";
  version = "43";

  src = python37.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "03qwba8qn3939jwm79jmc8s8lpirdbwdl6chah79544l0lh0vvbf";
  };

  buildInputs = [ python37Packages.aiohttp ];
  doCheck = false;
}
