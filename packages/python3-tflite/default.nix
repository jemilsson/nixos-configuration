{ python37, python37Packages  }:

#with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "tflite";
  version = "2.2.0";

  disabled = !python37.pkgs.isPy3k;

  src = python37.pkgs.fetchPypi {
    format = "wheel";
    inherit pname version;
    sha256 = "1l8ya0cln926x0mx2j5ngl1xwpc0r89hs3wcvb8x8paw3d4dl1ab";
  };

  buildInputs = [ python37Packages.requests python37Packages.requests ];
  doCheck = false;
}
