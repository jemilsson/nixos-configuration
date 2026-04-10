#!/bin/sh
# NetworkManager dispatcher script.
# Prefer IPv4 when only tunneled IPv6 (wg2) is available,
# prefer IPv6 when native IPv6 is present.

rm -f /etc/gai.conf

if @iproute2@/bin/ip -6 route show default | @gnugrep@/bin/grep -qv 'dev wg2'; then
  cat > /etc/gai.conf <<EOF
# Native IPv6 available, prefer IPv6 (default)
EOF
else
  cat > /etc/gai.conf <<EOF
precedence ::ffff:0:0/96 100
precedence ::/0          40
precedence ::1/128       50
precedence 2002::/16     30
precedence ::/96         20
EOF
fi
