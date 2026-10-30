package com.aosgoxel;

import org.libsdl.app.SDLActivity;

/**
 * Entry point of the Android build.
 *
 * All the work is done by SDLActivity: it creates the window, loads libSDL2.so
 * and libmain.so, and runs SDL_main() (our main() in src/main_sdl.c) on a
 * dedicated thread.  Touch, the software keyboard and the app lifecycle are
 * handled by SDL, so nothing else is needed here for now.
 *
 * This class is the place to add a native file picker later (onActivityResult
 * + a JNI callback), if the "put the file in Android/data/com.aosgoxel/files"
 * workflow is not enough.
 */
public class GoxelActivity extends SDLActivity {
    @Override
    protected String[] getLibraries() {
        // SDLActivity loads the last library of this list as the entry point,
        // so "main" (libmain.so) has to stay last.
        return new String[] { "SDL2", "main" };
    }
}
