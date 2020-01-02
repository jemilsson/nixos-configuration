{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1020";
  localAddress6 = "2a0e:b107:330::10/64";
  autoStart = true;
  privateNetwork = true;

  extraVeths = {
    "eth1024-1" = {
      hostBridge = "br1024";
      localAddress6 = "2a0e:b107:330:4::10/64";
    };
  };
}
