{ python36, python36Packages  }:

#with import <nixpkgs> {};

python36.pkgs.buildPythonPackage rec {
  pname = "faucet";
  version = "1.8.5";

  disabled = !python36.pkgs.isPy3k;

  src = python36.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "1l8ya0cln936x0mx2j5ngl1xwpc0r89hs3wcvb8x8paw3d4dl1ac";
  };

  buildInputs = [ python36Packages.requests python36Packages.requests ];
  doCheck = false;
}
