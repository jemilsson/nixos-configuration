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

  postInstall = ''
    mkdir -p $out/bin
    cat > $out/bin/fit-web <<EOF
    #!${python3.interpreter}
    import sys
    from fit_web.web import Web
    from PySide6.QtWidgets import QApplication
    from PySide6 import QtGui
    
    if __name__ == "__main__":
        app = QApplication(sys.argv)
        window = Web()
        if window.has_valid_case:
            window.show()
            sys.exit(app.exec())
        else:
            print("User cancelled the case form. Nothing to display.")
            sys.exit(0)
    EOF
    chmod +x $out/bin/fit-web
  '';

  # Skip import checks for now
  doCheck = false;
  pythonImportsCheck = [ ];

  meta = with lib; {
    description = "FIT WEB Scraper Module - Web page acquisition tool (GUI)";
    homepage = "https://github.com/fit-project/fit-web";
    license = licenses.lgpl3Plus;
    maintainers = with maintainers; [ ];
    mainProgram = "fit-web";
  };
}