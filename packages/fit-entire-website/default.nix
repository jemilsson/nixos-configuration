{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "fit-entire-website";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "fit-project";
    repo = "fit";
    rev = "25f5ad9ae6a204faca5e4adae7e500c2b91ff3b2";
    hash = "sha256-YM1NV+n4J0mFv/IEFXhTZfTMiJw1iT1X8Pny7t+my4M=";
  };

  format = "pyproject";

  nativeBuildInputs = with python3.pkgs; [
    poetry-core
  ];

  propagatedBuildInputs = with python3.pkgs; [
    # Core dependencies
    pyqt6
    pyqt6-webengine
    beautifulsoup4
    lxml
    pillow
    sqlalchemy
    psutil
    packaging
    numpy
    
    # Available dependencies
    ntplib
    pypdf2
    scapy
    # instaloader - not in nixpkgs
    brotli  # instead of brotlipy
    yt-dlp
    mitmproxy
    moviepy
    
    # Dependencies that need to be packaged separately:
    # python-whois
    # xhtml2pdf
    # rfc3161ng
    # youtube-comment-downloader
    # pyzmail36
    # instaloader
  ];

  # Remove version constraints from pyproject.toml
  preBuild = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'numpy = "^1.24.1"' 'numpy = "*"' \
      --replace-fail 'SQLAlchemy = "^2.0.0"' 'SQLAlchemy = "*"' \
      --replace-fail 'pillow = "^9.4.0"' 'pillow = "*"' \
      --replace-fail 'PyPDF2 = "^3.0.1"' 'PyPDF2 = "*"' \
      --replace-fail 'scapy = "^2.5.0"' 'scapy = "*"' \
      --replace-fail 'brotlipy = "^0.7.0"' 'brotlipy = "*"' \
      --replace-fail 'bs4 = "^0.0.1"' 'bs4 = "*"' \
      --replace-fail 'yt-dlp = "^2025.2.19"' 'yt-dlp = "*"' \
      --replace-fail 'mitmproxy = "^10.1.5"' 'mitmproxy = "*"' \
      --replace-fail 'lxml = "^4.9.3"' 'lxml = "*"' \
      --replace-fail 'moviepy = "^1.0.3"' 'moviepy = "*"' \
      --replace-fail 'psutil = "^6.0.0"' 'psutil = "*"' \
      --replace-fail 'pyqt6 = "6.7.1"' 'pyqt6 = "*"' \
      --replace-fail 'pyqt6-sip = "13.8.0"' 'pyqt6-sip = "*"' \
      --replace-fail 'pyqt6-qt6 = "6.7.2"' 'pyqt6-qt6 = "*"' \
      --replace-fail 'pyqt6-webengine = "6.7.0"' 'pyqt6-webengine = "*"' \
      --replace-fail 'pyqt6-webengine-qt6 = "6.7.1"' 'pyqt6-webengine-qt6 = "*"' \
      --replace-fail 'pyqt6-webenginesubwheel-qt6 = "6.7.1"' 'pyqt6-webenginesubwheel-qt6 = "*"' \
      --replace-fail 'packaging = "^24.2"' 'packaging = "*"' \
      --replace-fail 'pyinstaller = "^6.12.0"' 'pyinstaller = "*"'
      
    # Remove missing dependencies  
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
    sed -i 's/brotlipy/brotli/' pyproject.toml
    sed -i 's/bs4/beautifulsoup4/' pyproject.toml
  '';

  # Skip import checks and tests for now
  doCheck = false;
  pythonImportsCheck = [ ];

  meta = with lib; {
    description = "FIT Entire Website Scraper - Complete website acquisition tool";
    homepage = "https://github.com/fit-project/fit";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ];
  };
}