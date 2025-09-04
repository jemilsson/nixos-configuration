{ pkgs, lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "whitesur-wallpapers";
  version = "2.0";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "WhiteSur-wallpapers";
    rev = "v${version}";
    sha256 = "zO6wdwJH3VhR+Y1clPeV5BwxXS0FA9vZvPa1IKpnKvs=";
  };

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/share/backgrounds/whitesur
    
    # Copy all resolution directories
    for dir in 1080p 2k 4k Wallpaper-nord; do
      if [ -d "$dir" ]; then
        cp -r "$dir" $out/share/backgrounds/whitesur/
      fi
    done
    
    # Copy installation and preview files
    cp install-*.sh $out/share/backgrounds/whitesur/ 2>/dev/null || true
    cp preview-*.png $out/share/backgrounds/whitesur/ 2>/dev/null || true
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "WhiteSur wallpapers collection - macOS Big Sur style wallpapers for Linux";
    homepage = "https://github.com/vinceliuice/WhiteSur-wallpapers";
    license = licenses.gpl3Plus;
    maintainers = [ ];
    platforms = platforms.all;
  };
}