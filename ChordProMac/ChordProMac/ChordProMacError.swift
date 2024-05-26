//
//  ChordProMacError.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import Foundation

/// All errors that can happen in the application
enum ChordProMacError: String, LocalizedError {
    /// A read error
    case readDocumentError
    /// A write error
    case writeDocumentError
}
