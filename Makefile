CURRDATE := $(shell date "+%Y-%m-%d")
TESTBUILDDIR := TestBuild
DMGNAME := ChordPro macOS ${CURRDATE}.dmg
MKDIR := mkdir

DEST   := build

WRAPPERBIN := ChordProMac/ChordProMac/Bin

all: xcode archive
	
chordpro:
	@echo "Building ChordPro core"
	rm -fr "${DEST}/ChordProSource"
	$(MKDIR) -p "${DEST}/ChordProSource"
	git clone --branch dev https://github.com/ChordPro/chordpro.git "${DEST}/ChordProSource"
	cd "${DEST}/ChordProSource/pp/macos" && make ppl TARGET=chordpro
	@echo "Code signing..."
	codesign --force -s - "${DEST}/ChordProSource/pp/macos/build/libperl.dylib"
	@echo "Copy core to the wrapper..."
	rm -fr "${WRAPPERBIN}"
	$(MKDIR) -p "${WRAPPERBIN}"
	cp -r "${DEST}/ChordProSource/pp/macos/build/chordpro" "${WRAPPERBIN}"
	cp -r "${DEST}/ChordProSource/pp/macos/build/libperl.dylib" "${WRAPPERBIN}"
	cp -r "${DEST}/ChordProSource/pp/macos/build/lib" "${WRAPPERBIN}"
	cp -r "${DEST}/ChordProSource/pp/macos/build/script" "${WRAPPERBIN}"

xcode:
	@echo "Building ChordProMac"
	rm -fr "${DEST}/XcodeSource"
	$(MKDIR) -p "${DEST}/XcodeSource"
	cp -r "ChordProMac" "${DEST}/XcodeSource"
	xcodebuild -project ${DEST}/XcodeSource/ChordProMac/ChordProMac.xcodeproj \
		-arch x86_64 \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		BUILD_DIR=../../../build
		
archive:
	@echo "Archive ChordPro"
	$(MKDIR) -p "${DEST}/ChordPro"
	cp -r "${DEST}/Release/ChordPro.app" "build/ChordPro"
	cp "ChordProMac/Read Me First.html" "${DEST}/ChordPro"
	rm -f "${TESTBUILDDIR}/${DMGNAME}"
	hdiutil create -format UDZO -srcfolder build/ChordPro/ "${TESTBUILDDIR}/${DMGNAME}"
	
clean:
	rm -fr ${DEST}