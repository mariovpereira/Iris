# SoundFonts for MusicNotes

This directory contains SoundFont (.sf2) files used by the MusicNotes app for instrument playback.

## Required SoundFonts

The app requires one of the following SoundFont files to be placed in this directory:

1. **FluidR3_GM.sf2** (Recommended)
   - A comprehensive General MIDI SoundFont with high-quality instrument samples
   - Size: ~140MB
   - Download from: [https://member.keymusician.com/Member/FluidR3_GM/](https://member.keymusician.com/Member/FluidR3_GM/)

2. **ChoriumRevA.sf2** (Lighter alternative)
   - A lighter weight SoundFont with good quality instrument samples
   - Size: ~30MB
   - Download from: [https://schristiancollins.com/generaluser.php](https://schristiancollins.com/generaluser.php)

## Installation

1. Download one of the SoundFont files from the links above
2. Place the .sf2 file in this directory
3. Make sure the file is named exactly as specified above (case-sensitive)

## Usage

The app will automatically load the SoundFont file at startup. If both files are present, FluidR3_GM.sf2 will be used by default. If neither file is found, the app will fall back to a simpler sound generation method.

## Licensing

Both SoundFont files are free to use, but please respect their respective licenses:

- **FluidR3_GM.sf2**: Released under the MIT License
- **ChoriumRevA.sf2**: Released under the Creative Commons Attribution 3.0 license

Please refer to the original download sites for complete license information.