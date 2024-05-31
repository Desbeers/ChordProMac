//
//  Notation.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 28/05/2024.
//

import Foundation

/// A notation we found in the official **ChordPro** source
struct Notation: Identifiable {
    var id: URL {
        url
    }
    let url: URL
    var label: String {
        let label = self.url.deletingPathExtension()
        return label.lastPathComponent
    }
    var description: String {
        switch label {
        case "common":
            return "C, D, E, F, G, A, B"
        case "dutch":
            return "C, D, E, F, G, A, B"
        case "german":
            return "C, ... A, Ais/B, H"
        case "latin":
            return "Do, Re, Mi, Fa, Sol, ..."
        case "scandinavian":
            return "C, ... A, A#/Bb, H"
        case "solfege":
            return "Do, Re, Mi, Fa, So, ..."
        case "solfège":
            return "Do, Re, Mi, Fa, So, ..."
        case "nashville":
            return "1, 2, 3, ..."
        case "roman":
            return "I, II, III, ..."
        default:
            return "Unknown notation"
        }
    }
}
