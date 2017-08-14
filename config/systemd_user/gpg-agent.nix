# https://github.com/gpg/gnupg/tree/master/doc/examples/systemd-user
{ config, lib, pkgs, ... }:
{
  systemd = {
    user = {
      services = {
        "gpg-agent" = {
          enable = false;
          path = [ pkgs.gnupg ];

          #Unit
          description = "GnuPG cryptographic agent and passphrase cache";
          documentation = [ "man:gpg-agent(1)" ];
          requires = [ "gpg-agent.socket" ];

          #Service
          serviceConfig = {
            ExecStart = "${pkgs.gnupg}/bin/gpg-agent --supervised";
            ExecReload = "${pkgs.gnupg}/bin/gpgconf --reload gpg-agent";
          };
        };
      };

      sockets = {

        "gpg-agent" = {
          enable = true;

          #Unit
          description = "GnuPG cryptographic agent and passphrase cache";
          documentation = [ "man:gpg-agent(1)" ];

          #Socket
          socketConfig = {
            ListenStream = "%t/gnupg/S.gpg-agent";
            FileDescriptorName = "std";
            SocketMode = "0600";
            DirectoryMode = "0700";
          };

          #Install
          wantedBy = [ "sockets.target" ];
        };

        "gpg-agent-ssh" = {
          enable = true;

          #Unit
          description = "GnuPG cryptographic agent (ssh-agent emulation)";
          documentation = [ "man:gpg-agent(1)" "man:ssh-add(1)" "man:ssh-agent(1)" "man:ssh(1)" ];

          #Socket
          socketConfig = {
            ListenStream = "%t/gnupg/S.gpg-agent.ssh";
            FileDescriptorName = "ssh";
            Service = "gpg-agent.service";
            SocketMode = "0600";
            DirectoryMode = "0700";
          };

          #Install
          wantedBy = [ "sockets.target" ];
        };

        "gpg-agent-browser" = {
          enable = true;

          #Unit
          description = "GnuPG cryptographic agent and passphrase cache (access for web browsers)";
          documentation = [ "man:gpg-agent(1)" ];

          #Socket
          socketConfig = {
            ListenStream = "%t/gnupg/S.gpg-agent.browser";
            FileDescriptorName = "browser";
            Service = "gpg-agent.service";
            SocketMode = "0600";
            DirectoryMode = "0700";
          };

          #Install
          wantedBy = [ "sockets.target" ];
        };

        "gpg-agent-extra" = {
          enable = true;

          #Unit
          description = "GnuPG cryptographic agent and passphrase cache (restricted)";
          documentation = [ "man:gpg-agent(1)" ];

          #Socket
          socketConfig = {
            ListenStream = "%t/gnupg/S.gpg-agent.extra";
            FileDescriptorName = "extra";
            Service = "gpg-agent.service";
            SocketMode = "0600";
            DirectoryMode = "0700";
          };

          #Install
          wantedBy = [ "sockets.target" ];
        };
      };
    };
  };
}
