{ config, lib, pkgs, ... }:
let
  uplink = "enp0s20f0";

in
{

networking = {

  /*
  #Routers 10.5.0.0/24
  vlans."vlan1000".interface = uplink;
  vlans."vlan1000".id = 1000;
  bridges."br1000".interfaces = [ "vlan1000" ];
  interfaces."br1000".useDHCP = false;

  #LAN 10.5.1.0/24
  vlans."vlan1001".interface = uplink;
  vlans."vlan1001".id = 1001;
  bridges."br1001".interfaces = [ "vlan1001" ];
  interfaces."br1001".useDHCP = false;

  #Wifi 10.5.2.0/24
  vlans."vlan1002".interface = uplink;
  vlans."vlan1002".id = 1002;
  bridges."br1002".interfaces = [ "vlan1002" ];
  interfaces."br1002".useDHCP = false;

  #GuestWifi 10.5.3.0/24
  #vlans."vlan1003".interface = uplink;
  #vlans."vlan1003".id = 1003;
  #bridges."br1003".interfaces = [ "vlan1003" ];
  #interfaces."br1003".useDHCP = false;

  #Media 10.5.4.0/24
  vlans."vlan1004".interface = uplink;
  vlans."vlan1004".id = 1004;
  bridges."br1004".interfaces = [ "vlan1004" ];
  interfaces."br1004".useDHCP = false;

  #public_servers 10.5.5.0/24
  vlans."vlan1005".interface = uplink;
  vlans."vlan1005".id = 1005;
  bridges."br1005".interfaces = [ "vlan1005" ];
  interfaces."br1005".useDHCP = false;

  #offline_servers 10.5.6.0/24
  vlans."vlan1006".interface = uplink;
  vlans."vlan1006".id = 1006;
  bridges."br1006".interfaces = [ "vlan1006" ];
  interfaces."br1006".useDHCP = false;
  */

  #Servers 2a0e:b107:330::/64 10.5.20.0/24
  vlans."vlan1020".interface = uplink;
  vlans."vlan1020".id = 1020;
  bridges."br1020".interfaces = [ "vlan1020" ];
  interfaces."br1020".useDHCP = false;

  #LegacyLAN 2a0e:b107:330:4::/64  10.5.24.0/24
  vlans."vlan1024".id = 1024;
  vlans."vlan1024".interface = uplink;
  bridges."br1024".interfaces = [ "vlan1024" ];
  interfaces."br1024".useDHCP = false;

  #MannieL2 2a0e:b107:330:5::/64  10.5.254.2/31
  vlans."vlan2000".id = 2000;
  vlans."vlan2000".interface = uplink;
  bridges."br2000".interfaces = [ "vlan2000" ];
  interfaces."br2000".useDHCP = false;

  #private_servers 10.5.7.0/24
  #vlans."vlan1007".interface = uplink;
  #vlans."vlan1007".id = 1006;
  #bridges."br1007".interfaces = [ "vlan1007" ];
  #interfaces."br1007".useDHCP = false;

  #wireguard_connections 10.5.10.0/24

};

}
