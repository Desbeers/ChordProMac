//
//  DebugVieew.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 17/09/2024.
//

import SwiftUI

enum DebugView {
    // Just a placeholder
}

extension DebugView {
    /// SwiftUI `View` with debug buttons
    public struct ResetApplicationButtonView: View {
        /// Init the `View`
        public init() {}
        /// The scene state in the environment
        @FocusedValue(\.sceneState) private var sceneState: SceneStateModel?
        /// The body of the `View`
        public var body: some View {
            Button(
                action: {
                    /// Remove user defaults
                    if let bundleID = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: bundleID)
                    }
                    /// Delete the settings
                    try? Cache.delete(key: "ChordProMacSettings")
                    /// Terminate the application
                    NSApp.terminate(nil)
                },
                label: {
                    Text("Reset Application")
                }
            )
            Button(
                action: {
                    if let sceneState {
                        NSWorkspace.shared.open(sceneState.temporaryDirectoryURL)
                    }
                },
                label: {
                    Text("Open temporary folder")
                }
            )
            .disabled(sceneState == nil)
        }
    }
}
