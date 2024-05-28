//
//  SettingsView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The tempplates we found in the official **ChordPro** source
    @State var templates: [Template] = []
    /// The body of the `View`
    var body: some View {
        TabView {
            editor
                .tabItem {
                    Label("Editor", systemImage: "text.word.spacing")
                }
            configuration
                .tabItem {
                    Label("Configuration", systemImage: "filemenu.and.selection")
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

extension SettingsView {
    /// SwiftUI `View` with configuration settings
    var configuration: some View {
        Form {
            Section("The configuration to use for your PDF") {
                Picker("The configuration to use", selection: $appState.settings.template) {
                    ForEach(templates) { template in
                        Text(template.label)
                            .tag(template.label)
                    }
                }
            }
            .labelsHidden()
            Section("Transpose") {
                HStack {
                    Picker("From", selection: $appState.settings.transposeFrom) {
                        ForEach(Note.allCases, id: \.self) { note in
                            Text(note.rawValue)
                        }
                    }
                    Picker("To", selection: $appState.settings.transposeTo) {
                        ForEach(Note.allCases, id: \.self) { note in
                            Text(note.rawValue)
                        }
                    }
                }
                    Picker("Accents", selection: $appState.settings.transposeAccents) {
                        ForEach(Accents.allCases, id: \.self) { accents in
                            Text(accents.rawValue)
                        }
                    }
            }
        }
        .task {
            var templates: [Template] = []
            guard
                let templateFolder = Bundle.main.url(forResource: "lib/ChordPro/res/config", withExtension: nil),
                let items = FileManager.default.enumerator(at: templateFolder, includingPropertiesForKeys: nil)
            else {
                return
            }
            while let template = items.nextObject() as? URL {
                if template.pathExtension == UTType.json.preferredFilenameExtension ?? ".json", !template.absoluteString.contains("notes") {
                    templates.append(Template(url: template))
                }
            }
            self.templates = templates
        }
    }
}
