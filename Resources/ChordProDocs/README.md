# ChordPro for macOS

## What is ChordPro

**ChordPro**, the application, is first and foremost a command-line application and the reference implementation for the **ChordPro** standard:

> “A simple text format for the notation of lyrics with chords”.

The package you downloaded contains this powerful but maybe *hard-to-use* application that you have to run in the `Teminal`.

It is wrapped in a very pleasant and easy to use graphical application that gives you the basics of using **ChordPro**; both the application as well its text-format.

We called this graphical application also **ChordPro**; because *why not*?

## It is not easy

Providing applications for the Mac platform is not as easy as it seems. For the users, its mostly just *drag and drop*. It is not that easy for developers. Apple has a [lot of security](https://support.apple.com/en-gb/guide/security/secf826eff27/web) in place to make sure your *drag and drop* will be safe for you.

It needs a lot of time, effort and yeh... money for developers to provide such application for the Mac.

**ChordPro** is not a commercial product. It is an *Open Source* application made by volunteers. You are welcome to [download the source](https://github.com/ChordPro/chordpro), compile it and enjoy!

That is not realistic for must users, especially not on the Mac. We would love to provide you the expected experience but we can’t. There is nobody in the **ChordPro** community with an Apple Developers certificate to provide you this *ready to go* experience.

## The Gatekeeper

Your download contains an *almost* ready to go **ChordPro**; except that the application is only ad-hoc signed by us and not by an approved Apple Developer with a valid certificate. So, the security system on your Mac will give an error when you double-click the application. You have met the Gatekeeper. Depending of the version of macOS you have a different message and have to do different additional handlings to open **ChordPro**.

The message will be more or less like this:

> Apple could not verify “ChordPro.app" is free of malware that may harm your Mac or compromise your privacy.

On macOS versions before 15 (Sequoia) it was common practice to `right-click` the application and choose `Open` from the menu. That trick will bypass the gatekeeper and let you open the application.

Unfortunately, that does not work anymore on Sequoia and you have to go trough System Settings:

1. Try to open the application. A prompt saying ”ChordPro.app" Not Opened' may appear.
2. Go to `System Settings -> Privacy & Security`. Scroll down to find *ChordPro*, and an option to "Open Anyway".
3. Choose "Open Anyway".
4. Authenticate as an administrator.
5. *ChordPro* will now open.

## Install with the Terminal

Your download also contains an `Install` script that can do this for you. Same as with the *ChordPro.app*, you can not just double click to run the script. You have to run it manually in the Terminal yourself:

> Open the **Terminal** application in the `Applications/Utilities` and just *drag and drop* the `Install` script into its window.

It will do the following:

- Copy *ChordPro* to your applications folder
- Move *ChordPro* out of quarantine so the Gatekeeper will let you start the application with just a double-click.
- Add the *ChordPro* command-line command to your Terminal \$PATH

**It will not do anything without your permission but by providing your administration password, you will bypass all Apple’s security measurements.**

## Enjoy!

We hope you appreciate our best efforts.

The Mac is a beautiful platform for its users.

**Are you a macOS developer with an Developer Account? Please help us to provide a signed package to improve the user experience.**

\-- The ChordPro team

- Consult [www.chordpro.org](https://www.chordpro.org) for information and documentation.</p>
- Please join [the user forum](https://groups.io/g/ChordPro) for support and the latest updates.

