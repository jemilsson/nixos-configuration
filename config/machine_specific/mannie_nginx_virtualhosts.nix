{ config, ... }:
let
  enableSSL = true;
  forceSSL = true;
  enableACME = true;
in
  {
    services.nginx.virtualHosts = {
          "emilsson.cloud" = {
            inherit enableSSL forceSSL enableACME;
            default = true;
            locations = {
              "/" = {
              root = "/var/www/default";
              index = "index.html";
            };
            };
          };

          "emilsson.cloud" = {
            enableSSL = true;
            forceSSL = true;
            enableACME = true;
            default = true;
            locations = {
              "/" = {
              root = "/var/www/default";
              index = "index.html";
            };
            };
          };

         "jonasem.com" = {
           enableSSL = true;
           forceSSL = true;
           enableACME = true;
           default = true;
           locations = {
             "/" = {
             root = "/var/www/default";
             index = "index.html";
           };
           };
         };

         "grafana.jonasem.com" = {
           enableSSL = true;
           forceSSL = true;
           enableACME = true;
           locations = {
             "/" = {
               proxyPass = "http://localhost:3000";
             };
           };
         };
         "influxdb.jonasem.com" = {
           enableSSL = true;
           forceSSL = true;
           enableACME = true;
           locations = {
             "/" = {
               proxyPass = "http://localhost:8086";
             };
           };
         };
     };
}
