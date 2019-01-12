{ python37, python37Packages  }:

#with import <nixpkgs> {};

python37.pkgs.buildPythonPackage rec {
  pname = "pylgtv";
  version = "0.1.7";

  disabled = !python37.pkgs.isPy3k;

  src = python37.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "1k457x07xkbzibny1rpfq19wnk56frs0jbr3r2q7saxi94hqi05y";
  };

  buildInputs = [ python37Packages.aiohttp python37Packages.asyncio python37Packages.websockets ];
  doCheck = false;
}
