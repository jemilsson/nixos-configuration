{ config, ... }:
  {
    services.nginx = {
       enable = true;
       recommendedOptimisation=true;
       recommendedProxySettings=true;
       recommendedTlsSettings = true;
       recommendedGzipSettings = true;
       sslCiphers = "EECDH+aRSA+AESGCM:EDH+aRSA:EECDH+aRSA:+AES256:!AESGCM128:!ARIA128:!AES128:!SHA1:!SHA256:!SHA384:!CAMELLIA:!SEED:!3DES:!DES:!RC4:!eNULL";
       appendHttpConfig="server_names_hash_bucket_size 128; add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\" always;";
       sslDhparam = "/var/lib/dhparams/nginx.pem";
       statusPage = true;
    };
    security = {
       dhparams = {
         enable = true;
         params = {
           nginx = 4096;
         };
       };
    };
}
