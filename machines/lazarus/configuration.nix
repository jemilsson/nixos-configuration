{ config, lib, pkgs, ... }:
let
  dpi = 120;

  vpp = pkgs.callPackage pkgs.callPackage ../packages/vpp/default.nix {};
in
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
    initScript.enable = true;


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
     dpi = dpi;

     /*
     displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
        Xft.dpi: ${toString dpi}
       EOF
      '';
    */
   };
   undervolt = {
     enable = false;
   };

 };

/*
 docker-containers = {
   "bpi-build" = {
  image = "sinovoip/bpi-build-linux-4.4";
  environment = {
  };
  volumes = [  ];
  extraDockerOptions = [  ];
};
 };
 */

 #programs.adb.enable = true;

 environment.systemPackages = with pkgs; [

    # On screen keyboard
    gnome3.caribou
    atk

    #heimdall
    #heimdall-gui

    vpp
 ];

 nix = {
   extraOptions = ''
   extra-platforms = aarch64-linux arm-linux
   '';
 };
 boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

 virtualisation.libvirtd = {
   enable = true;
 };

}
