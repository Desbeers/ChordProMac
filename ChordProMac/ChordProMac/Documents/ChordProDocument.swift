//
//  ChordProDocument.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI
import UniformTypeIdentifiers

//extension UTType {
//    /// Define the UTType for a **ChordPro** song
//    static var chordProSong: UTType {
//        UTType(importedAs: "org.chordpro")
//    }
//}

/// Define the  **ChordPro** document
struct ChordProDocument: FileDocument {
    /// The UTType of the song
    static var readableContentTypes: [UTType] { [.chordProSong] }
    /// The text of the song
    var text: String
    /// Init the song
    init(text: String = "{title: New Song}\n") {
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
            let string = String(data: data, encoding: .utf8)
        else {
            throw AppError.readDocumentError
        }
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
