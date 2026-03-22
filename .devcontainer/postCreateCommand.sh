#!/usr/bin/env bash

set -euxo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
printf "\n\n\n### APPENDED by postCreateCommand ###\n\n" >> ~/.bashrc
cat ${SCRIPT_DIR}/bashrc_append >> ~/.bashrc

$SCRIPT_DIR/download-tools.sh

# TODO: move to features
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  bat

"$SCRIPT_DIR/install-dev-ca.sh"


