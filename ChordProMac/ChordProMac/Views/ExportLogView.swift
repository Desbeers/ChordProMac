//
//  ExportLogView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/06/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` for an export log button
struct ExportLogView: View {
    /// The label for the button
    let label: String
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
//    /// The observable state of the application
//    @EnvironmentObject private var appState: AppState
    /// The scene
    //@FocusedValue(\.sceneState) private var sceneState: SceneState?
    /// Present an export dialog
    @State private var exportLog = false
    /// The log as String
    @State private var log: String?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                    Task {
                        do {
                            log = try String(contentsOf: sceneState.logFileURL, encoding: .utf8)
                            exportLog = true
                        } catch {
                            /// Show an error
                            sceneState.alertError = error
                        }
                    }
            },
            label: {
                Text(label)
            }
        )
        .fileExporter(
            isPresented: $exportLog,
            document: LogDocument(log: log),
            contentType: .plainText,
            defaultFilename: "ChordPro Log Export"
        ) { _ in
            Logger.pdfBuild.notice("Export log completed")
        }
    }
}
