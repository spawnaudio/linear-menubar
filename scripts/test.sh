#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
source scripts/toolchain.sh
xcrun swift test --disable-xctest --scratch-path .build/xcode --cache-path .build/cache
