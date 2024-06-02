//
//  AppError.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import Foundation

/// All errors that can happen in the application
enum AppError: String, LocalizedError {
    /// A read error
    case readDocumentError
    /// A write error
    case writeDocumentError
    /// A settings error
    case saveSettingsError
    /// A binary error if **chordpro** is not found in the package
    case binaryNotFound
    /// An error when a custom file is not found
    case customFileNotFound
    /// An error when **chordpro** did not create a PDF
    case pdfCreationError
    /// An error when **chordpro** did  create a PDF but gave errors
    case pdfCreatedWithErrors
    /// Not an error, all is well
    /// - Note: Used for PDF export
    case noErrorOccurred

}

// MARK: Protocol implementations

extension AppError {

    /// The description of the error
    var errorDescription: String? {
        return "Something went wrong"
    }

    /// The recovery suggestion
    var recoverySuggestion: String? {
        switch self {
        case .pdfCreationError:
            return "ChordPro was unable to create a PDF"
        case .pdfCreatedWithErrors:
            return "There where warnings when creating the PDF"
        case .noErrorOccurred:
            return "All is well"
        default:
            ///  This should not happen
            return "ChordPro is sorry"
        }
    }
}
