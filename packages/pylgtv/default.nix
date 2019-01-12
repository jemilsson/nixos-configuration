{ pkgs, python37, python37Packages  }:

#with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "pylgtv";
  version = "0.1.9";

  disabled = !python37.pkgs.isPy3k;

  src = python37.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "0k2cj33mnfp914kvj698ldxw2807f6z1l1jr1h99h1xfdwrkz80f";
  };

  buildInputs = [ pkgs.unstable.python37Packages.aiohttp pkgs.unstable.python37Packages.websockets ];
  doCheck = false;
}
