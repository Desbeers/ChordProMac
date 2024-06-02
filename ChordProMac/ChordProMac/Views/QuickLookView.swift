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
    /// The current document
    let document: ChordProDocument
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
                    do {
                        let pdf = try await Terminal.exportDocument(
                            document: document,
                            settings: appState.settings,
                            sceneState: sceneState
                        )
                        /// Show the Quick Look
                        quickLookURL = sceneState.exportURL
                        /// Set the status
                        sceneState.exportStatus = pdf.status
                    } catch {
                        /// Show an `Alert`
                        sceneState.alertError = error
                        /// Set the status
                        sceneState.exportStatus = .pdfCreationError
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
