{ config, lib, pkgs, ... }:

{
  imports = [
    ./base.nix
  ];


  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];

      };

  };

  services.fail2ban = {
    enable = true;
    jails = {
      DEFAULT =
        ''
          bantime  = 3600
        '';
      sshd =
        ''
          filter = sshd
          maxretry = 4
          action   = iptables[name=ssh, port=ssh, protocol=tcp]
          enabled  = true
        '';

      sshd-ddos =
        ''
          filter = sshd-ddos
          maxretry = 2
          action   = iptables[name=ssh, port=ssh, protocol=tcp]
          enabled  = true
        '';

      jails.port-scan =
        ''
          filter   = port-scan
          action   = iptables-allports[name=port-scan]
          maxretry = 2
          bantime  = 7200
          enabled  = true
        '';
    };
}
