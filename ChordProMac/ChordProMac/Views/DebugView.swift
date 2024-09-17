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

    /// SwiftUI `View` with a `Button` to reset the application
    public struct ResetApplicationButtonView: View {
        /// Init the `View`
        public init() {}

        /// The scene state in the environment
        @FocusedValue(\.sceneState) private var sceneState: SceneState?

        /// The body of the `View`
        public var body: some View {
            Button(
                action: {
                    /// Remove user defaults
                    if let bundleID = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: bundleID)
                    }
                    /// Delete the cache
                    let manager = FileManager.default
                    if let cacheFolderURL = manager.urls(
                        for: .cachesDirectory,
                        in: .userDomainMask
                    ).first {
                        try? manager.removeItem(at: cacheFolderURL)
                        try? manager.createDirectory(
                            at: cacheFolderURL,
                            withIntermediateDirectories: false,
                            attributes: nil
                        )
                    }
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
                    Text("Open TMP folder")
                }
            )
            .disabled(sceneState == nil)
        }
    }
}
