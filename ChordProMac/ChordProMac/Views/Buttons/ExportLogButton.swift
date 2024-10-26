//
//  ExportLogButton.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 02/06/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View` for an export log button
struct ExportLogButton: View {
    /// The label for the button
    let label: String
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// Present an export dialog
    @Binding var exportLogDialog: Bool
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                exportLogDialog = true
            },
            label: {
                Text(label)
            }
        )
    }
}
