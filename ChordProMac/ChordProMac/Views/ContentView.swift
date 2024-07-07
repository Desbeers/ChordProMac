//
//  ContentView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import ChordProShared

/// SwiftUI `View` for the main content
struct ContentView: View {
    /// Binding to the current document
    @Binding var document: ChordProDocument
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @StateObject private var sceneState = SceneState()
    /// The font for the editor
    var nsFont: NSFont {
        return appState.settings.editor.fontStyle.nsFont(size: appState.settings.editor.fontSize)
    }
    /// The body of the `View`
    var body: some View {
        VStack {
            HStack {
                EditorView()
                /// - Note: Put the preview in its own stack, so a refresh does not scroll the editor back to top
                HStack(spacing: 0) {
                    PreviewPaneView()
                }
            }
            StatusView()
                .padding(.horizontal)
        }
        .animation(.default, value: sceneState.preview)
        .errorAlert(error: $sceneState.alertError, log: $sceneState.showLog)
        .onChange(of: document.text) { _ in
            if sceneState.preview.url != nil {
                sceneState.preview.outdated = true
            }
        }
        .toolbar {
            FontSizeButtonsView()
            ExportSongView(label: "Export as PDF")
            Group {
                PreviewPDFView(label: "Show Preview", document: document)
                ShareButtonView(document: document)
            }
            .labelStyle(.iconOnly)
        }
        .labelStyle(.titleAndIcon)
        .sheet(isPresented: $sceneState.showLog) {
            LogView()
        }
        .environmentObject(sceneState)
        /// Give the application access to the scene.
        .focusedSceneValue(\.sceneState, sceneState)
    }
}
