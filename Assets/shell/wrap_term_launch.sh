#!/usr/bin/env sh

## Stolen https://github.com/caelestia-dots/shell/blob/main/assets/wrap_term_launch.sh

cat ~/.local/state/shell/sequences.txt 2>/dev/null

exec "$@"
