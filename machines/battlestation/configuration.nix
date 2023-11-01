{ config, lib, pkgs, ... }:
{
  imports = [
    ../../config/desktop_base.nix
    ../../config/services/kvm/kvm.nix
    ../../config/i3_x11.nix
    ../../config/location/sesto01/configuration.nix
    ../../config/language/english.nix
    ./hardware-configuration.nix
  ];
  /*
  age.rekey = {
    # Obtain this using `ssh-keyscan` or by looking it up in your ~/.ssh/known_hosts
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtJIhxEVsyKN/7fUBN4DYFoU6wgMJZbC8+hZk7Rv4Cx";
    # The path to the master identity used for decryption. See the option's description for more information.
    masterIdentities = [ ../../age/jonas-yubikey-7447013.pub ];
    #masterIdentities = [ "/home/myuser/master-key" ]; # External master key
    #masterIdentities = [ "/home/myuser/master-key.age" ]; # Password protected external master key

    generatedSecretsDir = ./secrets;
  };

  #age.secrets.secret1.rekeyFile = ./secrets/secret1.age;
  age.secrets.secret1.generator.script = "alnum";

  environment.etc."secret1" = {
    source = config.age.secrets.secret1.path;
  };
  */
  system.stateVersion = "18.09";

  hardware.cpu.amd.updateMicrocode = true;

  networking = {
    hostName = "battlestation";
    firewall.allowedTCPPorts = [ 3389 ];
    firewall.allowedUDPPorts = [ 59802 ];
  };
  

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  #boot.kernelPackages = pkgs.linuxPackages_latest_hardened;
  #boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  services = {
    #wakeonlan.interfaces = [
    #  { interface = "enp8s0"; method = "password"; password = "00:11:22:33:44:55"; }
    #];


    #Logitech G29
    #udev = {
    #  packages = with pkgs; [
    #    unstable.usb-modeswitch-data
    #    unstable.usb-modeswitch
    #  ];
    #};

    xserver = {
      videoDrivers = [ "amdgpu" ];

      deviceSection = ''
        Option "DRI3" "1"
        Option "TearFree" "on"
      '';
    };

    lldpd = {
      enable = true;
    };

  };


  programs = {
    java.package = pkgs.jdk;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.

  environment.systemPackages = with pkgs; [
    #teamspeak_client
    vscode
    virtmanager

    taskwarrior

    elmPackages.elm

    freerdp

    xca

    wasabiwallet
  ];

  nixpkgs.overlays = [
    (self: super: {
      #mesa = pkgs.unstable.mesa;
      #mesa_glu = pkgs.unstable.mesa_glu;
      #mesa_noglu = pkgs.unstable.mesa_noglu;
      #mesa_drivers = pkgs.unstable.mesa_drivers;
      #xorg.xf86videoamdgpu = pkgs.unstable.xorg.xf86videoamdgpu;
      #steam-run = pkgs.unstable.steam-run;
      #steam = pkgs.unstable.steam;
      #steam-runtime = pkgs.unstable.steam-runtime;
      #steam-runtime-wrapped = pkgs.unstable.steam-runtime-wrapped;
      #steam-fonts = pkgs.unstable.steam-fonts;
      #steam-chrootenv = pkgs.unstable.steam-chrootenv;
      #vulkan-loader = pkgs.unstable.vulkan-loader;
      #zsh-powerlevel9k = pkgs.zsh-powerlevel9k;
      #handbrake = super.handbrake.override { useGtk = true; };
    }
    )
  ];





}
