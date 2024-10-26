#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if ! docker network ls | grep clusters-common > /dev/null ; then
  echo 'Creating Docker network "clusters-common"...'
  docker network create clusters-common --subnet=192.168.128.0/24 --gateway=192.168.128.1
fi

export CLUSTER_NAME=infra-1
CLUSTER_IP=192.168.128.11 EXISTS_EXIT_CODE=1 $SCRIPT_DIR/create-cluster.sh

$SCRIPT_DIR/install-cert-manager.sh

echo "Installing image registry..."
helm repo add twuni https://helm.twun.io --force-update
helm --kube-context $CLUSTER_NAME  -n registry install registry --create-namespace \
  -f $SCRIPT_DIR/registry-values.yaml twuni/docker-registry
  