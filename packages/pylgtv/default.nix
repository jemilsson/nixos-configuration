{ python36, python36Packages  }:

#with import <nixpkgs> {};

python36.pkgs.buildPythonPackage rec {
  pname = "pylgtv";
  version = "0.1.7";

  disabled = !python36.pkgs.isPy3k;

  src = python36.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "1k457x07xkbzibny1rpfq19wnk56frs0jbr3r2q7saxi94hqi05y";
  };

  buildInputs = [ ];
  doCheck = false;
}
