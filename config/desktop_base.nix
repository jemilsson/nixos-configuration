{ config, lib, pkgs, ... }:
let
  #scd-pkcs11 = pkgs.callPackage ../packages/scd-pkcs11/default.nix {};
  #python3-edgetpu = pkgs.callPackage ../packages/python3-edgetpu/default.nix {};
  #python3-tflite = pkgs.callPackage ../packages/python3-tflite/default.nix {};

  #continue = pkgs.callPackage ../packages/continue/default.nix {};
  #roo-code = pkgs.callPackage ../packages/roo-code/default.nix {};
  vscode-claude-code = pkgs.callPackage ../packages/vscode-claude-code/default.nix {};
  vscode-3d-preview = pkgs.callPackage ../packages/vscode-3d-preview/default.nix {};
  quarto = pkgs.callPackage ../packages/quarto/default.nix {};
  djlint = pkgs.callPackage ../packages/djlint/default.nix {};
  cloudformation-yaml-validator = pkgs.callPackage ../packages/cloudformation-yaml-validator/default.nix {};
  boto3-ide = pkgs.callPackage ../packages/boto3-ide/default.nix {};
  tratex-font = pkgs.callPackage ../packages/tratex-font/default.nix {};
  tmuxai = pkgs.callPackage ../packages/tmuxai/default.nix {};
  claude-aws = pkgs.callPackage ../packages/claude-aws/default.nix {};
  claude-code-router = pkgs.callPackage ../packages/claude-code-router/default.nix {};
  claude-router = pkgs.callPackage ../packages/claude-router/default.nix { 
    claude-code-router = claude-code-router;
  };
  ccr-configure-venice = pkgs.callPackage ../packages/ccr-configure-venice/default.nix {};

  vscode-extensions = (with pkgs.unstable.vscode-extensions; [
    vscode-claude-code

    #Python support
    ms-python.python

    antyos.openscad
    vscode-3d-preview

    #General tools
    # continue.continue commenting it because it's too old in nixpkgs
    rooveterinaryinc.roo-cline
    continue.continue
    eamodio.gitlens

    #Data formats
    yzhang.markdown-all-in-one

    #Themes
    github.github-vscode-theme

    quarto

    #Glecom vscode recommendations
    editorconfig.editorconfig
    tamasfe.even-better-toml
    charliermarsh.ruff
    redhat.vscode-yaml
    jnoortheen.nix-ide
    github.vscode-github-actions
    timonwong.shellcheck
    foxundermoon.shell-format
    davidanson.vscode-markdownlint
    djlint
    astro-build.astro-vscode
    cloudformation-yaml-validator
    bradlc.vscode-tailwindcss
    boto3-ide
    ms-python.vscode-pylance
    esbenp.prettier-vscode
    mkhl.direnv
  ]);
  my-vscode-with-extensions = pkgs.unstable.vscode-with-extensions.override {
    vscodeExtensions = vscode-extensions;
  };

in
{
  imports = [
    ./base.nix
    ./wallpapers.nix
    ./bare_metal.nix
    ./bedrock-access-gateway.nix
    ./fonts_ibm_plex.nix
    #./systemd_user/gpg-agent.nix
    #./x11.nix

  ];

  powerManagement = {
    enable = false;
    # cpuFreqGovernor = "ondemand";
  };

  xdg =
    {
      portal = {
        enable = true;
        wlr.enable = true;
      };
    };

  boot = {
    extraModulePackages = with config.boot.kernelPackages;
      [  ];
    kernelParams = [ "rw" ];
  };


  gtk.iconCache.enable = true;

  security.rtkit.enable = true;

  hardware = {
    enableAllFirmware = true;
    pulseaudio = {
      enable = false;
      support32Bit = true;
      #package = pkgs.pulseaudio-hsphfpd;

      extraModules = [
        #pkgs.unstable.pulseaudio-modules-bt
      ];

      daemon = {
        config = {
          "flat-volumes" = "no";
          "resample-method" = "speex-float-5";
          "realtime-scheduling" = "yes";
          "high-priority" = "yes";
          "realtime-priority" = 8;
          "default-fragments" = 5;
          "default-fragment-size-msec" = 2;
        };
      };
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      #package = pkgs.bluezFull;
      settings = {
        General = {
          #Experimental = true;
        };
      };
    };

    rtl-sdr.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-compute-runtime
        intel-media-driver
        libvdpau-va-gl
        vaapiVdpau
        vaapiIntel
        onevpl-intel-gpu
      ];
      extraPackages32 = with pkgs; [
        intel-compute-runtime
        intel-media-driver
        libvdpau-va-gl
        vaapiVdpau
        vaapiIntel
        onevpl-intel-gpu
      ];
    };

    steam-hardware = {
      enable = true;
    };

    ledger = {
      enable = true;
    };

    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };

  };

  networking.networkmanager.enable = true;

  #environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    ghostscript

    #Browsers
    firefox
    chromium
    google-chrome
    #unstable-small.tor-browser-bundle-bin

    #Media
    spotify
    vlc
    mplayer
    smplayer
    pavucontrol
    pasystray
    audacity
    gimp
    exiftool
    playerctl
    deluge

    #3D design
    openscad
    unstable.bambu-studio
    #cura
    meshlab


    ffmpeg-full
    #v4l-utils
    imagemagick

    #Programming
    #atom
    (python3.withPackages (ps: with ps; [
      yapf
      flake8
      autopep8
      uvicorn
      numpy
      pillow
      pylint
      scipy
      matplotlib
      pymeeus
      jupyter
      plotly
      markitdown
      copier
    ]))
    my-vscode-with-extensions
    #insomnia
    bruno
    vscodium
    emacs
    #aws-sam-cli

    ## Nix

    nixpkgs-fmt
    #rnix-lsp

    ## Pony
    #ponyc
    #pony-corral


    #Interface
    alacritty
    foot
    albert
    synapse
    feh
    (freerdp.override { pcsclite = pcsclite; libpulseaudio = libpulseaudio; })
    rdesktop
    appimage-run

    #Ricing
    paper-icon-theme
    hicolor-icon-theme
    adwaita-icon-theme
    pantheon.elementary-icon-theme
    #gtk3
    #gtk-engine-murrine
    lxappearance

    #Graphical System tools
    gedit
    nautilus
    sushi
    file-roller
    gparted
    file
    keepass
    libreoffice
    mupdf
    quarto
    #adobe-reader

    #Communication
    pidgin
    signal-desktop
    tdesktop
    teams-for-linux
    discord
    #skype

    #(steam.override { extraPkgs = pkgs: with pkgs.pkgsi686Linux; [ libva ]; })

    #Games
    #unstable-small.steam
    #(unstable.steam.override {  extraPkgs = pkgs: with pkgs.pkgsi686Linux; [ alsaLib alsaPlugins libpulseaudio ]; })
    #(unstable.winetricks.override { wine = unstable.wine.override { wineBuild = "wineWow"; };} )
    #(unstable.wine.override { wineBuild = "wineWow"; })
    #polymc
    #minecraft
    virtualgl

    #Security
    libu2f-host
    yubikey-personalization
    yubico-piv-tool
    pcsctools
    opensc
    yubikey-manager
    openssl
    libp11
    #scd-pkcs11
    #kdeApplications.kleopatra

    pass
    qtpass
    pwgen

    unetbootin

    teensy-loader-cli
    #unstable.qmk_firmware

    #Accessories
    piper
    android-file-transfer
    go-mtpfs

    sweethome3d.application

    #Terminal system tools
    lm_sensors
    picocom

    gnome.gvfs
    gtk3
    gsettings-desktop-schemas

    #virtualisation
    #virtmanager


    awscli

    #samba4Full
    cifs-utils

    ledger-live-desktop

    #hsphfpd

    vulkan-loader
    vulkan-validation-layers
    vulkan-tools

    swaybg
    grim
    wl-clipboard
    slurp

    obs-studio

    wireshark

    qFlipper

    prismlauncher
    libsecret

    nixd
    ruff

    handlr

    masterpdfeditor
    poppler-utils

    wine
    winetricks

    unstable.claude-code
    claude-aws
    claude-code-router
    claude-router
    ccr-configure-venice
    nodejs
    gh

    unstable.goose-cli
    devenv
    tmux
    tmuxai
  ];

  /*environment.extraSetup = ''
    ln - s ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0 $out/share
    '';*/

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        gtk3
        libnotify
        nss
        libsecret

      ];
    };
    ssh = {
      #package = pkgs.openssh.override { dsaKeysSupport = true; };
      startAgent = false;

      extraConfig = ''
        
      '';
    };

    steam.enable = true;

    wireshark.enable = true;

    chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
        "ldpochfccmkkmhdbclfhpagapcfdljkj" # Decentraleyes
        "kajibbejlbohfaggdiogboambcijhkke" # Mailvelope
        "naepdomgkenhinolocfifgehidddafch" # Browserpass
        "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies


      ];
      defaultSearchProviderSearchURL = "https://duckduckgo.com/?q=%s";
      defaultSearchProviderSuggestURL = "https://duckduckgo.com/?q=%s";
      homepageLocation = "about:blank";
    };

    browserpass = {
      enable = true;
    };

    gnupg = {
      agent = {
        enable = true;
        #pinentryFlavor = "qt";
        pinentryPackage = pkgs.pinentry-qt;
        #enableBrowserSocket = true;
        enableExtraSocket = true;
        enableSSHSupport = true;
      };
      #package = pkgs.unstable.gnupg;
    };

    adb = {
      enable = true;
    };


    #firejail = {
    #  enable = true;
    #};


  };


  nixpkgs.config = {
    allowBroken = true;
    chromium = {
      #enableAdobeFlash = true;
      #enablePepperPDF = true;
      enableWideVine = true; #Still broken
      pulseSupport = true;
      #enableVaapi = true;
    };
    firefox = {
      #enableAdobeFlash = true;
      enableWideVine = true;
      #enableVLC = true;
    };
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };

  };


  services = {
    samba = {
      enable = false;
      package = pkgs.samba4Full;
    };
    gvfs.enable = true;
    printing = {
      enable = true;
      drivers = with pkgs; [ postscript-lexmark ];
    };
    avahi = {
      nssmdns4 = true;
      nssmdns6 = true;
      enable = true;
      publish = {
        enable = false;
      };
    };

    #dbus.packages = [ pkgs.hsphfpd ];

    pipewire =
      {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        jack.enable = true;

        wireplumber = {
          enable = true;
        };

      };

    #passSecretService.enable = true;
  };



  /*
    # GTK3 global theme (widget and icon theme)
    environment.etc."gtk-3.0/settings.ini" = {
    text = ''
    gtk-theme-name=Adapta-Nokto
    gtk-icon-theme-name="elementary"
    gtk-font-name=Sans 10
    gtk-cursor-theme-size=0
    gtk-toolbar-style=GTK_TOOLBAR_BOTH
    gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images=1
    gtk-menu-images=1
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=1
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintfull
    gtk-xft-rgba=rgb
    '';
    mode = "444";
    };

    environment.etc."gtk-2.0/gtkrc" = {
    text = ''
    gtk-theme-name="Adapta-Nokto"
    gtk-icon-theme-name="elementary"
    gtk-font-name="Sans 10"
    gtk-cursor-theme-size=0
    gtk-toolbar-style=GTK_TOOLBAR_BOTH
    gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images=1
    gtk-menu-images=1
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=1
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle="hintfull"
    gtk-xft-rgba="rgb"
    '';
    mode = "444";
    };

    environment.variables = {
    #GTK_DATA_PREFIX = "/run/current-system/sw";

    };
  */

  virtualisation = {
    docker = {
      enable = true;
      #extraOptions = ''
      #    --storage-opt dm.basesize=20G
      #  '';
    };
    waydroid = {
      enable = false;
    };
  };
  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      corefonts
      google-fonts
      hack-font
      powerline-fonts
      emacs-all-the-icons-fonts
      winePackages.fonts
      tratex-font

      dejavu_fonts
      liberation_ttf
      ubuntu_font_family
      noto-fonts-cjk-sans
    ];
  };
  services = {

    #upower.enable = true;
    nscd.enable = true;

    tor = {
      enable = true;
      client.enable = true;
      package = pkgs.tor;
    };

    gpm.enable = true;

    openssh.settings.X11Forwarding = true;

    #udisks2.enable = true;
    devmon.enable = true;

    pcscd = {
      enable = true;
      #plugins = [ pkgs.unstable.ccid ];
    };

    ratbagd = {
      enable = true;
    };

    udev = {
      packages = [
        pkgs.libu2f-host
        pkgs.yubikey-personalization
        pkgs.yubico-piv-tool
        pkgs.yubikey-manager
        pkgs.pcsctools
        pkgs.opensc
        #pkgs.bash
        pkgs.usb-modeswitch-data
        pkgs.ledger-udev-rules
        pkgs.android-udev-rules
      ];


      extraRules = ''
        	

        	SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", ATTRS{manufacturer}=="Flipper Devices Inc.", TAG+="uaccess"
        #Flipper Zero DFU
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", ATTRS{manufacturer}=="STMicroelectronics", TAG+="uaccess"
        #Flipper ESP32s2 BlackMagic
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="40??", ATTRS{manufacturer}=="Flipper Devices Inc.", TAG+="uaccess"

                # this udev file should be used with udev 188 and newer
                ACTION!="add|change", GOTO="u2f_end"

                # Yubico YubiKey
                KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0402|0403|0406|0407|0410", MODE="0660", GROUP="plugdev", TAG+="uaccess"

                LABEL="u2f_end"
                # G29
                #SUBSYSTEMS=="hidraw", KERNELS=="0003:046D:C24F.????", DRIVERS=="logitech", MODE="0660", TAG+="uaccess"

                # Logitech G29 Driving Force Racing Wheel
                #SUBSYSTEMS=="hid", KERNELS=="0003:046D:C24F.????", DRIVERS=="logitech" , MODE="0660", TAG+="uaccess", RUN+="${pkgs.stdenv.shell} -c 'chmod 666 %S%p/../../range; chmod 777 %S%p/../../leds/ %S%p/../../leds/*; chmod 666 %S%p/../../leds/*/brightness'"
                #SUBSYSTEMS=="hid", KERNELS=="0003:046D:C24F.????", DRIVERS=="logitech" , MODE="0660", TAG+="uaccess", RUN+="${pkgs.stdenv.shell} -c 'chmod 666 %S%p/../../../range; chmod 777 %S%p/../../../leds/ %S%p/../../../leds/*; chmod 666 %S%p/../../../leds/*/brightness'"
                SUBSYSTEMS=="hid", KERNELS=="0003:046D:C24F.????", DRIVERS=="logitech", RUN+="${pkgs.stdenv.shell} -c 'cd %S%p/../../../; echo 65535 > autocenter; chmod 666 alternate_modes combine_pedals range gain autocenter spring_level damper_level friction_level ffb_leds peak_ffb_level leds/*/brightness; chmod 777 leds/ leds/*'"
      '';

    };

    redshift = {
      enable = false;
    };

  };

  #sound.mediaKeys.enable = true;

  nixpkgs.overlays = [
    (self: super: {
      #steam = pkgs.steam
      #pcsclite = pkgs.unstable.pcsclite;
    }
    )
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron_24"
    #"p7zip-16.02"
    #"openssl-1.1.1u"
  ];

}
