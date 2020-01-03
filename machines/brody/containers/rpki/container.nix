{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1020";
  localAddress6 = "2a0e:b107:330::11/64";
  autoStart = true;
  privateNetwork = true;
}
