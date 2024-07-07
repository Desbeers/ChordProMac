//
//  PreviewPaneView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 05/07/2024.
//

import SwiftUI
import ChordProShared

/// SwiftUI `View` with the preview pane
struct PreviewPaneView: View {
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// The document in the environment
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    var body: some View {
        if let url = sceneState.preview.url, let document = document?.document {
            QLPreviewRepresentedView(url: url)
                .id(sceneState.preview.id)
                .overlay(alignment: .top) {
                    if sceneState.preview.outdated {
                        PreviewPDFView.UpdatePreview(document: document)
                    }
                }
        }
    }
}
