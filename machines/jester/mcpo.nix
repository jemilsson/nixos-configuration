{ pkgs, ... }:

let
  mcpo = pkgs.python3Packages.callPackage ../../packages/mcpo { };
  graphiti = pkgs.callPackage ../../packages/graphiti/default.nix { };

  # Graphiti MCP server wrapper script
  graphitiScript = pkgs.writeShellApplication {
    name = "graphiti-mcp";
    runtimeInputs = [ graphiti pkgs.coreutils ];
    text = ''
      # Source environment variables from secrets file
      if [ -f /var/lib/mcpo/graphiti-env ]; then
        set -a
        # shellcheck disable=SC1091
        source /var/lib/mcpo/graphiti-env
        set +a
      fi
      
      # Use the built Graphiti MCP server directly
      exec ${graphiti}/bin/graphiti-mcp-server
    '';
  };

  # MCPO configuration with Graphiti MCP server using SSE transport
  mcpoConfig = pkgs.writeText "mcpo-config.json" (builtins.toJSON {
    mcpServers = {
      graphiti = {
        type = "sse";
        url = "http://localhost:8000/sse";
      };
    };
  });
in
{
  # Install required packages
  environment.systemPackages = [
    mcpo
    graphiti
  ];

  # Create mcpo service
  systemd.services.mcpo = {
    description = "MCPO - MCP to OpenAPI Proxy";
    after = [ "network.target" "neo4j.service" "graphiti-mcp.service" ];
    wants = [ "neo4j.service" "graphiti-mcp.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "mcpo";
      Group = "mcpo";
      WorkingDirectory = "/var/lib/mcpo";
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p /var/lib/mcpo"
        "${pkgs.bash}/bin/bash -c 'if [ ! -f /var/lib/mcpo/api-key ]; then echo \"sk-$(head -c 36 /dev/urandom | base64 | tr -d '/' | tr -d '+' | cut -c1-48)\" > /var/lib/mcpo/api-key; fi'"
        "${pkgs.bash}/bin/bash -c 'if [ ! -f /var/lib/mcpo/graphiti-env ]; then echo \"WARNING: Graphiti environment file missing. Please create /var/lib/mcpo/graphiti-env with OPENAI_API_KEY and NEO4J_PASSWORD.\" >&2; fi'"
      ];
      ExecStart = "${pkgs.bash}/bin/bash -c '${mcpo}/bin/mcpo --host 127.0.0.1 --port 8082 --api-key \"$(cat /var/lib/mcpo/api-key)\" --config ${mcpoConfig} --cors-allow-origins \"*\"'";
      Restart = "always";
      RestartSec = 5;

      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/mcpo" ];
    };
  };

  # Create mcpo user
  users.users.mcpo = {
    isSystemUser = true;
    group = "mcpo";
    home = "/var/lib/mcpo";
    createHome = true;
  };

  users.groups.mcpo = {};

  # No external firewall ports needed - MCPO only accessed internally
}