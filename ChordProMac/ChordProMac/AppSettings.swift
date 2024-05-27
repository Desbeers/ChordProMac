//
//  AppSettings.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 27/05/2024.
//

import Foundation

struct AppSettings: Codable {
    /// The font size of the editor
    var fontSize: Double = 14
    /// The template to use
    var template: String = "guitar"
}

extension AppSettings {

    /// Load the application settings
    /// - Returns: The ``ChordProMacSettings``
    static func load() -> AppSettings {
        if let settings = try? Cache.get(key: "ChordProMacSettings", as: AppSettings.self) {
            return settings
        }
        /// No settings found; return defaults
        return AppSettings()
    }

    /// Save the application settings to the cache
    /// - Parameter settings: The ``AppSettings``
    static func save(settings: AppSettings) throws {
        do {
            try Cache.set(key: "ChordProMacSettings", object: settings)
        } catch {
            throw AppError.saveSettingsError
        }
    }
}
