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
  #claude-code-router = pkgs.callPackage ../packages/claude-code-router/default.nix {};
  #claude-router = pkgs.callPackage ../packages/claude-router/default.nix { 
  #  claude-code-router = claude-code-router;
  #};

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
    ./appearance.nix
    #./systemd_user/gpg-agent.nix
    #./x11.nix

  ];


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


  # GTK icon cache moved to appearance.nix

  security.rtkit.enable = true;

  hardware = {
    enableAllFirmware = true;

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
        libva-vdpau-driver
        intel-vaapi-driver
        vpl-gpu-rt
      ];
      extraPackages32 = with pkgs; [
        intel-compute-runtime
        intel-media-driver
        libvdpau-va-gl
        libva-vdpau-driver
        intel-vaapi-driver
        vpl-gpu-rt
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

    flipperzero.enable=true;

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
    #unstable.bambu-studio
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
    #albert  # Temporarily disabled due to submodule authentication issues
    synapse
    feh
    (freerdp.override { pcsclite = pcsclite; libpulseaudio = libpulseaudio; })
    rdesktop
    appimage-run

    #Ricing packages moved to appearance.nix

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
    telegram-desktop
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
    pcsc-tools
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
    unstable.claude-code-router
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

    steam.enable = false;  # Temporarily disabled due to inode exhaustion

    wireshark.enable = true;

    chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
        "ldpochfccmkkmhdbclfhpagapcfdljkj" # Decentraleyes
        "naepdomgkenhinolocfifgehidddafch" # Browserpass
        "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies


      ];
      defaultSearchProviderSearchURL = "https://duckduckgo.com/?q=%s";
      defaultSearchProviderSuggestURL = "https://duckduckgo.com/?q=%s";
      homepageLocation = "about:blank";
      extraOpts = {
        CommandLineFlagSecurityWarningsEnabled = false;
      };
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



  # GTK theming configuration moved to appearance.nix

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
  # Additional fonts beyond the main appearance configuration
  fonts.packages = with pkgs; [
    corefonts
    google-fonts
    hack-font
    powerline-fonts
    emacs-all-the-icons-fonts
    winePackages.fonts
    tratex-font
    dejavu_fonts
    liberation_ttf
    ubuntu-classic
    noto-fonts-cjk-sans
    ibm-plex
    nerd-fonts.fira-code
  ];
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
      plugins = [ pkgs.ccid ];
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
        pkgs.pcsc-tools
        pkgs.opensc
        #pkgs.bash
        pkgs.usb-modeswitch-data
        pkgs.ledger-udev-rules
        # pkgs.android-udev-rules # Removed - superseded by built-in systemd uaccess rules
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
