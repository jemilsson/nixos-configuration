{ config, lib, pkgs, ... }:
let
  ip = "${pkgs.iproute2}/bin/ip";
  wifiIf = "wlp0s20f3";
in
{
  # portal netns: routes ONLY through the Wi-Fi interface, so a captive-portal
  # login page (RFC1918-addressed, behind the AP) is reachable even while wg2's
  # blanket routes for 10/8, 172.16/12, 192.168/16 and ::/0 black-hole those
  # same ranges into the tunnel on the main table (pcap-confirmed 2026-07-22:
  # every portal SYN encapsulated to the wg2 endpoint, zero replies). Mirrors
  # netns-claude-glecom.nix's veth + policy-routing pattern (table 200 there,
  # 201 here).
  systemd.services.portal-netns = {
    description = "portal network namespace (Wi-Fi-only route for captive-portal login)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${ip} netns list | ${pkgs.gnugrep}/bin/grep -q '^portal ' || ${ip} netns add portal

      ${ip} link show veth-pt-host >/dev/null 2>&1 || {
        ${ip} link add veth-pt-host type veth peer name veth-pt
        ${ip} link set veth-pt netns portal
      }

      ${ip} addr add 10.201.0.1/30 dev veth-pt-host 2>/dev/null || true
      ${ip} link set veth-pt-host up

      ${ip} -n portal addr add 10.201.0.2/30 dev veth-pt 2>/dev/null || true
      ${ip} -n portal link set veth-pt up
      ${ip} -n portal link set lo up
      ${ip} -n portal route replace default via 10.201.0.1

      # Policy routing: traffic leaving via veth-pt-host uses table 201
      # (re-synced to mirror wlp0s20f3's routes by the NM dispatcher below).
      ${ip} rule add iif veth-pt-host lookup 201 priority 110 2>/dev/null || true
      ${ip} -6 rule add iif veth-pt-host lookup 201 priority 110 2>/dev/null || true
    '';
    preStop = ''
      ${ip} rule del iif veth-pt-host lookup 201 priority 110 2>/dev/null || true
      ${ip} -6 rule del iif veth-pt-host lookup 201 priority 110 2>/dev/null || true
      ${ip} link del veth-pt-host 2>/dev/null || true
      ${ip} netns del portal 2>/dev/null || true
    '';
  };

  # net.ipv4.ip_forward is already enabled by netns-claude-glecom.nix; do not
  # redefine it here (duplicate boot.kernel.sysctl definitions of the same key
  # from two modules only merge cleanly when equal, and this repo already sets
  # it to 1 - re-declaring it adds risk for no benefit).

  # NAT + forwarding for the portal namespace's traffic out through Wi-Fi.
  # NixOS merges string-valued extraCommands definitions from multiple files
  # by concatenation, so this appends after configuration.nix's clatd rules.
  networking.firewall.extraCommands = lib.mkAfter ''
    iptables -t nat -A POSTROUTING -s 10.201.0.0/30 -o ${wifiIf} -j MASQUERADE
    iptables -I FORWARD -i veth-pt-host -o ${wifiIf} -j ACCEPT
    iptables -I FORWARD -i ${wifiIf} -o veth-pt-host -j ACCEPT
  '';
  networking.firewall.extraStopCommands = lib.mkAfter ''
    iptables -t nat -D POSTROUTING -s 10.201.0.0/30 -o ${wifiIf} -j MASQUERADE 2>/dev/null || true
    iptables -D FORWARD -i veth-pt-host -o ${wifiIf} -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i ${wifiIf} -o veth-pt-host -j ACCEPT 2>/dev/null || true
  '';

  # New list-valued dispatcherScripts definition (NixOS merges lists across
  # files); do not edit configuration.nix's existing definition in place.
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "portal-netns-sync" ''
        set -u
        iface="''${1:-}"
        action="''${2:-}"
        [ "$iface" = "${wifiIf}" ] || exit 0
        case "$action" in
          up|dhcp4-change|connectivity-change) ;;
          *) exit 0 ;;
        esac

        # Re-sync table 201 to mirror wlp0s20f3's current routes.
        ${ip} route flush table 201 || true
        # Skip multipath continuation lines (leading whitespace) and strip
        # status flags (linkdown/dead) that `ip route replace` rejects as input.
        ${ip} route show dev ${wifiIf} \
          | ${pkgs.gnugrep}/bin/grep -v '^[[:space:]]' \
          | ${pkgs.gnused}/bin/sed 's/ \(linkdown\|dead\)\b//g' \
          | while IFS= read -r line; do
          [ -n "$line" ] || continue
          ${ip} route replace $line dev ${wifiIf} table 201
        done

        # Point the netns' resolver at the Wi-Fi network's own DNS servers.
        servers="''${IP4_NAMESERVERS:-}"
        [ -n "$servers" ] || servers="''${DHCP4_DOMAIN_NAME_SERVERS:-}"
        if [ -n "$servers" ]; then
          ${pkgs.coreutils}/bin/mkdir -p /etc/netns/portal
          {
            for s in $servers; do echo "nameserver $s"; done
          } > /etc/netns/portal/resolv.conf
        fi

        if [ "$action" = "connectivity-change" ] && [ "''${CONNECTIVITY_STATE:-}" = "PORTAL" ]; then
          systemctl start portal-browser.service
        fi
      '';
    }
  ];

  # portal-browser: isolated Chromium run inside the portal netns for
  # captive-portal login. Hardcoded uid 1000 / wayland-1 / :0 is a
  # single-user-laptop shortcut (jester has exactly one interactive user),
  # not a general multi-user pattern.
  systemd.services.portal-browser = {
    description = "Captive-portal login browser (portal netns)";
    requires = [ "portal-netns.service" ];
    after = [ "portal-netns.service" ];
    serviceConfig = {
      Type = "simple";
      NetworkNamespacePath = "/run/netns/portal";
      # NetworkNamespacePath does NOT apply the /etc/netns/portal/resolv.conf
      # convention (that is an `ip netns exec` feature), so bind-mount it over
      # /etc/resolv.conf in a private mount ns. "-" = skip if not yet written
      # by the dispatcher (falls back to host DNS).
      PrivateMounts = true;
      BindReadOnlyPaths = [ "-/etc/netns/portal/resolv.conf:/etc/resolv.conf" ];
      User = "jonas";
      Environment = [
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DISPLAY=:0"
      ];
      # Literal home path: %h in system units resolves to /root even with
      # User= set, so it cannot be used here.
      ExecStart = "${pkgs.chromium}/bin/chromium --user-data-dir=/home/jonas/.local/share/chromium-portal --no-first-run --new-window --incognito --no-default-browser-check http://neverssl.com";
    };
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "portal-browser" ''
      exec systemctl start portal-browser.service
    '')
  ];
}
