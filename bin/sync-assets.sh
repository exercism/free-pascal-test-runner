#!/usr/bin/env bash

declare bindir
bindir="$(realpath "$(dirname "$0")")"
cd "$bindir" || exit 1

for dest in ../tests/*/; do
    echo "Syncing ${dest%/}..."
    rsync \
        --recursive \
        --links \
        --perms \
        --group \
        --checksum \
        --out-format='%i %n' \
        ../assets/ "$dest"
done
