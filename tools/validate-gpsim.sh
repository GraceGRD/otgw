#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}/chmodule"
if [[ ! -f configure ]]; then
    sed -i 's/\r$//' ./autogen.sh
    sh ./autogen.sh
fi
if [[ ! -f Makefile ]]; then
    ./configure
fi
make -j"$(nproc)"

cd "${ROOT_DIR}"
make test "$@"
