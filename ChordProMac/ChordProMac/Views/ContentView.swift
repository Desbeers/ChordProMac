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
            HStack(spacing: 0) {
                ChordProEditor(
                    text: $document.text,
                    settings: appState.settings.editor,
                    directives: appState.directives
                )
                .introspect { editor in
                    Task { @MainActor in
                        sceneState.editorInternals = editor
                    }
                }
                HStack(spacing: 0) {
                    Divider()
                    if let quickView = sceneState.quickLookURL {
                        QuickLookView.Preview(url: quickView)
                            .id(sceneState.quickLookID)
                            .overlay(alignment: .top) {
                                if sceneState.quickLookOutdated {
                                    QuickLookView.UpdatePreview(document: document)
                                }
                            }
                    }
                }
            }
            StatusView()
                .padding(.horizontal)
        }
        .animation(.default, value: sceneState.quickLookURL)
        .animation(.default, value: sceneState.quickLookOutdated)
        .errorAlert(error: $sceneState.alertError, log: $sceneState.showLog)
        .onChange(of: document.text) { _ in
            if sceneState.quickLookURL != nil {
                sceneState.quickLookOutdated = true
            }
        }
        .toolbar {
            FontSizeButtonsView()
            ExportSongView(label: "Export as PDF")
            ControlGroup {
                PrintPDFView(label: "Print PDF")
                QuickLookView(label: "Show Preview", document: document)
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
