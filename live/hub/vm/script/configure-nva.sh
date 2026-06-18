#!/usr/bin/env bash
set -euo pipefail

echo "net.ipv4.ip_forward=1" \
  > /etc/sysctl.d/99-nva-forwarding.conf

sysctl --system

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y iptables-persistent netfilter-persistent

OUT_IF="$(ip route show default | awk '/default/ {print $5; exit}')"

if ! iptables -t nat -C POSTROUTING \
  -o "${OUT_IF}" \
  -j MASQUERADE 2>/dev/null; then

  iptables -t nat -A POSTROUTING \
    -o "${OUT_IF}" \
    -j MASQUERADE
fi

netfilter-persistent save