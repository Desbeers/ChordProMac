//
//  ChordProMacApp.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `Scene` for **ChordProMac**
@main struct ChordProMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegateModel.self) var appDelegate
    /// The observable state of the application
    @StateObject private var appState = AppStateModel.shared
    /// The body of the `Scene`
    var body: some Scene {
        DocumentGroup(newDocument: ChordProDocument()) { file in
            ContentView(file: file.fileURL)
                .frame(minWidth: 680, minHeight: 480)
                .environmentObject(appState)
            /// Give the scene access to the document.
                .focusedSceneValue(\.document, file)
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button("About ChordPro") {
                    appDelegate.showAboutWindow()
                }
            }
#if DEBUG
            CommandMenu("Debug") {
                DebugView.ResetApplicationButtonView()
            }
#endif
            CommandGroup(after: .importExport) {
                ExportSongView(label: "Export as PDF…")
                    .environmentObject(appState)
                Divider()
                PrintPDFButtonView(label: "Print…")
                    .environmentObject(appState)
            }
            CommandMenu("Songbook") {
                Button("Export Folder…") {
                    appDelegate.showSongbookWindow()
                }
            }
            CommandMenu("Tasks") {
                TaskMenuView()
            }
            CommandGroup(replacing: .help) {
                HelpButtonsView()
                    .environmentObject(appState)
            }
        }
        Settings {
            SettingsView()
                .frame(width: 300, height: 440)
                .environmentObject(appState)
        }
    }
}
