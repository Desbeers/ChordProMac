//
//  ExportSongView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 26/05/2024.
//

import SwiftUI

/// SwiftUI `View` for an export button
struct ExportSongView: View {
    /// The label for the button
    let label: String
    /// The document
    @FocusedValue(\.document) private var document: FileDocumentConfiguration<ChordProDocument>?
    /// Present an export dialog
    @State private var exportFile = false
    /// The song as PDF
    @State private var pdf: Data?
    /// The body of the `View`
    var body: some View {
        Button(action: {
            if let document {
                Task {
                    pdf = try? await Terminal.exportDocument(document: document.document).data
                    exportFile = true
                }
            }
        }, label: {
            Text(label)
        })
        .fileExporter(
            isPresented: $exportFile,
            document: ExportDocument(pdf: pdf),
            contentType: .pdf,
            defaultFilename: document?.fileURL?.deletingPathExtension().lastPathComponent ?? "Export")
        { result in
            print("Done")
        }

    }
}
