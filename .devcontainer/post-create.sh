#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}/chmodule"

if [[ ! -f configure ]]; then
    sed -i 's/\r$//' ./autogen.sh
    sh ./autogen.sh
fi

# Refresh paths and rebuild when reopening with a new container toolchain.
./configure
make clean
make -j"$(nproc)"
