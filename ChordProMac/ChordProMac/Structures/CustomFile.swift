//
//  CustomFile.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import Foundation
import UniformTypeIdentifiers

enum CustomFile: String {
    case customConfig
    case customLibrary
    case customSongTemplate

    var utType: UTType {
        switch self {
        case .customConfig:
            return UTType.json
        case .customLibrary:
            return UTType.folder
        case .customSongTemplate:
            return UTType.chordProSong
        }
    }

    var label: String? {
        return try? FileBookmark.getBookmarkURL(self)?.lastPathComponent
    }

    var icon: String {
        switch self {
        case .customConfig:
            return "gear"
        case .customLibrary:
            return "building.columns"
        case .customSongTemplate:
            return "music.note.list"
        }
    }
}
