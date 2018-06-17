{ python36, python36Packages  }:

#with import <nixpkgs> {};

python36.pkgs.buildPythonPackage rec {
  pname = "pydeconz";
  version = "38";

  disabled = !python36.pkgs.isPy3k;

  src = python36.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "1gq13z54k9w4r6nygm2hsfl4yj0gl27hndnlxj0h91g90m2ggs14";
  };

  propagatedBuildInputs = [ python36Packages.aiohttp ];
  doCheck = false;
}
