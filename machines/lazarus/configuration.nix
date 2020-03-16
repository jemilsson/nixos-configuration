{ config, lib, pkgs, ... }:

{
  imports = [
    ../../config/laptop_base.nix
    ../../config/i3_x11.nix
    ../../config/language/english.nix
  ];

  networking.hostName = "lazarus";
  system.stateVersion = "18.09";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };


  #boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

 users.extraUsers = {
    wanida = {
      isNormalUser = true;
      uid = 1001;
      home = "/home/wanida/";
      extraGroups = [ "networkmanager" ];
      createHome = true;
      useDefaultShell = true;
    };
  };

 services = {
   xserver = {
     videoDrivers = [ "intel" "modesetting" ];

     desktopManager.gnome3.enable = true;
     dpi = 144;

   };
   undervolt = {
     enable = false;
   };

 };

 docker-containers = {
   "bpi-build" = {
  image = "sinovoip/bpi-build-linux-4.4";
  environment = {
  };
  volumes = [  ];
  extraDockerOptions = [  ];
};
 };

 #programs.adb.enable = true;

 environment.systemPackages = with pkgs; [

    # On screen keyboard
    gnome3.caribou
    atk

    #heimdall
    #heimdall-gui
 ];

}
