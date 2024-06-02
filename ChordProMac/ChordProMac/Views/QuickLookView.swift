//
//  QuickLookView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import QuickLook

/// SwiftUI `View` for a quick look button
struct QuickLookView: View {
    /// The document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The optional QuickLook URL
    @State private var quickLookURL: URL?
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                Task {
                    if let document {
                        do {
                            let pdf = try await Terminal.exportDocument(
                                document: document.document,
                                settings: appState.settings,
                                sceneState: sceneState
                            )
                            quickLookURL = pdf.exportURL
                        } catch {
                            sceneState.alertError = error
                        }
                        /// Something has happen and there should be a log available
                        sceneState.logIsAvailable = true
                    }
                }
            },
            label: {
                Label("PDF preview", systemImage: quickLookURL == nil ? "eye" : "eye.fill")
            }
        )
        .labelStyle(.iconOnly)
        .quickLookPreview($quickLookURL)
    }
}
