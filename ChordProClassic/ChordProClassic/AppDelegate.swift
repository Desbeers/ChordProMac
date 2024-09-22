//
//  AppDelegate.swift
//  ChordProClassic
//
//  Created by Nick Berendsen on 22/09/2024.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let args: [String] = []

        // Array of UnsafeMutablePointer<Int8>
        let cargs = args.map { strdup($0) } + [nil]

        execv("/Applications/ChordPro.app/Contents/MacOS/wxchordpro", cargs)

        fatalError("exec failed")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

