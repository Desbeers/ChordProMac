//
//  PrintPDFView.swift
//  Chord Provider
//
//  © 2024 Nick Berendsen
//

import SwiftUI
import OSLog

/// SwiftUI `View` for the Print Button
struct PrintPDFView: View {
    /// The label for the button
    let label: String
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The scene state in the environment
    @FocusedValue(\.sceneState) private var sceneState: SceneState?
    /// The document in the environment
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                if let sceneState, let document {
                    Task {
                        do {
                            _ = try await sceneState.exportPDF(text: document.document.text)
                            /// Show the print dialog
                            AppKitUtils.printDialog(exportURL: sceneState.exportURL)
                        } catch {
                            Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
                        }
                    }
                }
            },
            label: {
                Label(label, systemImage: "printer")
            }
        )
        .help("Print a PDF of the song")
        .disabled(sceneState == nil)
    }
}
