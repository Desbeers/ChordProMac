//
//  FileListItem.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 14/09/2024.
//

import Foundation

struct FileListItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var url: URL
    var path: [String]
    var enabled: Bool
}
