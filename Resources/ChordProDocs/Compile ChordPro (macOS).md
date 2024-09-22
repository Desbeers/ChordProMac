# Build ChordPro from source on a Mac

While it is not too easy to build **ChordPro** from source, it is doable. It will take some time and a lot of space; mainly because of the size of Xcode.

***Note**: These instructions are tested on macOS Sonoma, Ventura and Monterey.*

## Homebrew

Install [homebrew](https://brew.sh) and follow its instructions carefully.

## Perl

Once homebrew is installed, install the following formulas:

	brew install perl
	brew install cpanminus

Again, follow the instructions. It is important to add stuff to your `~/.zprofile`. In the end, the content should look like this:

	eval "$(/opt/homebrew/bin/brew shellenv)"
	eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"

***Note**: The pre-installed version of Perl cannot be used to build ChordPro. It contains a ‘universal’ dynamic library, both for Intel and ARM and ChordPro needs it for a specific architecture.*

Then, instal the following Perl package:

	cpanm PAR::Packer

***Note**: This package comes pre-installed on the Mac but it is insisting on using the ‘system-perl’. So we have to add a local version and that is why it is so important to have a correct `~/.zprofile`.*

## ChordPro CLI
	
Download or clone the `[dev](https://github.com/ChordPro/chordpro/tree/dev)` branch of ChordPro.

Open the downloaded folder in the Terminal (right-click folder in the Finder and choose ‘New Terminal at Folder’)

In the Terminal:

	cpanm --installdeps .

***Note**: Don’t forget the ‘.’ at the end!*

***Note**: Sometimes, ChordPro will add new dependencies. If compiling does not work anymore after a checkout, run above comment again.*

This will install most of the needed dependencies, but not all. Extra dependencies you have to install:

	cpanm HarfBuzz::Shaper
	cpanm Mozilla::CA

Now you can build the CLI version of **ChordPro**:

	cd pp/macos
	make ppl TARGET=chordpro
	
You will get some warnings but the building should complete and there is a **ChordPro** binary in the `pp/macos/build` directory.

***Note**: If you build on an Apple Silicon Mac, this binary will -not- run because it is unsigned. No worries, we deal with that later.*

## ChordPro SwiftUI GUI

If you are able to build the CLI version, you can build the SwiftUI GUI. Xcode will do that for us, again from the command-line.

### Xcode

Install Xcode. Best to download it directly from the Apple developer website or use [Xcodes](https://www.xcodes.app). Downloading Xcode from the Mac App Store often gives problems and is not recommended.

#### Intel:

	cd ../macosswift
	make
	
This will build a DMG with an ad-hoc signed Intel version.

#### Apple Silicon:

	cd ../macosswift
	make ARCH=arm64
 
 This will build a DMG with an ad-hoc signed Apple Silicon version.

***Note**: You cannot build an Intel version on an Apple Silicon Mac or an Apple Silicon version on an Intel. Also, ChordPro cannot be build as a ‘universal application’*.

You should now have a DMG in the `pp/macosswift` directory that is ready to use.


