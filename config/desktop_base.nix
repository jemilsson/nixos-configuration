{ config, lib, pkgs, ... }:

{
  imports = [
    ./base.nix
  ];

  hardware = {

    pulseaudio = {
      enable = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [ libvdpau-va-gl vaapiVdpau ];
      extraPackages32 = with pkgs; [ libvdpau-va-gl vaapiVdpau ];
    };

  };

  networking.networkmanager.enable = true;


  environment.systemPackages = with pkgs; [
    #Browsers
    firefox
    chromium
    google-chrome

    #Media
    spotify
    vlc
    pavucontrol
    pasystray
    audacity
    gimp
    playerctl

    #Programming
    atom
    eclipses.eclipse-platform

    #Interface
    rxvt_unicode
    synapse
    feh

    #Ricing
    paper-icon-theme
    gtk3
    gtk-engine-murrine
    lxappearance

    #Graphical System tools
    gnome3.gedit
    gnome3.nautilus
    gnome3.sushi
    gnome3.file-roller
    gparted
    file
    keepass

    #Office
    libreoffice

    #Communication
    pidgin
    skype

    #Games
    steam

    #Graphical network tools
    wireshark

    #Security
    libu2f-host
    gnupg
    pinentry_ncurses


  ];

  nixpkgs.config = {
    chromium = {
      enableAdobeFlash = true;
      enablePepperPDF = true;
      #enableWideVine = true;
      gnomeKeyringSupport = true;
      pulseSupport = true;
    };
    firefox = {
      enableAdobeFlash = true;
      enableWideVine = true;
    };
  };


  #services = {
  #    autofs.enable = true;
  #};

  systemd.user.services."urxvtd" = {
      enable = true;
      description = "rxvt unicode daemon";
      wantedBy = [ "default.target" ];
      path = [ pkgs.rxvt_unicode ];
      serviceConfig.Restart = "always";
      serviceConfig.RestartSec = 2;
      serviceConfig.ExecStart = "${pkgs.rxvt_unicode}/bin/urxvtd -q -o";
    };

    # GTK3 global theme (widget and icon theme)
  environment.etc."gtk-3.0/settings.ini" = {
    text = ''
      gtk-theme-name=Adapta-Nokto
      gtk-icon-theme-name=Paper
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
      gtk-icon-theme-name="Paper"
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
    GTK_DATA_PREFIX = "/run/current-system/sw";

  };

  fonts = {
     enableFontDir = true;
     enableGhostscriptFonts = true;
     fonts = with pkgs; [
       google-fonts
       hack-font
       font-awesome-ttf
     ];
   };
   services = {

     pcscd.enable = true;

     udev.extraRules = ''
        # this udev file should be used with udev 188 and newer
        ACTION!="add|change", GOTO="u2f_end"

        # Yubico YubiKey
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0402|0403|0406|0407|0410", MODE="0660", GROUP="plugdev", TAG+="uaccess"

        LABEL="u2f_end"
      '';
    gnome3 = {
      gnome-keyring.enable = true;
    };

    };


}
