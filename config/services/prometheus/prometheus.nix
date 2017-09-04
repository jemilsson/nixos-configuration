{ pkgs, lib, config, ... }:
{
  imports = [
    ./node_exporter.nix
  ];
  services = {
    prometheus = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "node";
          scrape_interval = "10s";
          static_configs = [
            {
              targets = [
                "localhost:9100"
              ];
              labels = {
                alias = "${config.networking.hostName}";
              };
            }
          ];
        }
      ];
    };
  };
}
