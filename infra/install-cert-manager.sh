#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Cert-manager
# https://artifacthub.io/packages/helm/cert-manager/cert-manager
CERT_MANAGER_VERSION="v1.16.1"
echo "Installing cert-manager $CERT_MANAGER_VERSION in cluster ${CLUSTER_NAME:?}..."
kubectl --context $CLUSTER_NAME apply \
  -f https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_VERSION/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io --force-update
helm --kube-context $CLUSTER_NAME install cert-manager -n cert-manager \
  --create-namespace --version $CERT_MANAGER_VERSION jetstack/cert-manager

# CA ClusterIssuer
kubectl --context $CLUSTER_NAME -n cert-manager create secret tls dev-ca \
  --cert=$SCRIPT_DIR/../.devcontainer/ca-cert.pem  --key=$SCRIPT_DIR/../.devcontainer/ca-key.pem
cat <<EOF | kubectl --context $CLUSTER_NAME apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: dev-ca
spec:
  ca:
    secretName: dev-ca
EOF