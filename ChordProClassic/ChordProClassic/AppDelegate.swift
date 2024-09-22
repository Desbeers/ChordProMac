//
//  AppDelegate.swift
//  ChordProClassic
//
//  Created by Nick Berendsen on 22/09/2024.
//

import Cocoa
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var open: URL?
    
    func application(_ sender: NSApplication, open urls: [URL]) {
    // Use open, not openFiles!
        print("appDelegate dropped urls:", urls) // diagnostic
        Logger.application.debug("Something dropped...")
        open = urls.first
    }
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        let arguments = ProcessInfo.processInfo.arguments
        
        dump(arguments)
        
        Logger.application.debug("Classic did start!!")
        
        // https://stackoverflow.com/questions/40875935/how-do-i-replace-the-current-swift-script-process-with-a-different-one
        
        var args: [String] = [""]
        
        if let open {
            args.append("\(open.path)")
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

