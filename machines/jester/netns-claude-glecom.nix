{ config, lib, pkgs, ... }:
let
  ip = "${pkgs.iproute2}/bin/ip";

  # Setuid helper: enters the claude-glecom netns and drops back to calling user
  nsenter-cg = pkgs.runCommandCC "nsenter-claude-glecom" { } ''
    mkdir -p $out/bin
    cat > main.c << 'EOF'
#define _GNU_SOURCE
#include <sched.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
  int fd = open("/var/run/netns/claude-glecom", O_RDONLY | O_CLOEXEC);
  if (fd < 0) { perror("open /var/run/netns/claude-glecom"); return 1; }
  if (setns(fd, CLONE_NEWNET) < 0) { perror("setns"); return 1; }
  close(fd);
  if (setgid(getgid()) < 0 || setuid(getuid()) < 0) { perror("drop privs"); return 1; }
  if (argc < 2) {
    char *sh[] = {"/bin/sh", NULL};
    execv("/bin/sh", sh);
  } else {
    execvp(argv[1], argv + 1);
  }
  perror(argc < 2 ? "/bin/sh" : argv[1]);
  return 1;
}
EOF
    cc -o $out/bin/nsenter-claude-glecom main.c
  '';
in
{
  # Setuid wrapper so regular users can enter the namespace
  security.wrappers.nsenter-claude-glecom = {
    source = "${nsenter-cg}/bin/nsenter-claude-glecom";
    owner = "root";
    group = "root";
    setuid = true;
  };

  # claude-glecom wrapper: runs claude inside the namespace with its own config dir
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "claude-glecom" ''
      exec /run/wrappers/bin/nsenter-claude-glecom \
        env HOME="$HOME" CLAUDE_CONFIG_DIR="$HOME/.claude-glecom" \
        claude "$@"
    '')
  ];

  # wg2: move Claude Code CIDRs out of main table into table 200
  # so regular processes use the default route for those destinations
  networking.wireguard.interfaces.wg2.postSetup = lib.mkAfter ''
    ${ip} route del 160.79.104.0/23 dev wg2 2>/dev/null || true
    ${ip} -6 route del 2607:6bc0::/48 dev wg2 2>/dev/null || true
    ${ip} route add 160.79.104.0/23 dev wg2 table 200
    ${ip} -6 route add 2607:6bc0::/48 dev wg2 table 200
  '';
  networking.wireguard.interfaces.wg2.postShutdown = lib.mkAfter ''
    ${ip} route del 160.79.104.0/23 dev wg2 table 200 2>/dev/null || true
    ${ip} -6 route del 2607:6bc0::/48 dev wg2 table 200 2>/dev/null || true
  '';

  # Network namespace setup
  systemd.services.netns-claude-glecom = {
    description = "claude-glecom network namespace";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "wireguard-wg2.service" ];
    wants = [ "wireguard-wg2.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${ip} netns add claude-glecom

      # veth pair: veth-cg (host) <-> veth-cg-ns (namespace)
      ${ip} link add veth-cg type veth peer name veth-cg-ns
      ${ip} link set veth-cg-ns netns claude-glecom

      # Host side
      ${ip} addr add 10.200.200.1/30 dev veth-cg
      ${ip} addr add fd00:200::1/64 dev veth-cg
      ${ip} link set veth-cg up

      # Namespace side
      ${ip} -n claude-glecom addr add 10.200.200.2/30 dev veth-cg-ns
      ${ip} -n claude-glecom addr add fd00:200::2/64 dev veth-cg-ns
      ${ip} -n claude-glecom link set veth-cg-ns up
      ${ip} -n claude-glecom link set lo up

      # Routes inside namespace: Claude Code CIDRs and default via host
      ${ip} -n claude-glecom route add 160.79.104.0/23 via 10.200.200.1
      ${ip} -n claude-glecom -6 route add 2607:6bc0::/48 via fd00:200::1
      ${ip} -n claude-glecom route add default via 10.200.200.1
      ${ip} -n claude-glecom -6 route add default via fd00:200::1

      # Policy rule: traffic from veth-cg uses table 200 (routes to wg2)
      ${ip} rule add iif veth-cg lookup 200 priority 100
      ${ip} -6 rule add iif veth-cg lookup 200 priority 100
    '';
    preStop = ''
      ${ip} rule del iif veth-cg lookup 200 priority 100 2>/dev/null || true
      ${ip} -6 rule del iif veth-cg lookup 200 priority 100 2>/dev/null || true
      ${ip} link del veth-cg 2>/dev/null || true
      ${ip} netns del claude-glecom 2>/dev/null || true
    '';
  };

  # IP forwarding for namespace traffic
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # NAT: masquerade namespace traffic leaving via wg2
  networking.firewall.extraCommands = lib.mkAfter ''
    iptables  -t nat -A POSTROUTING -s 10.200.200.0/30 -j MASQUERADE
    ip6tables -t nat -A POSTROUTING -s fd00:200::/64   -j MASQUERADE
  '';
  networking.firewall.extraStopCommands = lib.mkAfter ''
    iptables  -t nat -D POSTROUTING -s 10.200.200.0/30 -j MASQUERADE 2>/dev/null || true
    ip6tables -t nat -D POSTROUTING -s fd00:200::/64   -j MASQUERADE 2>/dev/null || true
  '';
}
