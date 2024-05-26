//
//  ChordProMacApp.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `Scene` for **ChordProMac**
@main struct ChordProMacApp: App {
    /// The body of the `Scene`
    var body: some Scene {
        DocumentGroup(newDocument: ChordProDocument()) { file in
            ContentView(document: file.$document)
            /// Give the scene access to the document.
                .focusedSceneValue(\.document, file)
        }
        .commands {
            CommandGroup(after: .importExport) {
                ExportSongView(label: "Export as PDF…")
            }
        }
    }
}


