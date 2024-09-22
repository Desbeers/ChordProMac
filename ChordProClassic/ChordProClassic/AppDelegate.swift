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
        
        
        let arguments = ProcessInfo.processInfo.arguments
        
        dump(arguments)
        
        Logger.application.info("Classic did start!!")
        
        // https://stackoverflow.com/questions/40875935/how-do-i-replace-the-current-swift-script-process-with-a-different-one
        
        var args: [String] = [""]
        
        if let song = Bundle.main.url(forResource: "busstop", withExtension: "chordpro") {
            args.append("\(song.path)")
        }

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

