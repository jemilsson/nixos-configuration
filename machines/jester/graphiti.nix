{ config, lib, pkgs, ... }:
let
  graphiti = pkgs.callPackage ../../packages/graphiti/default.nix { };
in
{
  services = {
    neo4j = {
      enable = true;
      bolt.enable = true;
      bolt.tlsLevel = "DISABLED";
      https.enable = false;
      http.enable = true;
      
      directories.home = "/var/lib/neo4j";
      
      bolt.listenAddress = "127.0.0.1:7687";
      http.listenAddress = "127.0.0.1:7474";
    };
  };

  # System packages for Graphiti MCP
  environment.systemPackages = with pkgs; [
    neo4j-desktop
    graphiti
    python3
    uv
  ];


  # Systemd service for Graphiti MCP server
  systemd.services.graphiti-mcp = {
    description = "Graphiti MCP Server";
    after = [ "neo4j.service" ];
    wants = [ "neo4j.service" ];
    wantedBy = [ "multi-user.target" ];
    
    environment = {
      GRAPHITI_TELEMETRY_ENABLED = "false";
    };
    
    serviceConfig = {
      Type = "simple";
      User = "graphiti";
      Group = "graphiti";
      WorkingDirectory = "/var/lib/graphiti";
      ExecStart = "${graphiti}/bin/graphiti-mcp-server";
      Restart = "always";
      RestartSec = 5;
      EnvironmentFile = "/var/lib/graphiti/graphiti-env";
    };
  };

  # Create graphiti user and group
  users.users.graphiti = {
    isSystemUser = true;
    group = "graphiti";
    home = "/var/lib/graphiti";
    createHome = true;
  };

  users.groups.graphiti = {};
}