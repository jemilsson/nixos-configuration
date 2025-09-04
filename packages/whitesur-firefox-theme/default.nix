{ pkgs, lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "whitesur-firefox-theme";
  version = "2025-07-28";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "WhiteSur-firefox-theme";
    rev = version;
    sha256 = "T1gWHKc6W9Z+PjuLo8wq145/ZGXM5L2RekXeEyoo0Ls=";
  };

  buildInputs = with pkgs; [ bash ];

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/share/whitesur-firefox-theme
    
    # Copy all theme files
    cp -r * $out/share/whitesur-firefox-theme/
    
    # Make the install script executable
    chmod +x $out/share/whitesur-firefox-theme/install.sh
    
    # Create a wrapper script for easy installation
    mkdir -p $out/bin
    cat > $out/bin/whitesur-firefox-install << 'EOF'
#!/usr/bin/env bash
cd ${placeholder "out"}/share/whitesur-firefox-theme
exec ./install.sh "$@"
EOF
    
    chmod +x $out/bin/whitesur-firefox-install
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "WhiteSur Firefox theme - macOS Big Sur style theme for Firefox";
    longDescription = ''
      A macOS Big Sur style theme for Firefox. Supports multiple variants:
      - Different color schemes (monterey, alt, darker)
      - Customizable accent colors
      - Rounded corners and modern styling
    '';
    homepage = "https://github.com/vinceliuice/WhiteSur-firefox-theme";
    license = licenses.gpl3Plus;
    maintainers = [ ];
    platforms = platforms.all;
    mainProgram = "whitesur-firefox-install";
  };
}