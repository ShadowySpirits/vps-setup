#!/usr/bin/env bash
VERSION=1.13.5
OS=linux
ARCH=amd64

set -euo pipefail
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
sudo tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" | sudo tee --append /etc/profile
export PATH=$PATH:/usr/local/go/bin
go version