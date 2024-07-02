//
//  ShareButtonView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/07/2024.
//

import SwiftUI
import ChordProShared


struct ShareButtonView: View {
    /// Binding to the current document
    let document: ChordProDocument
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// Bool to show the share picker
    @State private var showSharePicker: Bool = false
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                Task {
                    do {
                        _ = try await Terminal.exportDocument(
                            text: document.text,
                            settings: appState.settings,
                            sceneState: sceneState
                        )
                        showSharePicker = true
                    } catch {
                        /// Show an `Alert`
                        sceneState.alertError = error
                    }
                }
            },
            label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        )
        .help("Share the PDF")
        .background(
            SharingPickerView(
                isPresented: $showSharePicker,
                url: sceneState.exportURL
            )
        )
    }
}
