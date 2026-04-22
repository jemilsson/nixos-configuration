{ config, lib, pkgs, ... }:

# fafnir: unified TPM-backed daemon. Replaces ssh-agent-mux + linux-id +
# (eventually) the standalone openssh ssh-agent we used for FIDO keys.
#
# fafnir is itself the SSH agent: it advertises a native ECDSA P-256
# identity AND a sk-ecdsa-sha2-nistp256 identity backed by the same TPM
# key. Upstream gpg-agent is forwarded through fafnir so GPG-backed SSH
# auth keys still work behind the same SSH_AUTH_SOCK.
#
# Requires programs.gnupg.agent.enableSSHSupport = false (we manage
# SSH_AUTH_SOCK ourselves).
#
# # First-time provisioning (manual, runs once per user)
#
#   $ fafnir provision               # passphrase-encrypted, default
#   $ fafnir provision --no-passphrase   # plaintext seed, auto-unlocks
#
# Both write `$XDG_CONFIG_HOME/fafnir/master.seed[.enc]` and print
# the 24-word BIP39 mnemonic — store that offline.
# Recovery requires BOTH the mnemonic AND this TPM chip: use
# `fafnir import-seed` on the same machine after a disk replacement.
#
# # Upgrading from a pre-seed-derived install
#
#   $ fafnir migrate-evict
#
# Idempotent one-shot that walks the TPM and frees the legacy
# `0x8101_FAF{0,1,2}` persistent slots (no-op if nothing there).
# After it runs, the SSH/age/FIDO identities advertised by fafnir
# will have changed (they're now derived from the master seed via
# CreatePrimary instead of being persisted under fixed handles), so
# you'll need to re-enroll the new public keys with GitHub etc.
#
# # Day-to-day (after upgrade)
#
#   $ fafnir status      # locked|unlocked
#   $ fafnir unlock      # GUI passphrase modal, sends to daemon
#   $ fafnir lock        # flush handles, drop master seed from RAM
#
# Auto-locks after 8 h idle (auto_lock_idle_secs).

let
  fafnirConfig = pkgs.writeText "fafnir.toml" ''
    listen_path = "$XDG_RUNTIME_DIR/fafnir/agent.sock"
    age_socket  = "$XDG_RUNTIME_DIR/fafnir/age.sock"
    approval    = "fprintd"
    powerled_path = "/sys/class/leds/tpacpi::power"

    # Native TPM RSA-2048 SSH identity (in addition to the ECDSA + SK ones).
    enable_rsa = true
    rsa_bits   = 2048

    # Forward gpg-agent's SSH socket through fafnir; no extra fafnir-side
    # gate (GPG already prompts via its own pinentry).
    agent_sock_paths = [ "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh" ]

    auto_lock_idle_secs = 28800
  '';
in
{
  # gpg-agent ssh socket — kept so fafnir can forward GPG-auth keys.
  programs.gnupg.agent.settings = {
    enable-ssh-support = "";
  };
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

  systemd.user.services.fafnir = {
    unitConfig = {
      Description = "fafnir TPM-backed crypto daemon (SSH agent + FIDO + age)";
      After = [ "gpg-agent-ssh.socket" "graphical-session.target" ];
      Wants = [ "gpg-agent-ssh.socket" ];
      PartOf = [ "graphical-session.target" ];
    };
    path = [ pkgs.libnotify pkgs.dbus pkgs.fafnir ];
    serviceConfig = {
      Type = "simple";
      UMask = "0077";
      PassEnvironment = [ "WAYLAND_DISPLAY" "DISPLAY" "XDG_RUNTIME_DIR" "DBUS_SESSION_BUS_ADDRESS" "XDG_SESSION_TYPE" ];
      # mkdir runtime dir + the seed dir under $XDG_CONFIG_HOME so the
      # daemon can find ~/.config/fafnir/master.seed[.enc]. Provisioning
      # the master seed is now a one-shot user action via
      # `fafnir provision` (writes the seed file + prints the BIP39
      # mnemonic) — the service no longer auto-provisions on boot.
      #
      # On startup the daemon reads the seed file:
      #   - plaintext seed   → unlock immediately
      #   - encrypted seed   → start LOCKED, wait for `fafnir unlock`
      #                        on the control socket
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p %t/fafnir"
        "${pkgs.coreutils}/bin/mkdir -p %h/.config/fafnir"
      ];
      ExecStart = "${pkgs.fafnir}/bin/fafnir --config ${fafnirConfig} run";
      Restart = "on-failure";
      RestartSec = 5;
    };
    wantedBy = [ "graphical-session.target" ];
  };

  # Point SSH_AUTH_SOCK at fafnir's listen socket.
  environment.extraInit = lib.mkAfter ''
    export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/fafnir/agent.sock"
  '';

  # Update TTY for gpg-agent when SSH connects (same as enableSSHSupport).
  programs.ssh.extraConfig = ''
    Match host * exec "${pkgs.runtimeShell} -c '${config.programs.gnupg.package}/bin/gpg-connect-agent --quiet updatestartuptty /bye >/dev/null 2>&1'"
  '';

  # /dev/uhid access for fafnir's CTAPHID device emulation.
  services.udev.extraRules = lib.mkAfter ''
    KERNEL=="uhid", SUBSYSTEM=="misc", GROUP="tss", MODE="0660"
  '';
}
