{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "fit-web";
  version = "0.2.5";

  src = fetchFromGitHub {
    owner = "fit-project";
    repo = "fit-web";
    rev = "35cd432eb07ad3f9a487e745274132217eab5ef6";
    hash = "sha256-XAreIPoE8vzxadk6c6fFx2aN4LMo/G5/og9KOPqDOus=";
  };

  format = "pyproject";

  nativeBuildInputs = with python3.pkgs; [
    poetry-core
  ];

  propagatedBuildInputs = with python3.pkgs; [
    pyside6
  ];

  # Skip git dependency and fix version constraints
  preBuild = ''
    sed -i '/fit-scraper/d' pyproject.toml
    sed -i 's/PySide6 = "6.9.0"/PySide6 = "*"/' pyproject.toml
  '';

  # Skip import checks for now
  doCheck = false;
  pythonImportsCheck = [ ];

  meta = with lib; {
    description = "FIT WEB Scraper Module - Web page acquisition tool";
    homepage = "https://github.com/fit-project/fit-web";
    license = licenses.lgpl3Plus;
    maintainers = with maintainers; [ ];
  };
}