{ config, lib, pkgs, ... }:

{
  imports = [
    ../../config/laptop_base.nix
    ../../config/kde_x11.nix
    ../../config/emilsson.nix
    ../../config/language/swedish.nix
  ];

  system.stateVersion = "19.03";

  networking.hostName = "thor";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };


  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  services = {
    xserver = {
      videoDrivers = [ "intel" ];
    };
  };

  environment.systemPackages = with pkgs; [

  ];

}
