#!/usr/bin/env sh
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
runtime_root=${MOSSFIELD_RUNTIME_DIR:-"$(dirname -- "$project_root")/.runtime"}
export XDG_DATA_HOME="$runtime_root/data"
export XDG_CONFIG_HOME="$runtime_root/config"
export XDG_CACHE_HOME="$runtime_root/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec godot --path "$project_root/godot" "$@"
