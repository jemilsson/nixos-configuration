{ config, lib, pkgs, ... }:
  let
      app = pkgs.callPackage ./default.nix {};
  in
  {

  users.users."vpp" = {
  createHome = true;
  isSystemUser = true;
  group = "vpp";
  home = "/home/vpp";
 };

 users.groups."vpp" = {
     members = ["vpp"];
 };


  systemd.services.vpp = {
  description = "vpp";
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${app}/bin/vpp -c ${app}/etc/vpp/startup.conf";
    User = "vpp";
    Group = "vpp";
    };
  };

  environment.systemPackages = [app];
}