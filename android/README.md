# AoS Goxel on Android

This directory contains a **community Android port** of this goxel fork: a
Gradle project that builds an installable APK.

> The original goxel Android app on Google Play is **not** built from the
> public goxel repository — the store build uses a closed platform layer. The
> public sources only contain the editor core, plus a few mobile hooks
> (`GOXEL_MOBILE`, the OpenGL ES 2.0 renderer, the multi-touch gesture code and
> the `sys_show_keyboard` / `sys_save_to_photos` callbacks). This directory adds
> the missing platform layer so an APK can be built from source.

## How it works

| Piece | File |
| --- | --- |
| Platform layer (window, main loop, touch, text input) | `src/main_sdl.c` |
| Native build | `CMakeLists.txt` (repo root), `GOXEL_SDL` define |
| Android project | `android/app/build.gradle`, `AndroidManifest.xml`, `GoxelActivity.java` |
| CI | `.github/android-workflow.yml` (copy to `.github/workflows/android.yml`) |

The renderer is built with `GLES2=1`, so it uses the OpenGL ES 2.0 path that
already exists in `src/utils/gl.c`, `src/render.c` and the GLSL shaders
(`#ifdef GL_ES` blocks). The windowing/input layer is SDL2, because it already
handles EGL, the software keyboard/IME, the activity lifecycle and multi-touch.
`src/main.c` (GLFW) is excluded from the Android build; the desktop SCons build
still compiles `src/main_sdl.c` to nothing (`#ifdef GOXEL_SDL`), so nothing
changes for Windows/macOS/Linux.

## Build

Requirements: JDK 17, Android SDK (platform 34 + build-tools 34.0.0),
NDK `27.0.12077973`, CMake `3.22.1` and Gradle 8.7.

```bash
# 1. Get the SDL2 sources (not vendored in this repo, git-ignored)
./android/fetch-sdl.sh

# 2. Build the APK
cd android
gradle assembleDebug        # or: gradle assembleRelease

# 3. Install
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Or let GitHub Actions do it: the workflow is stored as
`.github/android-workflow.yml`. **Enable it once** by creating
`.github/workflows/android.yml` with the same content (GitHub web UI: *Add
file → Create new file*, paste, commit). It then builds the APK on every push
and uploads it as the `aosgoxel-apk` artifact, and attaches it to the release
when a `v*` tag is pushed.

The APK is built for `arm64-v8a` only. Add `armeabi-v7a` to `abiFilters` in
`android/app/build.gradle` for older devices.

The release build is signed with the local debug key so that it can be
installed directly. Replace the signing config with your own key for anything
you publish.

## Touch controls

The core already speaks touch: `inputs_t` has four touch slots and
`src/gesture.c` implements drag/click/pinch gestures, so the platform layer only
maps the fingers onto the existing mouse gestures:

| Gesture | Action |
| --- | --- |
| 1 finger drag | draw / edit with the current tool (left mouse button) |
| 2 fingers | orbit (drag) + zoom (pinch) |
| 3 fingers | pan |
| mouse / stylus | same as the desktop build (left = edit, middle = orbit, right = pan) |
| tap on a widget | click in the UI |
| back button | `Escape` (closes popups) |

Notes:

* Only touch 0 is forwarded to ImGui, which is what the desktop code does with
  the mouse; the UI therefore behaves like the desktop UI with one finger.
* Two and three finger gestures are synthesized by `update_touches()` in
  `src/main_sdl.c`, because the core binds orbit/pan/zoom to the mouse buttons.
* When the finger count changes, one frame with everything released is emitted
  so a half-finished stroke is properly closed instead of being left pressed.

## Files on the device

There is **no native file picker** in this build yet. The app works inside its
own external directory, which is reachable from a computer over USB/MTP and
needs no permission:

```
/storage/emulated/0/Android/data/com.aosgoxel/files/goxel/
├── *.gox            models you put there (they show up in File > Recent)
└── exports/         everything the app saves or exports
```

* **Open**: copy a `.gox` file into the folder above, then use the
  *File ▸ Recent* menu — the list is rebuilt at startup, newest first, and the
  most recent model is opened automatically when the app starts.
* **Save / export**: no dialog, the file is written to `goxel/exports/` with the
  name of the format. Rename/move it from a computer, or use a file manager.

Adding a real `ACTION_OPEN_DOCUMENT` / `ACTION_CREATE_DOCUMENT` picker is the
natural next step; it needs a few lines of `onActivityResult` in
`GoxelActivity.java` plus a JNI callback (see the comment in that file).

## Known limitations

* Tested on nothing yet — this is a first cut. Expect to iterate on the DRM
  drivers/build config of your device, and please report runtime logs
  (`adb logcat`) if something fails.
* The UI is laid out for a mouse: panels are sized in UI points scaled by the
  screen DPI (`dpi / 160`, override with the `GOXEL_SCALE` environment
  variable), but small phone screens will still feel cramped in a few dialogs.
* The path tracer (*Render* panel, yocto) is CPU heavy and very slow on a
  phone; the voxel editor itself is fine.
* No pen pressure, no haptics, no share sheet, no `.gox` file association.
* No `Audio` (sound is off in this build, same as the macOS build).
