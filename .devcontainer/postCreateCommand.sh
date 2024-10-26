#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
printf "\n\n\n### APPENDED by postCreateCommand ###\n\n" >> ~/.bashrc
cat ${SCRIPT_DIR}/bashrc_append >> ~/.bashrc

# Cool tools
curl -sL https://github.com/stern/stern/releases/download/v1.31.0/stern_1.31.0_linux_amd64.tar.gz | sudo tar xvz -C /usr/local/bin/ stern
curl -sL https://github.com/oras-project/oras/releases/download/v1.2.0/oras_1.2.0_linux_amd64.tar.gz | sudo tar xvz -C /usr/local/bin/ oras

# TODO: move to features
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  bat

$SCRIPT_DIR/install-dev-ca.sh

