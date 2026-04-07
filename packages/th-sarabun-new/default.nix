{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "th-sarabun-new";
  version = "2024-01-01";

  src = fetchFromGitHub {
    owner = "epsilonxe";
    repo = "SIPAFonts";
    rev = "master";
    sha256 = "1zgd98rsxz2dkhf815ivvwndr39a3x1pa84wczakfnprdssbyjxq";
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/share/fonts/truetype \
      "THSarabunNew.ttf" \
      "THSarabunNew Bold.ttf" \
      "THSarabunNew Italic.ttf" \
      "THSarabunNew BoldItalic.ttf"
    runHook postInstall
  '';

  meta = with lib; {
    description = "TH Sarabun New - Official Thai government font by SIPA";
    homepage = "https://github.com/epsilonxe/SIPAFonts";
    license = licenses.gpl2Plus;
    platforms = platforms.all;
  };
}
