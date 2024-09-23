//
//  main.swift
//  ChordProClassic
//
//  Created by Nick Berendsen on 22/09/2024.
//

/// - Note: The name of this file **must** be `main.swift` or else it does not work

import AppKit

// MARK: Start the application

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

// MARK: The Application Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    /// The optional URL to open
    var open: URL?
    /// Store the requested file URL
    func application(_ sender: NSApplication, open urls: [URL]) {
        open = urls.first
    }
    /// Set the arguments and create a window with wxWidgets
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("ChordPro wrapper launched!")
        /// We must create arguments but the first on is ignored
        var args: [String] = [""]
        /// Add the optional file URL as second argument
        if let open {
            args.append("\(open.path)")
        }
        /// Black magic
        let cargs = args.map { strdup($0) } + [nil]
        /// Execute the real **ChordPro** program with its arguments
        execv("/Applications/ChordPro.app/Contents/MacOS/wxchordpro", cargs)
        /// This should not happen
        fatalError("exec failed")
    }
}
