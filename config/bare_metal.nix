{ config, lib, pkgs, ... }:
{
  services = {
    fstrim.enable = true;

    fwupd = {
      enable = true;
      enableTestRemote = true;
      package = pkgs.unstable.fwupd;
      blacklistPlugins = [];
    };
  };

  environment = {
    #disrupts git
    #loginShellInit = "hostname | figlet -f big; fortune -a -s | cowsay";

    systemPackages = with pkgs; [
      ethtool
      wol
    ];
  };
}
