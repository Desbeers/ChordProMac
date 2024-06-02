//
//  AppState.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import Foundation

/// The observable state of the application
final class AppState: ObservableObject {
    /// An error that can happen
    @Published var alertError: Error?
    /// Bool to show the log of the last **ChordPro** output
    @Published var showLog: Bool = false
    /// All the settings for the application
    @Published var settings: AppSettings {
        didSet {
            try? AppSettings.save(settings: settings)
        }
    }
    /// Init the class; get application settings
    init() {
        self.settings = AppSettings.load()
    }
    /// The URL of the log file
    static let logFileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("LatestLog", conformingTo: .plainText)
}
