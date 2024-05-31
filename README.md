# ChordProMac

A MacOS SwiftUI wrapper for the official [ChordPro](https://chordpro.org) program.

![ChordProMac](https://github.com/Desbeers/ChordProMac/raw/main/Images/screenshot-macOS.jpg)

Goal is to replace the very outdated current wrapper. See [MacOS rewrite](https://github.com/ChordPro/chordpro/issues/373).

It is using the official pre-compiled binary to do the hard work and that is in the `Bin` directory of the project.

The chordpro-core `Bin` directory can be updated with `make chordpro` but requires a lot of perl-packages to compile...

## What can it do

- Open and save **ChordPro** files
- QuickLook the PDF
- Export the PDF
- Choose templates
- Transpose and transcode a song

## Building

- There are pre-compiled `dmg` images in the 'TestBuild' folder.

### Build yourself (arm and intel)

- Clone or download the project

#### Xcode:

- Open the project in Xcode
- Change the signing  certificate to your own
- Build and run!

#### Command line:

- You don't need a developers account or a full install of Xcode
- `Xcode Command Line Tools` must be installed (enter 'xcode-select --install' in the Terminal to install)
- Run `make xcodebuild` from the root of the project. That will build an unsigned Intel application... It works on arm as well, it is just that universal binaries will not run unsigned at all...

## Notes

- MacOS 12 or higher...
