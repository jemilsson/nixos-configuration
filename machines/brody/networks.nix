{ config, lib, pkgs, ... }:
let
  uplink = "enp0s20f0";

in
{

networking = {

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
  #vlans."vlan1004".interface = uplink;
  #vlans."vlan1004".id = 1004;
  #bridges."br1004".interfaces = [ "vlan1004" ];
  #interfaces."br1004".useDHCP = false;

  #public_servers 10.5.5.0/24
  #vlans."vlan1005".interface = uplink;
  #vlans."vlan1005".id = 1005;
  #bridges."br1005".interfaces = [ "vlan1005" ];
  #interfaces."br1005".useDHCP = false;


  #offline_servers 10.5.6.0/24
  vlans."vlan1006".interface = uplink;
  vlans."vlan1006".id = 1006;
  bridges."br1006".interfaces = [ "vlan1006" ];
  interfaces."br1006".useDHCP = false;

  #private_servers 10.5.7.0/24
  #vlans."vlan1007".interface = uplink;
  #vlans."vlan1007".id = 1006;
  #bridges."br1007".interfaces = [ "vlan1007" ];
  #interfaces."br1007".useDHCP = false;

};

}
