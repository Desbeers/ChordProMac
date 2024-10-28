//
//  PanesButtons.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` with a button for a PDF preview
struct PanesButtons: View {
    /// Bool if we have to replace the current preview
    var replacePreview: Bool = false
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The observable state of the document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        Picker("Options", selection: $sceneState.panes) {
            ForEach(SceneStateModel.Panes.allCases, id: \.self) { option in
                Text("\(option.rawValue)")
            }
        }
        .pickerStyle(.segmented)
        .task(id: sceneState.customTask) {
            if sceneState.customTask != nil {
                /// Clear the data
                sceneState.preview.data = nil
                /// Show a preview with the task
                PreviewPaneView.showPreview(document: document, sceneState: sceneState)
            }
        }
        .onChange(of: appState.settings.chordPro) { _ in
            if sceneState.preview.data != nil {
                /// Show a preview with the new settings
                PreviewPaneView.showPreview(document: document, sceneState: sceneState)
            }
        }
    }
}
