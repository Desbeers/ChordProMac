//
//  FileListItem.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 14/09/2024.
//

import Foundation

struct FileListItem: Identifiable {
    let id = UUID()
    let url: URL
    var enabled: Bool
}
