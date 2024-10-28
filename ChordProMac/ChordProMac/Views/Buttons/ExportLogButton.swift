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
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The body of the `View`
    var body: some View {
        Button(
            action: {
                sceneState.exportLogDialog = true
            },
            label: {
                Text(label)
            }
        )
        Button(
            action: {
                sceneState.logMessages = [.init()]
            },
            label: {
                Text("Clear the Message Area")
            }
        )
        Divider()
        Button(
            action: {
                insertChordProInfo()
            },
            label: {
                Text("Insert Runtime Information")
            }
        )
    }
}

extension ExportLogButton {

    func insertChordProInfo() {
        if let chordProInfo = appState.chordProInfo {
            dump(chordProInfo)
            var text =
"""
ChordPro Preview Editor version \(chordProInfo.general.chordpro.version)
https://www.chordpro.org
Copyright 2016,2024 Johan Vromans <jvromans@squirrel.nl>

Mac GUI written in SwiftUI

**Run-time information:**
 ChordProCore:
    \(chordProInfo.general.chordpro.version) (\(chordProInfo.general.chordpro.aux))
  Perl:
    \(chordProInfo.general.abc) (\(chordProInfo.general.perl.path))
  Resource path:

"""
            for resource in chordProInfo.resources {
                text += "    \(resource.path)\n"
            }

            text +=
"""
  ABC support:
    \(chordProInfo.general.abc)

**Modules and libraries:**

"""
            for module in chordProInfo.modules {
                text += "    \(module.name)"
                text += String(repeating: " ", count: 22 - module.name.count)
                text += "\(module.version)\n"
            }
            sceneState.logMessages.append(.init(type: .notice, message: text))
        }
    }
}
