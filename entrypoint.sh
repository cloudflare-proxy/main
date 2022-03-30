#!/bin/bash

set -euo pipefail

DEFAULT_GATEWAY=$(ip route show default | awk '/default/ {print $3}')

echo "Adding static routes for DNS servers"
(
  set -x;
  ip route add 8.8.8.8 via ${DEFAULT_GATEWAY};
  ip route add 8.8.4.4 via ${DEFAULT_GATEWAY};
  ip route add 1.1.1.1 via ${DEFAULT_GATEWAY}
)

echo "Configuring wireguard interface"
(
  set -x;
  ip link add wgcf type wireguard;
  ip addr add 172.16.0.2/32 dev wgcf
  ip link set wgcf up
  wg setconf wgcf /run/secrets/wgcf.conf
  ip route add 172.16.0.1/32 dev wgcf
)

echo "Replacing default gateway"
(
  set -x;
  ip route add 162.159.192.1/32 via ${DEFAULT_GATEWAY};
  ip route replace default via 172.16.0.1
)

wg

echo "Starting socks4 proxy"
cat > /etc/danted.conf <<EOCONF
logoutput: stderr
internal: 0.0.0.0 port = 1080
external: eth0
socksmethod: username none

user.privileged: root
user.unprivileged: nobody
user.libwrap: nobody

client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: error connect disconnect
}

socks pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: error connect disconnect
}

EOCONF

exec $@

