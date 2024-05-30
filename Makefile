CURRDATE := $(shell date "+%Y-%m-%d")
TESTBUILDDIR := TestBuild
DMGNAME := ChordPro macOS ${CURRDATE}.dmg

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
	rm -f "${TESTBUILDDIR}/${DMGNAME}"
	hdiutil create -format UDZO -srcfolder build/Release/ChordPro.app "${TESTBUILDDIR}/${DMGNAME}"