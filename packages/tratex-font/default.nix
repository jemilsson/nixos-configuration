{ stdenv ? (import <nixpkgs> {}).stdenv
, fetchurl ? (import <nixpkgs> {}).fetchurl
, unzip ? (import <nixpkgs> {}).unzip
, lib ? (import <nixpkgs> {}).lib
}:

stdenv.mkDerivation rec {
  pname = "tratex-font";
  version = "1.0";

  src = fetchurl {
    url = "https://www.transportstyrelsen.se/globalassets/global/vag/vagmarken/teckensnitt/tratex_win.zip";
    sha256 = "sha256-2E41Ju6em4/mRPLxbLjf0I4gyZ1cfiFNzYNV2oBXceo="; # Replace with actual hash if you know it
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    find . -name "*.ttf" -o -name "*.TTF" | while read -r font; do
      cp "$font" $out/share/fonts/truetype/
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Tratex font family for Swedish road signs";
    homepage = "https://www.transportstyrelsen.se/";
    license = licenses.unfree; # Adjust according to actual license
    platforms = platforms.all;
    maintainers = [ ]; # Add yourself as a maintainer if appropriate
  };
}