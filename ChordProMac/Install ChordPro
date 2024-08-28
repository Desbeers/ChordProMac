#!/bin/zsh

if [ $(id -u) != 0 ]; then
   echo "This script requires administration permission to install ChordPro"
   sudo "$0" "$@"
   exit
fi

echo "Copy ChordPro to your Applications folder"

cp -r "${0:a:h}/Resources/ChordPro.app" /Applications/

echo "Codesign the application"

xattr -cr /Applications/ChordPro.app
codesign --force --deep -s - /Applications/ChordPro.app

echo "Remove the quarantine"

xattr -r -d com.apple.quarantine /Applications/ChordPro.app

echo "Adding ChordPro to your path"

echo "/Applications/ChordPro.app/Contents/Resources" > /private/etc/paths.d/chordpro

echo "\nDone!\n\nEnjoy ChordPro!"