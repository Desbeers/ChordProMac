//
//  ChordProDocument.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// Define the UTType for a **ChordPro** song
    static var chordProSong: UTType {
        UTType(importedAs: "org.chordpro")
    }
}

/// Define the  **ChordPro** document
struct ChordProDocument: FileDocument {
    /// The text of the file
    var text: String
    /// Init the text
    init(text: String = "{title: New Song}") {
        let settings = AppSettings.load()
        /// Check if we have to use a custom template
        if
            settings.useCustomSongTemplate,
            let persistentURL = try? FileBookmark.getBookmarkURL(CustomFile.customSongTemplate) {
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
    /// The UTType of the file
    static var readableContentTypes: [UTType] { [.chordProSong] }
    /// Black magic
    init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents,
            let string = String(data: data, encoding: .utf8)
        else {
            throw AppError.readDocumentError
        }
        text = string
    }
    /// Save the file
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw AppError.writeDocumentError
        }
        return .init(regularFileWithContents: data)
    }
}
