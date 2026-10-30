#!/usr/bin/env bash
# Fetch the SDL2 sources used by the Android build.
#
# SDL2 is not vendored in this repository (it is a fairly large git tree), so
# both the CI and local builds clone it into third_party/SDL, which is
# git-ignored.  Run this once before building the APK.
set -euo pipefail

SDL_TAG="${SDL_TAG:-release-2.32.8}"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
dest="$root/third_party/SDL"

if [ -f "$dest/CMakeLists.txt" ]; then
    echo "SDL2 already present in third_party/SDL"
    exit 0
fi

mkdir -p "$root/third_party"
echo "Cloning SDL2 ($SDL_TAG) into third_party/SDL ..."
git clone --depth 1 --branch "$SDL_TAG" https://github.com/libsdl-org/SDL "$dest"
echo "Done."
