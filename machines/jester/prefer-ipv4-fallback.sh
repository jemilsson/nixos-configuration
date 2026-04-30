#!/bin/sh
# NetworkManager dispatcher script.
# Prefer IPv4 unless we have *working* native IPv6 internet connectivity.
# Checking for a default IPv6 route is not enough: many networks advertise
# RAs (so a fe80::1 default appears) but don't actually route v6 traffic,
# and ULA/wg2 tunnel addresses don't count as real v6 either. So probe a
# known global v6 host with a short timeout.

rm -f /etc/gai.conf

if ip -6 route get 2606:4700:4700::1111 2>/dev/null | grep -qv 'dev wg2' \
   && @iputils@/bin/ping -6 -c1 -W2 -q 2606:4700:4700::1111 >/dev/null 2>&1; then
  cat > /etc/gai.conf <<EOF
# Native IPv6 reachable, prefer IPv6 (default precedence)
EOF
else
  # Native v6 is unreachable (no RA, or RA present but upstream blackholes
  # traffic, e.g. AIS Fibre admin-prohibited). Drop any RA-installed default
  # so the wg2 ::/0 fallback (metric 50000) wins for v6-only destinations.
  # The next RA from the upstream router will re-add it; the dispatcher
  # re-runs on NM connectivity-change and re-evaluates.
  ip -6 route show default 2>/dev/null \
    | awk '/proto ra/ {sub(/ pref [a-z]+$/, ""); print}' \
    | while read -r r; do ip -6 route del $r 2>/dev/null || true; done
  cat > /etc/gai.conf <<EOF
# No working native IPv6, prefer IPv4-mapped addresses
precedence ::ffff:0:0/96 100
precedence ::/0          40
precedence ::1/128       50
precedence 2002::/16     30
precedence ::/96         20
EOF
fi
