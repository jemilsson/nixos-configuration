{ config, pkgs, ... }:
let
  configFile = pkgs.writeText "stubby.yaml" ''
resolution_type: GETDNS_RESOLUTION_STUB

dns_transport_list:
  - GETDNS_TRANSPORT_TLS

tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
tls_query_padding_blocksize: 128

edns_client_subnet_private : 1
round_robin_upstreams: 1
idle_timeout: 10000


upstream_recursive_servers:

# The Surfnet/Sinodun servers
  - address_data: 145.100.185.15
    tls_auth_name: "dnsovertls.sinodun.com"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: 62lKu9HsDVbyiPenApnc4sfmSYTHOVfFgL3pyB+cBL4=
  - address_data: 145.100.185.16
    tls_auth_name: "dnsovertls1.sinodun.com"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: cE2ecALeE5B+urJhDrJlVFmf38cJLAvqekONvjvpqUA=

# The getdnsapi.net server
  - address_data: 185.49.141.37
    tls_auth_name: "getdnsapi.net"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: foxZRnIh9gZpWnl+zEiKa0EJ2rdCGroMWm02gaxSc9Q=
# The Uncensored DNS servers
  - address_data: 89.233.43.71
    tls_auth_name: "unicast.censurfridns.dk"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: wikE3jYAA6jQmXYTr/rbHeEPmC78dQwZbQp6WdrseEs=

# A Surfnet/Sinodun server supporting TLS 1.2 and 1.3
  - address_data: 145.100.185.18
    tls_auth_name: "dnsovertls3.sinodun.com"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: 5SpFz7JEPzF71hditH1v2dBhSErPUMcLPJx1uk2svT8=

# A Surfnet/Sinodun server using Knot resolver. Warning - has issue when used
# for DNSSEC
  - address_data: 145.100.185.17
    tls_auth_name: "dnsovertls2.sinodun.com"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: NAXBESvpjZMnPWQcrxa2KFIkHV/pDEIjRkA3hLWogSg=

# dns.cmrg.net server using Knot resolver. Warning - has issue when used for
# DNSSEC.
  - address_data: 199.58.81.218
    tls_auth_name: "dns.cmrg.net"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: 3IOHSS48KOc/zlkKGtI46a9TY9PPKDVGhE3W2ZS4JZo=
      - digest: "sha256"
        value: 5zFN3smRPuHIlM/8L+hANt99LW26T97RFHqHv90awjo=

# dns.larsdebruin.net (formerly dns1.darkmoon.is)
  - address_data: 51.15.70.167
    tls_auth_name: "dns.larsdebruin.net "
    tls_pubkey_pinset:
      - digest: "sha256"
        value: AAT+rHoKx5wQkWhxlfrIybFocBu3RBrPD2/ySwIwmvA=

# dot.securedns.eu
  - address_data: 146.185.167.43
    tls_auth_name: "dot.securedns.eu"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: h3mufC43MEqRD6uE4lz6gAgULZ5/riqH/E+U+jE3H8g=

# dns-tls.bitwiseshift.net
  - address_data: 81.187.221.24
    tls_auth_name: "dns-tls.bitwiseshift.net"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: YmcYWZU5dd2EoblZHNf1jTUPVS+uK3280YYCdz4l4wo=

# ns1.dnsprivacy.at
  - address_data: 94.130.110.185
    tls_auth_name: "ns1.dnsprivacy.at"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: vqVQ9TcoR9RDY3TpO0MTXw1YQLjF44zdN3/4PkLwtEY=

# ns2.dnsprivacy.at
  - address_data: 94.130.110.178
    tls_auth_name: "ns2.dnsprivacy.at"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: s5Em89o0kigwfBF1gcXWd8zlATSWVXsJ6ecZfmBDTKg=

# dns.bitgeek.in
  - address_data: 139.59.51.46
    tls_auth_name: "dns.bitgeek.in"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: FndaG4ezEBQs4k0Ya3xt3z4BjFEyQHd7B75nRyP1nTs=

# Lorraine Data Network  (self-signed cert).
  - address_data: 80.67.188.188
    tls_pubkey_pinset:
      - digest: "sha256"
        value: WaG0kHUS5N/ny0labz85HZg+v+f0b/UQ73IZjFep0nM=

# dns.neutopia.org
  - address_data: 89.234.186.112
    tls_auth_name: "dns.neutopia.org"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: wTeXHM8aczvhRSi0cv2qOXkXInoDU+2C+M8MpRyT3OI=

listen_addresses:
- 0.0.0.0@53
'';
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  defaultGateway = {
    address = "10.5.1.1";
    interface = "eth0";
  };
  firewall = {
    allowedUDPPorts = [ 53 ];
  };
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
        ExecStart = "${pkgs.stubby}/bin/stubby  -C ${configFile} -l";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };


}
