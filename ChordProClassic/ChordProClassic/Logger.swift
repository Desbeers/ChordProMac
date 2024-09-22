//
//  Logger.swift
//  ChordProClassic
//
//  Created by Nick Berendsen on 22/09/2024.
//

import Foundation
import OSLog

/// Messages for the Logger
public extension Logger {

    /// The name of the subsystem
    private static let subsystem = "Classic"
    /// Log application messages
    static var application: Logger {
        Logger(subsystem: subsystem, category: "Application")
    }
}
