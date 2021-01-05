{ python38, python38Packages, pkgs  }:

#with import <nixpkgs> {};

python38.pkgs.buildPythonPackage rec {
  pname = "pydeconz";
  version = "77";

  src = python38.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "1v06c31w1fy90xh0y3al1y0s6iilvg729j9jqbq320ka6a1742gh";
  };

  buildInputs = [ pkgs.unstable.python38Packages.aiohttp pkgs.unstable.python38Packages.netdisco ];
  doCheck = false;
}
