{ config, pkgs, ... }:
let
pmacctd_config = pkgs.writeText "pmacctd.config" ''
#daemonize: true
daemonize: false
interface: enp0s20f1
aggregate: src_host, dst_host, src_port, dst_port, proto, tos, vlan, src_mac, dst_mac, timestamp_arrival
plugins: nfprobe
nfprobe_receiver: 127.0.0.1:9995
! Do IPFIX:
nfprobe_version: 10
nfprobe_timeouts: tcp=30:maxlife=60
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
  interfaces."enp0s20f1".useDHCP = false;

  nameservers = [ "10.5.20.1" ];

  defaultGateway = {
    address = "10.5.20.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [
  unstable.pmacct
];

*/
services = {
  ntopng = {
    enable = true;
    http-port = 3000;
    interfaces = [ "enp0s20f1" ];
  };
};
*/

systemd.services.pmacctd = {
      description = "pmacctd IPFIX distributor";
      after = [ "network.target" ];
      before = [ "nss-lookup.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        AmbientCapabilities = "CAP_NET_BIND_SERVICE,CAP_NET_ADMIN";
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE,CAP_NET_ADMIN";
        ExecStart = "${pkgs.unstable.pmacct}/bin/pmacctd - ${pmacctd_config}";
        DynamicUser = true;
      };
}
