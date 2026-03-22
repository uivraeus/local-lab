#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

SQUID_IMAGE="docker.io/ubuntu/squid:latest"
SQUID_CONTAINER_NAME="squid-host"

docker rm -f "${SQUID_CONTAINER_NAME}" >/dev/null 2>&1 || true
docker run -d \
  --name "${SQUID_CONTAINER_NAME}" \
  --restart unless-stopped \
  --network=host \
  --entrypoint /usr/sbin/squid \
  -v "${SCRIPT_DIR}/squid.conf:/etc/squid/squid.conf:ro" \
  "${SQUID_IMAGE}" \
  -N -f /etc/squid/squid.conf

cat <<'EOF'
Squid container started: squid-host

Use HTTP scheme for the proxy URL (even for HTTPS targets):
  export HTTPS_PROXY=http://127.0.0.1:3128
EOF
