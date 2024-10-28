//
//  LogView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI
import OSLog

/// SwiftUI `View to show the latest log`
struct LogView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppStateModel
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneStateModel
    /// The body of the `View`
    var body: some View {
        ScrollView {
            ScrollViewReader { value in
                ForEach(sceneState.logMessages) { log in
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.bubble")
                            .foregroundStyle(log.type.color)
                        Divider()
                        Text(log.time.formatted(.dateTime))
                        Divider()
                        if let lineNumber = log.lineNumber {
                            Text("**Line \(lineNumber):**")
                        }
                        Text(.init(log.message))
                    }
                    .padding([.horizontal], 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                /// Just use this as anchor point to keep the scrollview at the bottom
                Divider()
                    .opacity(0)
                    .id(1)
                    .onChange(of: sceneState.logMessages) { _ in
                        value.scrollTo(1)
                    }
            }
        }
        .font(.monospaced(.body)())
        .background(Color(nsColor: .textBackgroundColor))
        .border(Color.secondary)
        .fileExporter(
            isPresented: $sceneState.exportLogDialog,
            document: LogDocument(log: sceneState.logMessages.map { item -> String in
                return "\(item.time): \(item.message)"
            } .joined(separator: "\n")),
            contentType: .plainText,
            defaultFilename: "ChordPro Messages \(Date.now.formatted())"
        ) { _ in
            Logger.pdfBuild.notice("Export log completed")
        }
        .contextMenu {
            ExportLogButton(label: "Export Messages")
        }
        .padding()
    }
}
