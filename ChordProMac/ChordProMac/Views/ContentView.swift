//
//  ContentView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `View` for the main content
struct ContentView: View {
    /// The optional file location
    let file: URL?
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @StateObject private var sceneState = SceneStateModel()
    /// The body of the `View`
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                EditorPaneView()
                PreviewPaneView()
            }
            StatusView()
                .padding(.horizontal)
        }
        .animation(.default, value: sceneState.preview)
        .toolbar {
            FontSizeButtonsView()
            ExportSongView(label: "Export as PDF")
            Group {
                PreviewPDFButtonView(label: "Show Preview")
                ShareButtonView()
            }
            .labelStyle(.iconOnly)
        }
        .labelStyle(.titleAndIcon)
        /// Store the filename in the scene
        .task(id: file) {
            sceneState.file = file
        }
        .environmentObject(sceneState)
        /// Give the application access to the scene.
        .focusedSceneValue(\.sceneState, sceneState)
        /// Make sure all directives are up-to-date
        .task {
            appState.chordProInfo = try? await Terminal.getChordProInfo()
            appState.directives = Directive.getChordProDirectives(chordProInfo: appState.chordProInfo)
        }
    }
}
