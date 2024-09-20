//
//  AppDelegateModel.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 13/06/2024.
//

import SwiftUI

/// The AppDelegate to bring the `About` Window into the SwiftUI world
class AppDelegateModel: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
    }

    private var aboutWindowController: NSWindowController?

    @MainActor func showAboutWindow() {
        if aboutWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled]
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "About ChordPro"
            window.contentView = NSHostingView(rootView: AboutView())
            window.center()
            aboutWindowController = NSWindowController(window: window)
        }
        aboutWindowController?.showWindow(aboutWindowController?.window)
    }

    private var songbookWindowController: NSWindowController?

    @MainActor func showSongbookWindow() {
        if songbookWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled]
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "Export a Folder to a Songbook"
            window.contentView = NSHostingView(rootView: SongbookView())
            window.center()
            songbookWindowController = NSWindowController(window: window)
        }
        songbookWindowController?.showWindow(songbookWindowController?.window)
    }
}
