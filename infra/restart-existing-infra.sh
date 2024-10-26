#!/usr/bin/env bash

set -euo pipefail

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cluster_name=infra-1

jq_query=".valid | map(select(.Name == \"$cluster_name\")) | length"
existing_clusters=$(minikube profile list -l -o json | jq "$jq_query")

if [ "$existing_clusters" -ne "0" ]; then
  minikube start -p $cluster_name --auto-update-drivers=false
else
  echo "Cluster $cluster_name doesn't exist. Create it by running \"$script_dir/bootstrap-infra.sh\""
fi
