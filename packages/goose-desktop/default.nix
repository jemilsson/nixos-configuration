{ pkgs, lib, stdenv, fetchurl, autoPatchelfHook, dpkg, makeWrapper, nodejs }:

stdenv.mkDerivation rec {
  pname = "goose-desktop";
  version = "1.18.0";

  src = fetchurl {
    url = "https://github.com/block/goose/releases/download/v${version}/goose_${version}_amd64.deb";
    sha256 = "1lidzklqqi8788g75s5921yqfmmaqkbjv8c57cyg4gidf5va3asl";
  };

  nativeBuildInputs = with pkgs; [
    binutils
    zstd
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = with pkgs; [
    xorg.libxcb
    xorg.libX11
    xorg.libXi
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXfixes
    libGL
    gtk3
    glib
    cairo
    pango
    gdk-pixbuf
    atk
    stdenv.cc.cc.lib
    nss
    nspr
    expat
    fontconfig
    freetype
    dbus
    xorg.libXext
    xorg.libXrender
    xorg.libXtst
    xorg.libXdamage
    xorg.libXcomposite
    xorg.libXScrnSaver
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cups
    mesa
    libglvnd
    libxkbcommon
    wayland
  ];

  unpackPhase = ''
    runHook preUnpack
    
    # Extract DEB with ar and handle tar manually to avoid setuid issues
    ar x $src
    tar --no-same-permissions -xf data.tar.zst
    
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out
    cp -r usr/* $out/
    
    # Make sure the main executable is in the expected location
    chmod +x $out/lib/goose/Goose
    
    # Patch all shell scripts to use correct interpreter paths
    patchShebangs $out/lib/goose/resources/bin/
    
    # Replace the node and npx wrappers with simple scripts that use Nix's Node.js
    cat > $out/lib/goose/resources/bin/node << EOF
#!${pkgs.bash}/bin/bash
exec ${nodejs}/bin/node "\$@"
EOF
    chmod +x $out/lib/goose/resources/bin/node
    
    cat > $out/lib/goose/resources/bin/npx << EOF
#!${pkgs.bash}/bin/bash
exec ${nodejs}/bin/npx "\$@"
EOF
    chmod +x $out/lib/goose/resources/bin/npx
    
    # Create a wrapper script in bin with proper environment
    mkdir -p $out/bin
    cat > $out/bin/goose-desktop << EOF
#!/bin/sh

# Set up graphics libraries path
export LD_LIBRARY_PATH="${pkgs.mesa}/lib:${pkgs.libglvnd}/lib:\$LD_LIBRARY_PATH"

# Set EGL/GL vendor directories  
export __EGL_VENDOR_LIBRARY_DIRS="${pkgs.mesa}/share/glvnd/egl_vendor.d"
export __GLX_VENDOR_LIBRARY_DIRS="${pkgs.mesa}/lib/dri"

# Enable software rendering as fallback
export MESA_LOADER_DRIVER_OVERRIDE=swrast

# Always use software rendering for now to avoid GPU issues
exec "$out/lib/goose/Goose" --disable-gpu --no-sandbox "\$@"
EOF
    chmod +x $out/bin/goose-desktop
    
    # Fix the desktop file to point to our installation
    sed -i "s|/usr/lib/goose/Goose|$out/lib/goose/Goose|g" $out/share/applications/goose.desktop
    sed -i "s|/usr/share/pixmaps/goose.png|$out/share/pixmaps/goose.png|g" $out/share/applications/goose.desktop
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Goose AI agent - desktop version for automating development tasks";
    longDescription = ''
      Goose is an open source, extensible AI agent that goes beyond code suggestions.
      It can build entire projects from scratch, write and execute code, debug failures,
      orchestrate workflows, and interact with external APIs autonomously.
    '';
    homepage = "https://github.com/block/goose";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "goose-desktop";
  };
}