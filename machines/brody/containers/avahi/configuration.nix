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
        <txt-record>rs=s</txt-record>
        <txt-record>nf=1</txt-record>
        <txt-record>bs=FA8F70F3B781</txt-record>
        <txt-record>st=0</txt-record>
        <txt-record>ca=200709</txt-record>
        <txt-record>fn=AndroidTV</txt-record>
        <txt-record>ic=/setup/icon.png</txt-record>
        <txt-record>md=SHIELD Android TV</txt-record>
        <txt-record>ve=05</txt-record>
        <txt-record>rm=</txt-record>
        <txt-record>cd=F65683CC58FE3F2805CA04DEC27488B3</txt-record>
        <txt-record>id=3cde360ad8d4b999f10c32ea3673d6eb</txt-record>
      </service>
    </service-group>
    '';
  };
  };
};

#environment.etc."avahi/hosts".text = ''
#2a0e:b107:330:4:c516:4e7a:40c:43a1 shield.local
#'';


    environment.systemPackages = with pkgs; [

    ];



}
