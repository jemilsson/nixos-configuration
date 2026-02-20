{ lib
, python3
, fetchFromGitHub
, qt6
}:

python3.pkgs.buildPythonApplication rec {
  pname = "fit-main";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "fit-project";
    repo = "fit";
    rev = "25f5ad9ae6a204faca5e4adae7e500c2b91ff3b2";
    hash = "sha256-YM1NV+n4J0mFv/IEFXhTZfTMiJw1iT1X8Pny7t+my4M=";
  };

  format = "pyproject";

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
  ] ++ (with python3.pkgs; [
    poetry-core
  ]);

  buildInputs = [
    qt6.qtbase
    qt6.qtwebengine
  ];

  propagatedBuildInputs = with python3.pkgs; [
    # Core Qt dependencies
    pyqt6
    pyqt6-webengine
    
    # Core Python dependencies
    beautifulsoup4
    lxml
    pillow
    sqlalchemy
    psutil
    packaging
    numpy
    ntplib
    pypdf2
    scapy
    brotli
    yt-dlp
    mitmproxy
    moviepy
  ];

  # Fix version constraints and missing dependencies
  preBuild = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'python = ">=3.11,<3.14"' 'python = ">=3.11"' \
      --replace-fail 'numpy = "^1.24.1"' 'numpy = "*"' \
      --replace-fail 'SQLAlchemy = "^2.0.0"' 'SQLAlchemy = "*"' \
      --replace-fail 'pillow = "^9.4.0"' 'pillow = "*"' \
      --replace-fail 'PyPDF2 = "^3.0.1"' 'PyPDF2 = "*"' \
      --replace-fail 'scapy = "^2.5.0"' 'scapy = "*"' \
      --replace-fail 'brotlipy = "^0.7.0"' 'brotli = "*"' \
      --replace-fail 'bs4 = "^0.0.1"' 'beautifulsoup4 = "*"' \
      --replace-fail 'yt-dlp = "^2025.2.19"' 'yt-dlp = "*"' \
      --replace-fail 'mitmproxy = "^10.1.5"' 'mitmproxy = "*"' \
      --replace-fail 'lxml = "^4.9.3"' 'lxml = "*"' \
      --replace-fail 'moviepy = "^1.0.3"' 'moviepy = "*"' \
      --replace-fail 'psutil = "^6.0.0"' 'psutil = "*"' \
      --replace-fail 'pyqt6 = "6.7.1"' 'pyqt6 = "*"' \
      --replace-fail 'pyqt6-sip = "13.8.0"' 'pyqt6-sip = "*"' \
      --replace-fail 'pyqt6-webengine = "6.7.0"' 'pyqt6-webengine = "*"' \
      --replace-fail 'packaging = "^24.2"' 'packaging = "*"'
      
    # Remove unavailable dependencies
    sed -i '/python-whois/d' pyproject.toml
    sed -i '/xhtml2pdf/d' pyproject.toml
    sed -i '/nslookup/d' pyproject.toml
    sed -i '/instaloader/d' pyproject.toml
    sed -i '/pyzmail36/d' pyproject.toml
    sed -i '/rfc3161ng/d' pyproject.toml
    sed -i '/youtube-comment-downloader/d' pyproject.toml
    sed -i '/pyinstaller/d' pyproject.toml
    sed -i '/pyqt6-qt6/d' pyproject.toml
    sed -i '/pyqt6-webengine-qt6/d' pyproject.toml
    sed -i '/pyqt6-webenginesubwheel-qt6/d' pyproject.toml
  '';

  postInstall = ''
    mkdir -p $out/bin
    
    # Main FIT application launcher
    cat > $out/bin/fit <<EOF
    #!${python3.interpreter}
    import sys
    import os
    os.chdir("$out/lib/python${python3.pythonVersion}/site-packages")
    sys.path.insert(0, "$out/lib/python${python3.pythonVersion}/site-packages")
    
    from PyQt6 import QtWidgets, QtGui
    from view.wizard import Wizard
    
    if __name__ == "__main__":
        app = QtWidgets.QApplication(sys.argv)
        wizard = Wizard()
        wizard.show()
        sys.exit(app.exec())
    EOF
    chmod +x $out/bin/fit
  '';

  # Skip tests
  doCheck = false;
  pythonImportsCheck = [ ];

  meta = with lib; {
    description = "FIT (Freezing Internet Tool) - Digital forensics tool for web acquisition";
    homepage = "https://github.com/fit-project/fit";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
    mainProgram = "fit";
  };
}