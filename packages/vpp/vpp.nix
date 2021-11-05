{ config, lib, pkgs, ... }:
  let
      app = import ./default.nix { };
  in
  {

  users.users."vpp" = {
  createHome = true;
  isSystemUser = true;
  group = "vpp";
  home = "/home/vpp";
 };


  systemd.services.vpp = {
  description = "vpp";
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${app}/bin/vpp -c {app}/etc/vpp/startup.conf";
    User = "vpp";
    Group = "vpp";
    };
  };

  environment.systemPackages = [app];
}