{ python38, python38Packages, pkgs  }:

#with import <nixpkgs> {};

python38.pkgs.buildPythonPackage rec {
  pname = "pydeconz";
  version = "47";

  src = python38.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "1d8drgy712sxxvisdaz53jgyiiidbhvnbrsvgci6jh9b6s6189wb";
  };

  buildInputs = [ pkgs.unstable.python38Packages.aiohttp ];
  doCheck = false;
}
