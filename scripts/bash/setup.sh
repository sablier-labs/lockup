#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT_ENV="${PROJECT_ROOT}/.env"
DIRECTORIES=("flow" "lockup" "airdrops" "utils")

[ ! -f "$ROOT_ENV" ] && touch "$ROOT_ENV"

create_symlink() {
    local dir=$1 target_dir="${PROJECT_ROOT}/${dir}" target_env="${target_dir}/.env"

    [ ! -d "$target_dir" ] && return 1

    if [ -L "$target_env" ]; then
        [ "$(readlink "$target_env")" = "../.env" ] && return 0
        rm "$target_env"
    elif [ -f "$target_env" ]; then
        mv "$target_env" "${target_env}.backup"
    fi

    (cd "$target_dir" && ln -sf "../.env" ".env")
}

for dir in "${DIRECTORIES[@]}"; do create_symlink "$dir"; done
