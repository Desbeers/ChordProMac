//
//  ExportSongView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` for an export button
struct ExportSongView: View {
    /// The label for the button
    let label: String
    /// The document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The app settings
    @EnvironmentObject private var appState: AppState
    /// Present an export dialog
    @State private var exportFile = false
    /// The song as PDF
    @State private var pdf: Data?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                if let document {
                    Task {
                        do {
                            /// Create the PDF with **ChordPro**
                            let pdf = try await Terminal.exportDocument(
                                document: document.document,
                                settings: appState.settings
                            )
                            /// Set the PDF as Data
                            self.pdf = pdf.data
                            /// Show the export dialog
                            exportFile = true
                        } catch {
                            /// Show an error
                            appState.alertError = error
                        }
                    }
                }
            },
            label: {
                Text(label)
            }
        )
        /// Disable the button when there is no document window in focus
        .disabled(document == nil)
        .fileExporter(
            isPresented: $exportFile,
            document: ExportDocument(pdf: pdf),
            contentType: .pdf,
            defaultFilename: document?.fileURL?.deletingPathExtension().lastPathComponent ?? "Export"
        ) { _ in
            Logger.pdfBuild.notice("Export completed")
        }

    }
}
