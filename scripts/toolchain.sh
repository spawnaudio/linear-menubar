#!/bin/zsh
# Respect an explicit toolchain choice; otherwise prefer a complete Xcode installation.
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
    if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
        export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    elif [[ -d /Applications/Xcode-beta.app/Contents/Developer ]]; then
        export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer
    fi
fi
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
