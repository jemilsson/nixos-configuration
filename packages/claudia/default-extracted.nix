{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, appimageTools
, libGL
, mesa
, wayland
, libxkbcommon
, libdrm
, xorg
, webkitgtk_4_1
, gtk3
, glib
, cairo
, pango
, atk
, gdk-pixbuf
, libsoup_2_4
, openssl
, nspr
, nss
, libnotify
, libayatana-appindicator
}:

stdenv.mkDerivation rec {
  pname = "claudia";
  version = "0.1.0";
  
  src = fetchurl {
    url = "https://github.com/getAsterisk/claudia/releases/download/v${version}/Claudia_v${version}_linux_x86_64.AppImage";
    sha256 = "sha256-qjsbv+qvE3g7/jBNRIh6ImLEBpz8Gllc+e16WPvVPLA=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    libGL
    mesa
    libdrm
    wayland
    libxkbcommon
    webkitgtk_4_1
    gtk3
    glib
    cairo
    pango
    atk
    gdk-pixbuf
    libsoup_2_4
    openssl
    nspr
    nss
    libnotify
    libayatana-appindicator
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxshmfence
    stdenv.cc.cc.lib
  ];

  sourceRoot = ".";

  unpackPhase = ''
    # Extract the AppImage using appimageTools
    cp $src claudia.AppImage
    ${appimageTools.appimage-exec}/bin/appimage-extract-and-run claudia.AppImage --appimage-extract || true
    
    # Check if extraction worked
    if [ -d squashfs-root ]; then
      mv squashfs-root/* .
    else
      # Fallback: try to extract as a type 2 AppImage
      ${lib.getExe appimageTools.appimage-exec} claudia.AppImage --appimage-extract || true
      mv squashfs-root/* . || true
    fi
  '';

  installPhase = ''
    runHook preInstall
    
    # Create output directories
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/128x128/apps
    
    # Install the main binary
    cp usr/bin/claudia $out/bin/claudia-bin
    
    # Create wrapper with environment variables
    makeWrapper $out/bin/claudia-bin $out/bin/claudia \
      --set LD_LIBRARY_PATH "${lib.makeLibraryPath buildInputs}" \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
      --set LIBGL_ALWAYS_SOFTWARE 1 \
      --set __GLX_VENDOR_LIBRARY_NAME mesa \
      --set MESA_LOADER_DRIVER_OVERRIDE swrast \
      --set GALLIUM_DRIVER softpipe
    
    # Install desktop file and icon
    cp Claudia.desktop $out/share/applications/
    substituteInPlace $out/share/applications/Claudia.desktop \
      --replace-warn 'Exec=claudia' 'Exec=claudia'
    
    cp claudia.png $out/share/icons/hicolor/128x128/apps/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "GUI for Claude Code with advanced agent and project management";
    homepage = "https://github.com/getAsterisk/claudia";
    license = licenses.agpl3Plus;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "claudia";
  };
}