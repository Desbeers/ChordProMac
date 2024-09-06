//
//  AppDelegate.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 13/06/2024.
//

import SwiftUI

/// The AppDelegate to bring the `About` Window into the SwiftUI world
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    /// The **ChordPro** information
    @Published var chordProInfo: ChordProInfo?
    /// The list of known directives
    @Published var directives: [ChordProDirective] = []
    /// Get the **ChordPro** information
    func applicationWillFinishLaunching(_ notification: Notification) {
        Task {
            chordProInfo = try? await Terminal.getChordProInfo()
            directives = Directive.getChordProDirectives(chordProInfo: chordProInfo)
        }
    }

    private var aboutBoxWindowController: NSWindowController?

    @MainActor func showAboutWindow() {
        if aboutBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled]
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "About ChordPro"
            window.contentView = NSHostingView(rootView: AboutView())
            window.center()
            aboutBoxWindowController = NSWindowController(window: window)
        }

        aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
    }

    private var exportFolderBoxWindowController: NSWindowController?

    @MainActor func showExportFolderWindow() {
        if exportFolderBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled]
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "Songbook from Folder"
            window.contentView = NSHostingView(rootView: ExportFolderView())
            window.center()
            exportFolderBoxWindowController = NSWindowController(window: window)
        }

        exportFolderBoxWindowController?.showWindow(exportFolderBoxWindowController?.window)
    }
}
