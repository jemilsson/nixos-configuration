{ python37, python37Packages  }:

#with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "spotipy";
  version = "2.25.2";

  disabled = !python37.pkgs.isPy3k;

  src = python37.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "";  # Will be filled by nix
  };

  buildInputs = [ python37Packages.requests python37Packages.requests ];
  doCheck = false;
}
