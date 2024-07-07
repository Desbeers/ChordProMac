//
//  PreviewPDFView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `View` for a PDF preview
struct PreviewPDFButtonView: View {
    /// The label for the button
    let label: String
    /// The current document
    let document: ChordProDocument
    /// Bool if we have to replace the current preview
    var replacePreview: Bool = false
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The body of the `View`
    var body: some View {
        Button(
//            action: {
//                if sceneState.preview.url == nil || replacePreview {
//                    showPreview()
//                } else {
//                    sceneState.preview.url = nil
//                }
//            },
            action: {
                if sceneState.preview.data == nil || replacePreview {
                    showPreview()
                } else {
                    sceneState.preview.data = nil
                }
            },
            label: {
                Label(label, systemImage: sceneState.preview.url == nil ? "eye" : "eye.fill")
            }
        )
        .help("Preview the PDF")
        .task(id: sceneState.customTask) {
            if sceneState.customTask != nil {
                /// Show a preview with the task
                showPreview()
            }
        }
        .onChange(of: appState.settings.chordPro) { _ in
            if sceneState.preview.data != nil {
                /// Show a preview with the new settings
                showPreview()
            }
        }
    }
    /// Show a preview of the PDF
    @MainActor func showPreview() {
        Task {
            do {
                let pdf = try await Terminal.exportDocument(
                    text: document.text,
                    settings: appState.settings,
                    sceneState: sceneState
                )
                /// Set the status
                sceneState.exportStatus = pdf.status
                /// The preview is not outdated
                sceneState.preview.outdated = false
                /// Show the Quick Look
                //sceneState.preview.url = sceneState.exportURL
                /// Give the Quick Look a new ID
                //sceneState.preview.id = UUID().uuidString
                /// Show the Quick Look
                sceneState.preview.data = pdf.data
            } catch {
                /// Show an `Alert`
                sceneState.alertError = error
                /// Set the status
                sceneState.exportStatus = .pdfCreationError
            }
            /// Remove the task (if any)
            sceneState.customTask = nil
        }
    }
}

extension PreviewPDFButtonView {

    /// Update the preview of the current document
    struct UpdatePreview: View {
//        /// The current document
//        let document: ChordProDocument

        /// The document in the environment
        @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?

        var body: some View {
            if let document {
                PreviewPDFButtonView(
                    label: "Update Preview",
                    document: document.document,
                    replacePreview: true
                )
                .labelStyle(.titleOnly)
                .padding(8)
                .background(Color(nsColor: .textColor).opacity(0.04).cornerRadius(10))
                .background(
                    Color(nsColor: .textBackgroundColor)
                        .cornerRadius(10)
                        .shadow(
                            color: .secondary.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 2
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }
        }
    }
}
