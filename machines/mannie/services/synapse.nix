{ config, lib, pkgs, ... }:
{
  services = {

    matrix-synapse = {
      enable = true;
      enable_registration = false;
      no_tls = true;
      web_client = true;
      public_baseurl = "https://emilsson.chat/";
      server_name = "emilsson.chat";
      database_type = "psycopg2";
      database_args = {
         user = "synapse";
         password = "mBgLGniz7i0maQDR";
         database = "synapse";
         host = "127.0.0.1";
         cp_min = "5";
         cp_max = "10";
      };
      listeners = [
       {
         bind_address = "127.0.0.1";
         port = 8448;
         tls = false;
         type = "http";
         x_forwarded = true;
         resources = [
           { compress = false;
             names = [ "client" "webclient"];
           }
         ];
       }
      ];
    };

    nginx.virtualHosts = {
      "emilsson.chat" = {
        enableSSL = true;
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:8448";
          };
        };
      };
    };
};

}
