//
//  FontStyle.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI

enum FontStyle: String, CaseIterable, Codable {
    case monospaced = "Monospaced"
    case serif = "Serif"
    case sansSerif = "Sans Serif"

    func font(size: Double) -> Font {
        switch self {
        case .monospaced:
            return .system(size: size, weight: .regular, design: .monospaced)
        case .serif:
            return .system(size: size, weight: .regular, design: .serif)
        case .sansSerif:
            return .system(size: size, weight: .regular, design: .default)
        }
    }
}
