{ config, pkgs, ... }:
let
  rabbitmqConfig = builtins.readFile ./rabbitmq.conf;
in
{
  
imports = [
  ../../../../config/minimum.nix   
];

networking = {
  firewall = {
    enable = false;
  };

  defaultGateway = {
    address = "10.5.30.1";
    interface = "eth0";
  };

  defaultGateway6 = {
    #address = "fe80::1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [
];

services = {

  rabbitmq = {
    enable = true;
    plugins = [ "rabbitmq_mqtt" "rabbitmq_management" "rabbitmq_web_mqtt" ];
    config = rabbitmqConfig;
    };
  };

}
