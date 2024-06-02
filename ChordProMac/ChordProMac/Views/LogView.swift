//
//  LogView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI

/// SwiftUI `View to show the latest log`
struct LogView: View {
    /// The observable state of the application
    @EnvironmentObject private var appState: AppState
    /// The observable state of the scene
    @EnvironmentObject private var sceneState: SceneState
    /// Get the latest log
    var log: [String] {
        do {
            return try String(contentsOf: sceneState.logFileURL, encoding: .utf8).components(separatedBy: .newlines)
        } catch {
            /// There is no log
            return ["There is no log available"]
        }
    }
    /// The body of the `View`
    var body: some View {
        VStack {
            Text("Log")
                .font(.title)
            ScrollView {
                ForEach(log, id: \.self) { logLine in
                    HStack {
                        Image(systemName: "pencil.line")
                        Text(logLine)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Button("Close") {
                sceneState.showLog = false
            }
        }
        .frame(width: 500, height: 500)
        .padding()
    }
}
