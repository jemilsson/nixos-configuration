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

    publish = {
      enable = true;
    };

    extraServiceFiles = {
      shieldAndroidRemote = ''
      <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name>HelloWorld</name>
        <service>
          <type>_androidtvremote._tcp</type>
          <port>6466</port>
          <host-name>shield.sesto01.jonas.systems</host-name>
        </service>
      </service-group>
      '';
    shieldCast = ''
    <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
      <name>HelloWorld</name>
      <service>
        <type>_googlecast._tcp</type>
        <port>8009</port>
        <host-name>shield.sesto01.jonas.systems</host-name>
      </service>
    </service-group>
    '';
  };
  };
};

environment.etc."avahi/hosts".text = ''
2a0e:b107:330:0:3385:bf0f:1be8:8b8d shield.local
2a0e:b107:330:0:3385:bf0f:1be8:8b8d HelloWorld.local
'';


    environment.systemPackages = with pkgs; [

    ];



}
