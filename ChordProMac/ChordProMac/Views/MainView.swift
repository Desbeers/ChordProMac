//
//  MainView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` for the main content
struct MainView: View {
    /// The optional file location
    let file: URL?
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @StateObject private var sceneState = SceneStateModel()
    /// The observable state of the document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        VStack(spacing: 0)  {
            HStack(spacing: 0) {
                EditorPaneView()
                PreviewPaneView()
            }
            StatusView()
        }
        .animation(.default, value: sceneState.panes)
        .animation(.default, value: sceneState.showLog)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    PanesButtons()
                    ExportSongButton(label: "Export PDF")
                    ShareButton()
                        .labelStyle(.iconOnly)
                }
            }
        }
        .labelStyle(.titleAndIcon)
        /// Set the default panes
        .task {
            if file == nil {
                sceneState.panes = .editorOnly
            } else {
                /// Create the preview unless we show only the editor
                if appState.settings.application.openSongAction != .editorOnly {
                    sceneState.file = file
                    do {
                        let pdf = try await sceneState.exportToPDF(text: document?.document.text ?? "error")
                        /// Show the preview
                        sceneState.preview.data = pdf.data
                    } catch {
                        /// Something went wrong
                        Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
                    }
                }
            }
        }
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
