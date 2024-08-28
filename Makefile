CURRDATE := $(shell date "+%Y-%m-%d")
TESTBUILDDIR := TestBuild
DMGNAME := ChordPro macOS ${CURRDATE}.dmg
MKDIR := mkdir

DEST   := build

WRAPPERBIN := ChordProMac/ChordProMac/Bin

all: archive
	
chordpro:
	@echo "Building ChordPro core"
	rm -fr "${DEST}/ChordProSource"
	$(MKDIR) -p "${DEST}/ChordProSource"
	git clone --branch dev https://github.com/Desbeers/chordpro.git "${DEST}/ChordProSource"
	cd "${DEST}/ChordProSource/pp/macosswift" && make chordpro
	@echo "Copy core to the wrapper..."
	rm -fr "${WRAPPERBIN}"
	$(MKDIR) -p "${WRAPPERBIN}"
	cp -r "${DEST}/ChordProSource/pp/macosswift/${WRAPPERBIN}/" "${WRAPPERBIN}"

xcodebuild: info
	@echo "Building ChordProMac for Apple Silicone"
	rm -fr "${DEST}/XcodeSource"
	$(MKDIR) -p "${DEST}/XcodeSource"
	cp -r "ChordProMac" "${DEST}/XcodeSource"
	xcodebuild -project ${DEST}/XcodeSource/ChordProMac/ChordProMac.xcodeproj \
		-arch arm64 \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=YES \
		BUILD_DIR=../../../build
		
archive: xcodebuild
	@echo "Archive ChordPro"
	$(MKDIR) -p "${DEST}/ChordPro/Resources"
	cp -r "${DEST}/Release/ChordPro.app" "build/ChordPro/Resources"
	cp "ChordProMac/Read Me.html" "${DEST}/ChordPro"
	cp "ChordProMac/Install.zsh" "${DEST}/ChordPro"
	rm -f "${TESTBUILDDIR}/${DMGNAME}"
	hdiutil create -format UDZO -srcfolder build/ChordPro/ "${TESTBUILDDIR}/${DMGNAME}"
	
info:
	@echo "Add core info to the wrapper..."
	${WRAPPERBIN}/chordpro -A -A -A -> ${WRAPPERBIN}/ChordProInfo.json
	
clean:
	rm -fr ${DEST}
