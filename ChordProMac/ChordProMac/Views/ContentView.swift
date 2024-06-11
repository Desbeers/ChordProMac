//
//  ContentView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

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
        return appState.settings.fontStyle.nsFont(size: appState.settings.fontSize)
    }
    /// The body of the `View`
    var body: some View {
        VStack {
            MacEditorView(
                text: $document.text,
                font: nsFont
            )
            /// - Note: Below is needed or else new files to not 'quick-view' for some unknown reason...
            .disabled(sceneState.quickLookURL != nil)
            StatusView()
                .padding(.horizontal)
        }
        .quickLookPreview($sceneState.quickLookURL)
        .errorAlert(error: $sceneState.alertError, log: $sceneState.showLog)
        .toolbar {
            ExportSongView(label: "Export as PDF")
            QuickLookView(document: document)
        }
        .sheet(isPresented: $sceneState.showLog) {
            LogView()
        }
        .environmentObject(sceneState)
        /// Give the application access to the scene.
        .focusedSceneValue(\.sceneState, sceneState)
    }
}

///  Work-around the smart quote issue
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}
