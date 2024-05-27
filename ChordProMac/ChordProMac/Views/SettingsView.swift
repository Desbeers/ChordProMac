//
//  SettingsView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import SwiftUI

struct SettingsView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The body of the `View`
    var body: some View {
        TabView {
            editor
                .tabItem {
                    Label("Editor", systemImage: "text.word.spacing")
                }
        }
        .formStyle(.grouped)
    }
}

extension SettingsView {
    /// SwiftUI `View` with editor settings
    var editor: some View {
        Form {
            Section("Font") {
                Picker("The font size of the editor", selection: $appState.settings.fontSize) {
                    ForEach(12...24, id: \.self) { value in
                        Text("\(value)px")
                            .tag(Double(value))
                    }
                }
            }
        }
    }
}
