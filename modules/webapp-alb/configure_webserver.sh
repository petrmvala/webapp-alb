#!/usr/bin/env bash
set -euo pipefail

node_ip=$(curl 169.254.169.254/latest/meta-data/local-ipv4)

echo "Hi, there! I'm $${node_ip}" > index.html
nohup busybox httpd -f -p "${port}" &
