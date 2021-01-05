{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  #hostBridge = "br1020";
  localAddress = "10.5.30.2/32";
  localAddress6 = "2a0e:b107:330:beef::2/128";
  hostAddress6 = "fe80::1";
  hostAddress = "10.5.30.1";
  autoStart = true;
  privateNetwork = true;
}
