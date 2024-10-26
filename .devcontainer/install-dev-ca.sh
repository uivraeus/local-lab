#!/usr/bin/env bash


set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Setting up local dev CA cert..."

if [ ! -f "$SCRIPT_DIR/ca-key.pem" ]; then
  echo "No existing CA cert detected, generating a new one..."
  openssl genrsa -out "$SCRIPT_DIR/ca-key.pem" 2048
  openssl req -x509 -new -nodes -key "$SCRIPT_DIR/ca-key.pem" -sha256 -days 3650 -out "$SCRIPT_DIR/ca-cert.pem" -outform PEM -subj '/CN=MyDev Root CA/C=SE/ST=VGR/L=GBG/O=MyDev'
fi

# Trust dev CA in current distro
sudo mkdir -p /usr/local/share/ca-certificates/my-custom-ca
sudo cp "$SCRIPT_DIR/ca-cert.pem" /usr/local/share/ca-certificates/my-custom-ca/local-dev-ca.crt
sudo update-ca-certificates

# Trust dev CA in minikube
mkdir -p ~/.minikube/certs
cp "$SCRIPT_DIR/ca-cert.pem" ~/.minikube/certs/local-dev-ca.pem
