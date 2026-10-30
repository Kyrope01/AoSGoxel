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

if [ ! -f "$dest/CMakeLists.txt" ]; then
    mkdir -p "$root/third_party"
    echo "Cloning SDL2 ($SDL_TAG) into third_party/SDL ..."
    git clone --depth 1 --branch "$SDL_TAG" https://github.com/libsdl-org/SDL "$dest"
else
    echo "SDL2 already present in third_party/SDL"
fi

# SDL ships a Gradle project (android-project/) with its own gradle-wrapper.jar.
# gradle/actions/setup-gradle validates every wrapper jar it finds in the
# workspace and fails on unknown ones, so drop them: we only need SDL's Java
# glue (org.libsdl.app.SDLActivity), which is compiled from source by AGP.
rm -rf "$dest/android-project/gradle"
find "$dest" -name 'gradle-wrapper.jar' -delete 2>/dev/null || true

echo "Done."
