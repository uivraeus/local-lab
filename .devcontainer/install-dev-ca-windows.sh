#!/usr/bin/env bash

set -euo pipefail

# Installs the dev CA into Windows Current User -> Trusted Root store via certutil.exe.
# This script is intended to run inside WSL and does not require elevation.
#
# Usage:
#   ./install-dev-ca-windows.sh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ ${1:-} == "" ]]; then
  CERT_PATH="$SCRIPT_DIR/ca-cert.pem"
else
  CERT_PATH="$1"
fi

if [[ ! -f "$CERT_PATH" ]]; then
  echo "ERROR: Certificate file not found: $CERT_PATH"
  echo "Usage: $(basename "$0") [path-to-ca-cert.pem]"
  exit 1
fi

if ! command -v certutil.exe >/dev/null 2>&1; then
  echo "ERROR: certutil.exe is not available from this WSL environment."
  exit 1
fi

if ! command -v wslpath >/dev/null 2>&1; then
  echo "ERROR: wslpath is not available from this WSL environment."
  exit 1
fi

CERT_CN=$(openssl x509 -in "$CERT_PATH" -noout -subject -nameopt RFC2253 | sed -n 's/^subject=.*CN=\([^,]*\).*$/\1/p')
if [[ -z "$CERT_CN" ]]; then
  echo "ERROR: Could not extract CN from certificate subject."
  exit 1
fi

if certutil.exe -user -store Root | tr -d '\r' | grep -qi "CN=$CERT_CN"; then
  echo "A certificate with CN '$CERT_CN' is already registered in Current User > Trusted Root."
  read -r -p "Remove existing certificate(s) and continue? [y/N]: " REMOVE_OLD
  if [[ ! "$REMOVE_OLD" =~ ^[Yy]$ ]]; then
    echo "Aborted. Existing certificate was not removed."
    exit 2
  fi

  echo "Removing existing certificate(s) with CN '$CERT_CN'..."
  certutil.exe -user -delstore Root "$CERT_CN" >/dev/null || true

  if certutil.exe -user -store Root | tr -d '\r' | grep -qi "CN=$CERT_CN"; then
    echo "ERROR: Failed to remove all existing certificates with CN '$CERT_CN'."
    echo "Run 'certutil.exe -user -store Root' and remove them manually, then rerun this script."
    exit 3
  fi
fi

CERT_PATH_WIN=$(wslpath -m "$CERT_PATH")

echo "Importing dev CA into Windows Current User Trusted Root store..."
certutil.exe -user -addstore "Root" "$CERT_PATH_WIN"

echo
echo "Success. Imported '$CERT_CN' into Current User > Trusted Root Certification Authorities."
echo "Verify with: certutil.exe -user -store Root"
