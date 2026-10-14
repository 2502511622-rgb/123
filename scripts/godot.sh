#!/usr/bin/env sh
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
export XDG_DATA_HOME=/workspace/.runtime/data
export XDG_CONFIG_HOME=/workspace/.runtime/config
export XDG_CACHE_HOME=/workspace/.runtime/cache
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec godot --path "$project_root/godot" "$@"
