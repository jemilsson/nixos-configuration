{ config, pkgs, ... }:

{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };
  nameservers = [ "10.5.20.1" ];

  defaultGateway = {
    address = "10.5.20.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [

];

services = {
  grafana = {
    enable = true;
    analytics = {
      reporting.enable = true;
    };
    auth = {
      anonymous = {
        enable = true;
        org_role = "Editor";
        org_name = "org";
      };
    };
    addr = "0.0.0.0";

  };
};

nixpkgs.overlays = [
    (self: super: {
      prometheus = pkgs.unstable.prometheus_2;
    }
    )
  ];

}
