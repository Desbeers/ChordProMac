//
//  main.swift
//  ChordProClassic
//
//  Created by Nick Berendsen on 22/09/2024.
//

import AppKit

// 1
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
