//
//  main.swift
//  ChordProClassic
//
//  Created by Nick Berendsen on 22/09/2024.
//

import AppKit
import OSLog

// https://sarunw.com/posts/how-to-create-macos-app-without-storyboard/

// 1
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate


Logger.application.info("ARG: \(CommandLine.arguments.joined(separator: "-"), privacy: .public)")

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
