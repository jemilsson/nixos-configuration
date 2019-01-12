{ python37, python37Packages  }:

#with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "spotipy";
  version = "2.4.4";

  disabled = !python37.pkgs.isPy3k;

  src = python37.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "1l8ya0cln936x0mx2j5ngl1xwpc0r89hs3wcvb8x8paw3d4dl1ab";
  };

  buildInputs = [ python37Packages.requests python37Packages.requests ];
  doCheck = false;
}
