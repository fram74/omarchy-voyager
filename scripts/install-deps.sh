#!/usr/bin/env bash
# Install Zapp (+ optional dfu-util) so Voyager layouts can be flashed.
# Same as: voyager-layout install-deps --with-dfu
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/bin/voyager-layout" install-deps --with-dfu "$@"
