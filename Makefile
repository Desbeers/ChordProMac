CURRDATE := $(shell date "+%Y-%m-%d")
TESTBUILDDIR := TestBuild
DMGNAME := ChordPro macOS ${CURRDATE}.dmg
MKDIR := mkdir

DEST   := build

COREDIR := ChordProMac/ChordProMac/Core

all: archive
	
chordpro:
	@echo "Building ChordPro core"
	rm -fr "${DEST}/ChordProSource"
	$(MKDIR) -p "${DEST}/ChordProSource"
	git clone --branch dev https://github.com/Desbeers/chordpro.git "${DEST}/ChordProSource"
	cd "${DEST}/ChordProSource/pp/macosswift" && make chordpro
	@echo "Copy core to the wrapper..."
	rm -fr "${COREDIR}"
	$(MKDIR) -p "${COREDIR}"
	cp -R "${DEST}/ChordProSource/pp/macosswift/${COREDIR}/" "${COREDIR}"
	cd "${COREDIR}"; ln -s -v ../chordpro cli/chordpro

xcodebuild:
	@echo "Building ChordProMac for Apple Silicone"
	rm -fr "${DEST}/XcodeSource"
	$(MKDIR) -p "${DEST}/XcodeSource"
	cp -R "ChordProMac" "${DEST}/XcodeSource"
	xcodebuild -project ${DEST}/XcodeSource/ChordProMac/ChordProMac.xcodeproj \
		-arch arm64 \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=YES \
		BUILD_DIR=../../../build
	
clean:
	rm -fr ${DEST}

archive: xcodebuild
	@echo "Archive ChordPro"
	rm -fr "${DEST}/ChordPro"
	$(MKDIR) -p "${DEST}/ChordPro"
	cp -R "${DEST}/Release/ChordPro.app" "${DEST}/ChordPro"
	cp "Resources/README.html" "${DEST}/ChordPro"
	cp "Resources/Install.zsh" "${DEST}/ChordPro"
	rm -f "${TESTBUILDDIR}/${DMGNAME}"
	# Create the DMG
	bash Resources/Create-dmg/create-dmg \
	  --volname "ChordPro Development Version" \
	  --volicon "Resources/chordpro-dmg.icns" \
	  --background "Resources/installer_background.png" \
	  --eula "Resources/eula.rtf" \
	  --window-pos 200 120 \
	  --window-size 700 440 \
	  --icon-size 64 \
	  --icon "ChordPro.app" 560 75 \
	  --hide-extension "ChordPro.app" \
	  --icon "README.html" 560 175 \
	  --hide-extension "README.html" \
	  --icon "Install.zsh" 560 275 \
	  --hide-extension "Install.zsh" \
	  "${TESTBUILDDIR}/${DMGNAME}" \
	  "${DEST}/ChordPro"