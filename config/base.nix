{ config, lib, pkgs, ... }:

{
  imports = [
    ../../hardware-configuration.nix

];

boot.loader.grub = {
    enable = true;
    version = 2;
  };

time.timeZone = "Europe/Stockholm";

system = {
  autoUpgrade = {
    enable = true;
  };
  stateVersion = "17.03";
};

services = {
  openssh.enable = true;
};

nixpkgs.config.allowUnfree = true;

programs = {
  fish.enable = true;
};

environment.systemPackages = with pkgs; [
  #System tools
  htop
  git
  wget

  #Network tools
  tcpdump

];

networking = {
  timeServers = [
    "sth1.ntp.se"
    "sth2.ntp.se"
    "ntp3.sptime.se"
    "ntp4.sptime.se"
  ];

};

nix = {
  autoOptimiseStore = true;
  gc = {
    automatic = true;
    dates = "04:00";
  };
};

}
