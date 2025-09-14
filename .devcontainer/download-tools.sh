#!/usr/bin/env bash

set -euxo pipefail

# Detect architecture
ARCH=$(uname -m)
case ${ARCH} in
    x86_64)
        ARCH_SUFFIX="amd64"
        ;;
    aarch64)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

# Cool tools
curl -sL "https://github.com/stern/stern/releases/download/v1.31.0/stern_1.31.0_linux_${ARCH_SUFFIX}.tar.gz" | sudo tar xvz -C /usr/local/bin/ stern
curl -sL "https://github.com/oras-project/oras/releases/download/v1.2.0/oras_1.2.0_linux_${ARCH_SUFFIX}.tar.gz" | sudo tar xvz -C /usr/local/bin/ oras
