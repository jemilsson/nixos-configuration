{ python38, python38Packages, pkgs  }:

#with import <nixpkgs> {};

python38.pkgs.buildPythonPackage rec {
  pname = "pydeconz";
  version = "120";

  src = python38.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "";  # Will be filled by nix
  };

  buildInputs = [ pkgs.unstable.python38Packages.aiohttp pkgs.unstable.python38Packages.netdisco ];
  doCheck = false;
}
