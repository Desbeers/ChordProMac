//
//  EditorPaneView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 05/07/2024.
//

import SwiftUI

/// SwiftUI `View` with the editor
struct EditorPaneView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The observable state of the document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// The body of the `View`
    var body: some View {
        if sceneState.panes != .previewOnly, let document {
            VStack(spacing: 0) {
                ChordProEditor(
                    text: document.$document.text,
                    settings: appState.settings.editor,
                    directives: appState.directives,
                    log: sceneState.editorMessages
                )
                .introspect { editor in
                    Task { @MainActor in
                        sceneState.editorInternals = editor
                    }
                }
                Divider()
                HStack(spacing: 0) {
                    Text("Line \(sceneState.editorInternals.currentLineNumber)")
                    let logMessages = sceneState.logMessages
                        .filter { $0.lineNumber == sceneState.editorInternals.currentLineNumber }
                        .map(\.message)
                        .joined(separator: ", ")
                    Text(.init(logMessages.isEmpty ? " " : ": \(logMessages)"))
                    Spacer()
                    FontSizeButtons()
                        .labelStyle(.iconOnly)
                        .controlSize(.small)
                        .buttonStyle(.plain)
                        .padding(.trailing)
                }
                .font(.caption)
                .padding(.leading)
                .padding([.vertical], 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
            }
            .frame(maxHeight: .infinity)
            /// - Note: Make sure we have an up-to-date list of directives
            .id(appState.directives.map(\.directive))
        }
    }
}
