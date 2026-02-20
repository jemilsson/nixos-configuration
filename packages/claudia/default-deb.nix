{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, dpkg
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
, libsoup_3
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
    url = "https://github.com/getAsterisk/claudia/releases/download/v${version}/Claudia_v${version}_linux_x86_64.deb";
    sha256 = "sha256-vrknH7FdZcOhvDZbUpP0gkyFzYGgr9BYophclAJ1ejs=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    dpkg
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
    libsoup_3
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

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall
    
    # Create output directories
    mkdir -p $out
    
    # Copy all files from the deb package
    cp -r usr/* $out/
    
    # Wrap the binary with environment variables for EGL/GL issues
    wrapProgram $out/bin/claudia \
      --set LD_LIBRARY_PATH "${lib.makeLibraryPath buildInputs}" \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
      --set WEBKIT_FORCE_SANDBOX 0 \
      --set LIBGL_ALWAYS_SOFTWARE 1 \
      --set __GLX_VENDOR_LIBRARY_NAME mesa \
      --set MESA_LOADER_DRIVER_OVERRIDE swrast \
      --set GALLIUM_DRIVER softpipe \
      --add-flags "--no-sandbox" \
      --add-flags "--disable-gpu" \
      --add-flags "--disable-gpu-compositing"
    
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