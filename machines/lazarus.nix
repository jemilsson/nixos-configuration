{ config, lib, pkgs, ... }:

{
  imports = [
    ../config/x_desktop.nix
  ];
  networking.hostName = "lazarus";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.tlp.enable = true;

  #boot.loader.grub.device = "/dev/sda";

  # Define a user account. Don't forget to set a password with ‘passwd’.
 users.extraUsers = {
   user = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/jonas/";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = "/run/current-system/sw/bin/fish";
    createHome = true;
    };

    wanida = {
      isNormalUser = true;
      uid = 1001;
      home = "/home/wanida/";
      extraGroups = [ "networkmanager" ];
      shell = "/run/current-system/sw/bin/fish";
      createHome = true;
    };
  };

 services.xserver.desktopManager.gnome3.enable = true;

 environment.systemPackages = with pkgs; [

    # On screen keyboard
    gnome3.caribou
    atk
 ];

}
