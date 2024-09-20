//
//  WelcomeView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 20/09/2024.
//

import SwiftUI
import OSLog

struct WelcomeView: View {
    /// The observable state of the application
    @StateObject private var appState = AppStateModel.shared
    /// The AppDelegate to bring additional Windows into the SwiftUI world
    let appDelegate: AppDelegateModel
    /// The selected tab
    @State private var selectedTab: NewTabs = .create
    /// The body of the `View`
    var body: some View {
        HStack {
            Image("ChordProLogo")
                .resizable()
                .scaledToFit()
                .padding()
                .frame(maxWidth: .infinity)
                .padding(.bottom)
            VStack {
                VStack {
                    switch selectedTab {
                    case .create:
                        Button(
                            action: {
                                appState.newDocumentContent = ChordProDocument.newText
                                NSDocumentController.shared.newDocument(nil)
                            },
                            label: {
                                Label("Create a new song", systemImage: "doc")
                            }
                        )
                        Button(
                            action: {
                                Task {
                                    if let urls = await NSDocumentController.shared.beginOpenPanel() {
                                        for url in urls {
                                            do {
                                                try await NSDocumentController.shared.openDocument(withContentsOf: url, display: true)
                                            } catch {
                                                Logger.application.error("Error opening URL: \(error.localizedDescription, privacy: .public)")
                                            }
                                        }
                                    }
                                }
                            },
                            label: {
                                Label("Open an existing song", systemImage: "doc.badge.ellipsis")
                            }
                        )
                        Button(
                            action: {
                                appDelegate.closeWelcomeWindow()
                                appDelegate.showExportSongbookWindow()
                            },
                            label: {
                                Label("Make a songbook", systemImage: "doc.on.doc")
                            }
                        )
                        Button(
                            action: {
                                if let sampleSong = Bundle.main.url(forResource: "lib/ChordPro/res/examples/swinglow.cho", withExtension: nil) {
                                    let content = try? String(contentsOf: sampleSong, encoding: .utf8)
                                    appState.newDocumentContent = content ?? ChordProDocument.newText
                                    NSDocumentController.shared.newDocument(nil)
                                }
                            },
                            label: {
                                Label("Open an example song", systemImage: "doc.text")
                            }
                        )
                    case .recent:
                        if appState.recentFiles.isEmpty {
                            Text("You have no recent songs")
                        } else {
                            ScrollView {
                                ForEach(appState.recentFiles, id: \.self) { url in
                                    Button(
                                        action: {
                                            Task {
                                                do {
                                                    try await NSDocumentController.shared.openDocument(withContentsOf: url, display: true)
                                                } catch {
                                                    Logger.application.error("Error opening URL: \(error.localizedDescription, privacy: .public)")
                                                }
                                            }
                                        },
                                        label: {
                                            Label(url.deletingPathExtension().lastPathComponent, systemImage: "doc.badge.clock")
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                Divider()
                    .frame(width: 240)
                    .padding()
                if let url = URL(string: "https://www.chordpro.org/") {
                    Link(destination: url) {
                        Label("Visit the **ChordPro** website", systemImage: "globe")
                    }
                }
                if let url = URL(string: "https://www.chordpro.org/chordpro") {
                    Link(destination: url) {
                        Label("Read the documentation", systemImage: "book")
                    }
                }
            }
            .padding()
            .frame(maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
        }
        .animation(.default, value: selectedTab)
        .labelStyle(ButtonLabelStyle())
        .buttonStyle(.plain)
        .frame(width: 580)
        .toolbar {
            Picker("Tabs", selection: $selectedTab) {
                ForEach(NewTabs.allCases) { tab in
                    Text(tab.rawValue)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

extension WelcomeView {
    enum NewTabs: String, CaseIterable, Identifiable {
        var id: String {
            self.rawValue
        }
        case create = "Create"
        case recent = "Recent"
    }
}

extension WelcomeView {

    /// The style of a label on the Welcome View
    struct ButtonLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.icon
                    .foregroundColor(.secondary)
                    .imageScale(.large)
                configuration.title
                    .padding(.trailing)
                    .frame(width: 220, height: 40, alignment: .leading)
            }
            .padding(.leading)
            .background(.thinMaterial)
            .cornerRadius(6)
        }
    }
}
