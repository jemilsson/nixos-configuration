{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  defaultGateway = { address = "10.5.24.1";};

  };

services = {
  avahi = {
    enable = true;
    reflector = true;
    nssmdns = true;
    ipv6 = true;
    ipv4 = true;
    interfaces = [ "eth0" "eth1024-1" ];

    extraServiceFiles = {
      shield = ''
      <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name>HelloWorld</name>
        <service>
          <type>_androidtvremote._tcp</type>
          <port>6466</port>
          <host-name>shield.local</host-name>
        </service>
      </service-group>
      '';

    };
  };
};

environment.etc."avahi/hosts".text = ''
2a0e:b107:330:4:c516:4e7a:40c:43a1 shield.local
'';


    environment.systemPackages = with pkgs; [

    ];



}
