#!/bin/zsh

######################################################
#                                                    #
# Install and ad-hoc re-sign an application on macOS #
#                                                    #
######################################################

# Nice colours
autoload colors
if [[ "$terminfo[colors]" -gt 8 ]]; then
    colors
fi
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval $COLOR='$fg_no_bold[${(L)COLOR}]'
    export $COLOR
    eval BOLD_$COLOR='$fg_bold[${(L)COLOR}]'
    export BOLD_$COLOR
done
eval RESET='$reset_color'
export RESET

# The name of the application
APPLICATION="$BOLD_BLUE""ChordPro""$RESET"

# We need administration access to run this script
if [ $(id -u) != 0 ]; then
   echo "\n$BOLD_RED""This install script requires administration permission to install $APPLICATION$RESET"
   echo "
It will do the following:

- Copy $APPLICATION to your applications folder
- Remove all attributes that prevents code-signing
- Re-sign $APPLICATION ‘ad-hoc’, so it is yours and yours only
- Move $APPLICATION out of quarantine
- Add the $APPLICATION command-line command to your Terminal \$PATH
"
   echo "$BOLD_BLACK""Use it at your own risk...$RESET\n"
   sudo "$0" "$@"
   exit
fi

# Make the application name green because we have sudo :-)
APPLICATION="$BOLD_GREEN""ChordPro""$RESET"

echo "\nCopy $APPLICATION to your Applications folder..."

rm -fr "/Applications/ChordPro.app"

cp -r "${0:a:h}/ChordPro.app" /Applications/

echo "Ad-hoc code-sign $APPLICATION to make it yours...\n$RESET$MAGENTA"

# Remove stuff that prevents code-signing
xattr -cr /Applications/ChordPro.app
# Re-sign the application
codesign --force --deep -s - /Applications/ChordPro.app

echo "$RESET\nRemove the quarantine flag; its yours now!"

xattr -rd com.apple.quarantine /Applications/ChordPro.app

echo "Adding $APPLICATION to your path for real power in the Terminal..."

echo "/Applications/ChordPro.app/Contents/Resources" > /private/etc/paths.d/chordpro

echo "\nDone!\n\nEnjoy $APPLICATION on your Mac!\n"
