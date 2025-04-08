This directory contains the SoundFont file required by the Iris application.

The SoundFont file FluidR3_GM.sf2 must be included in the app bundle for the audio
functionality to work properly.

When adding this directory to the Xcode project, make sure to:
1. Add the entire 'Resources' directory to the project
2. Select "Create folder references" (blue folder icon) rather than "Create groups" (yellow folder)
3. Ensure the SoundFont file is included in the target's "Copy Bundle Resources" build phase

The audio engine will automatically search for the SoundFont file in the app bundle 
and in the Resources/SoundFonts directory.