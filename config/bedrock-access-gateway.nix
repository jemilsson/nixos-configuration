{ config, pkgs, lib, ... }:
let
  serviceName = "bedrock-access-gateway";
  port = 8001;
  package = pkgs.callPackage ../packages/bedrock-access-gateway { };
  mangum = pkgs.python3.pkgs.callPackage ../packages/python-mangum { };
in
{
  # Add package to system packages so users can access it
  environment.systemPackages = [ package ];

  # User service configuration
  systemd.user.services.${serviceName} = {
    description = "Bedrock Access Gateway (User Service)";
    after = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "exec";
      ExecStart = "${package}/bin/bedrock-access-gateway";
      Environment = [
        "DEBUG=false"
        "AWS_MAX_ATTEMPTS=3"
        "AWS_RETRY_MODE=adaptive"
        "AWS_REGION=us-east-1"
        "AWS_SHARED_CREDENTIALS_FILE=%h/.aws/credentials"
        "AWS_CONFIG_FILE=%h/.aws/config"
        "UVICORN_PORT=${toString port}"
        "UVICORN_HOST=127.0.0.1"
        "PYTHONPATH=${mangum}/${pkgs.python3.sitePackages}:$PYTHONPATH"
      ];
      Restart = "on-failure";
      RestartSec = 5;

      # Reduced security settings for user service
      NoNewPrivileges = true;
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
    };
  };

  # Environment setup instructions
  environment.etc."bedrock-access-gateway-setup.md".text = ''
    # Bedrock Access Gateway Setup

    This service provides OpenAI-compatible access to AWS Bedrock models.

    ## AWS Credentials Setup
    
    Set up your AWS credentials using one of these methods:
    
    1. AWS CLI: `aws configure`
    2. Environment variables:
       ```
       export AWS_ACCESS_KEY_ID=your_access_key
       export AWS_SECRET_ACCESS_KEY=your_secret_key
       export AWS_DEFAULT_REGION=us-east-1
       ```
    3. AWS credentials file: ~/.aws/credentials

    ## Service Management

    The service runs as a user systemd service:
    - Status: systemctl --user status ${serviceName}.service
    - Start: systemctl --user start ${serviceName}.service
    - Stop: systemctl --user stop ${serviceName}.service
    - Enable autostart: systemctl --user enable ${serviceName}.service

    ## Testing

    curl http://127.0.0.1:${toString port}/v1/models

    ## Configuration

    The service runs on 127.0.0.1:${toString port}
    Configure your AI tools to use: http://127.0.0.1:${toString port}
  '';
}