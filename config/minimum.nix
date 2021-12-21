{ config, lib, pkgs, ... }:
{

  programs = {
    zsh = {
      enable = true;
      autosuggestions = {
        enable = true;
      };
      syntaxHighlighting = {
        enable = true;
      };
      promptInit = "source ${pkgs.zsh-powerlevel9k}/share/zsh-powerlevel9k/powerlevel9k.zsh-theme";
    };
  };

  users.defaultUserShell = "/run/current-system/sw/bin/zsh";

  environment = {
    systemPackages = with pkgs; [
      #System tools
      htop
      wget
      curl
      git

      file
      usbutils

      #Network tools
      tcpdump
      whois
      traceroute
    ];
  };

  networking = {
    search = [ "jonas.systems" ];
  };

}
