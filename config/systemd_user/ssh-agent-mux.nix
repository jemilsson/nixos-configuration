{ config, lib, pkgs, ... }:

# Sets up ssh-agent-mux to multiplex GPG agent (for GPG authentication keys)
# and a standalone OpenSSH ssh-agent (for FIDO/U2F keys) into a single socket.
#
# Requires programs.gnupg.agent.enableSSHSupport = false (we manage SSH_AUTH_SOCK ourselves).
# Requires services.gnome.gcr-ssh-agent.enable = false (we replace it).

{
  # Tell gpg-agent to serve SSH keys on its socket, even though enableSSHSupport is false.
  # enableSSHSupport controls both the socket AND the env var; we only want the socket.
  programs.gnupg.agent.settings = {
    enable-ssh-support = "";
  };

  # Create the gpg-agent-ssh systemd socket (normally done by enableSSHSupport)
  systemd.user.sockets.gpg-agent-ssh = {
    unitConfig = {
      Description = "GnuPG cryptographic agent (ssh-agent emulation)";
      Documentation = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
    };
    socketConfig = {
      ListenStream = "%t/gnupg/S.gpg-agent.ssh";
      FileDescriptorName = "ssh";
      Service = "gpg-agent.service";
      SocketMode = "0600";
      DirectoryMode = "0700";
    };
    wantedBy = [ "sockets.target" ];
  };

  # Standalone OpenSSH ssh-agent for FIDO keys
  systemd.user.services.ssh-agent = {
    unitConfig = {
      Description = "OpenSSH Agent (for FIDO/U2F keys)";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent.sock";
    };
    wantedBy = [ "default.target" ];
  };

  # Auto-load FIDO key into ssh-agent on login. After= only orders unit
  # startup; ssh-agent's socket may not exist yet when ssh-add runs, so
  # poll until it appears before attempting to connect.
  systemd.user.services.ssh-add-fido = {
    unitConfig = {
      Description = "Load FIDO SSH key into agent";
      After = [ "ssh-agent.service" ];
      Requires = [ "ssh-agent.service" ];
    };
    serviceConfig = {
      Type = "oneshot";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent.sock";
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 50); do [ -S %t/ssh-agent.sock ] && exit 0; sleep 0.1; done; exit 1'";
      ExecStart = "${pkgs.openssh}/bin/ssh-add /home/jonas/.ssh/id_ecdsa_sk";
    };
    wantedBy = [ "default.target" ];
  };

  # ssh-agent-mux combines both agents behind a single socket
  systemd.user.services.ssh-agent-mux = {
    unitConfig = {
      Description = "SSH Agent Multiplexer";
      After = [ "gpg-agent-ssh.socket" "ssh-agent.service" ];
      Requires = [ "gpg-agent-ssh.socket" ];
      Wants = [ "ssh-agent.service" ];
    };
    serviceConfig = {
      Type = "simple";
      UMask = "0077";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %t/ssh-agent-mux";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.ssh-agent-mux}/bin/ssh-agent-mux"
        "--listen %t/ssh-agent-mux/ssh-agent-mux.sock"
        "%t/ssh-agent.sock"
        "%t/gnupg/S.gpg-agent.ssh"
      ];
      Restart = "on-failure";
      RestartSec = 5;
    };
    wantedBy = [ "default.target" ];
  };

  # Point SSH_AUTH_SOCK at the mux socket
  environment.extraInit = lib.mkAfter ''
    export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent-mux/ssh-agent-mux.sock"
  '';

  # Update TTY for gpg-agent when SSH connects (same as enableSSHSupport does)
  programs.ssh.extraConfig = ''
    Match host * exec "${pkgs.runtimeShell} -c '${config.programs.gnupg.package}/bin/gpg-connect-agent --quiet updatestartuptty /bye >/dev/null 2>&1'"
  '';
}
