{ config, pkgs, ... }:
let
pmacctd_config = pkgs.writeText "nfacctd.config" ''
#daemonize: true
daemonize: false
pmacctd_nonroot: true
aggregate: src_host, dst_host, src_port, dst_port, proto, tos, vlan, src_mac, dst_mac, timestamp_arrival
plugins: print
nfacctd_port: 9995
nfacctd_renormalize: true
print_output_file: /tmp/ipfix.json
'';
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };

  nameservers = [ "10.5.20.1" ];

  defaultGateway = {
    address = "10.5.20.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [
  unstable.pmacct
];

/*
services = {
  ntopng = {
    enable = true;
    http-port = 3000;
    interfaces = [ "enp0s20f1" ];
  };
};
*/

systemd.services.nfacctd = {
      description = "nfacctd IPFIX collector";
      after = [ "network.target" ];
      before = [ "nss-lookup.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.unstable.pmacct}/bin/nfacctd -f ${nfacctd_config}";
        DynamicUser = true;
      };
  };
}
