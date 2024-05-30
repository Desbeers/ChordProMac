CURRDATE := $(shell date "+%Y-%m-%d")
TESTBUILDDIR := TestBuild
DMGNAME := ChordPro macOS ${CURRDATE}.dmg
MKDIR := mkdir

all: xcode archive

xcode:
	@echo "Building ChordPro"
	xcodebuild -project ChordProMac/ChordProMac.xcodeproj \
		-arch x86_64 \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		BUILD_DIR=../build
		
archive:
	@echo "Archive ChordPro"
	$(shell $(MKDIR) -p "build/ChordPro")
	$(shell cp -r "build/Release/ChordPro.app" "build/ChordPro")
	$(shell cp "ChordProMac/Read Me First.html" "build/ChordPro")
	rm -f "${TESTBUILDDIR}/${DMGNAME}"
	hdiutil create -format UDZO -srcfolder build/ChordPro/ "${TESTBUILDDIR}/${DMGNAME}"