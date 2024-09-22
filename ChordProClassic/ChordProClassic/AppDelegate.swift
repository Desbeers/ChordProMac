//
//  AppDelegate.swift
//  ChordProClassic
//
//  Created by Nick Berendsen on 22/09/2024.
//

import Cocoa
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        dump(aNotification)
        Logger.application.info("Classic did start!!")
        
        // https://stackoverflow.com/questions/40875935/how-do-i-replace-the-current-swift-script-process-with-a-different-one
        
        let args: [String] = ["", "/Users/Desbeers/Desktop/Songs Folder/Feargal Sharkey - A good heart.chordpro"]

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

