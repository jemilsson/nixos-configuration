{ buildPythonPackage, isPy3k, fetchPypi, aiohttp  }:

#with import <nixpkgs> {};

buildPythonPackage rec {
  pname = "pydeconz";
  version = "38";

  disabled = !isPy3k;

  src = fetchPypi {
    inherit pname version;
    sha256 = "1gq13z54k9w4r6nygm2hsfl4yj0gl27hndnlxj0h91g90m2ggs14";
  };

  propagatedBuildInputs = [ aiohttp ];
  doCheck = false;
}
