#!/usr/bin/env bash

## Prerequisites:
# Existing docker network, e.g.
#   docker network create clusters-common --subnet=192.168.128.0/24 --gateway=192.168.128.1
#
# Usage (example):
#   CLUSTER_NAME=kube-1 CLUSTER_IP=192.168.128.11 ./create-cluster.sh

set -euo pipefail
cluster_name=${CLUSTER_NAME:?}
exit_code_if_exists=${EXISTS_EXIT_CODE:-'0'}

jq_query=".valid | map(select(.Name == \"$cluster_name\")) | length"
existing_clusters=$(minikube profile list -l -o json | jq "$jq_query")

if [ "$existing_clusters" -ne "0" ]; then
  echo "Cluster \"$cluster_name\" already exists"
  exit $exit_code_if_exists
fi

echo "Creating cluster \"$cluster_name\"..."

cluster_version=${CLUSTER_VERSION:-''}
cluster_network=${CLUSTER_NETWORK:-'clusters-common'}
cluster_ip=${CLUSTER_IP:?}

set -euxo pipefail

minikube start -p $cluster_name --kubernetes-version=$cluster_version --network=$cluster_network --static-ip=$cluster_ip
minikube -p $cluster_name addons enable metrics-server
minikube -p $cluster_name addons enable ingress
#minikube -p $cluster_name addons enable volumesnapshots
#minikube -p $cluster_name addons enable csi-hostpath-driver
#minikube -p $cluster_name addons disable storage-provisioner
#minikube -p $cluster_name addons disable default-storageclass
#kubectl --context $cluster_name  patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
#kubectl --context $cluster_name get volumesnapshotclasses