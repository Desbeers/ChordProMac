//
//  ChordProDocument.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import ChordProShared

/// Define the  **ChordPro** document
struct ChordProDocument: FileDocument {
    /// The UTType of the song
    static var readableContentTypes: [UTType] { [.chordProSong] }
    /// The text of the song
    var text: String
    /// Init the song
    /// - Note: Make sure we have a minimum of 10 lines or else we have a crash on macOS Monterey
    init(text: String = "{title: New Song}\n\n\n\n\n\n\n\n\n") {
        let settings = AppSettings.load()
        /// Check if we have to use a custom template
        if
            settings.application.useCustomSongTemplate,
            let persistentURL = try? UserFileBookmark.getBookmarkURL(UserFileItem.customSongTemplate) {
            /// Get access to the URL
            _ = persistentURL.startAccessingSecurityScopedResource()
            let data = try? String(contentsOf: persistentURL, encoding: .utf8)
            self.text = data ?? text
            /// Stop access to the URL
            persistentURL.stopAccessingSecurityScopedResource()
        } else {
            self.text = text
        }
    }
    /// Black magic
    init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents,
            var string = String(data: data, encoding: .utf8)
        else {
            throw AppError.readDocumentError
        }
        /// Make sure we have a minimum of 10 lines or else we have a crash on macOS Monterey
        while string.components(separatedBy: "\n").count < 10 { string += "\n" }
        text = string
    }
    /// Save the song
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw AppError.writeDocumentError
        }
        return .init(regularFileWithContents: data)
    }
}

/// The `FocusedValueKey` for the current document
struct DocumentFocusedValueKey: FocusedValueKey {
    /// The `typealias` for the key
    typealias Value = FileDocumentConfiguration<ChordProDocument>
}

extension FocusedValues {
    /// The value of the document key
    var document: DocumentFocusedValueKey.Value? {
        get {
            self[DocumentFocusedValueKey.self]
        }
        set {
            self[DocumentFocusedValueKey.self] = newValue
        }
    }
}
