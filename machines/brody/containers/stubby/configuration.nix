{ config, pkgs, ... }:
let
  configFile = pkgs.writeText "stubby.yaml" ''
upstream_recursive_servers:

# The Surfnet/Sinodun servers
- address_data: 145.100.185.15
  tls_auth_name: "dnsovertls.sinodun.com"
  tls_pubkey_pinset:
    - digest: "sha256"
      value: 62lKu9HsDVbyiPenApnc4sfmSYTHOVfFgL3pyB+cBL4=

# The Cloudflare server
- address_data: 1.1.1.1
  tls_port: 853
  tls_auth_name: "cloudflare-dns.com"

listen_addresses:
- 10.0.0.5@53
'';
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking.defaultGateway = {
  address = "10.0.0.1";
  interface = "eth0";
};
environment.systemPackages = with pkgs; [
  stubby
  dnsutils
];



systemd.services.stubby = {
      enable = true;
      description = "stubby";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        ExecStart = "${pkgs.stubby}/bin/stubby  -C ${configFile}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };


}
