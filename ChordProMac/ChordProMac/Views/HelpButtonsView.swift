//
//  HelpButtonsView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 01/06/2024.
//

import SwiftUI

/// SwiftUI buttons for the main `help` menu
struct HelpButtonsView: View {
    /// The body of te `View`
    var body: some View {
        if let url = URL(string: "https://www.chordpro.org/chordpro/") {
            Link(destination: url) {
                Text("ChordPro file format")
            }
        }
        if let url = URL(string: "https://groups.io/g/ChordPro") {
            Link(destination: url) {
                Text("ChordPro community")
            }
        }
        Divider()
        if let url = URL(string: "https://github.com/ChordPro/chordpro") {
            Link(destination: url) {
                Text("ChordPro on GitHub")
            }
        }
    }
}
