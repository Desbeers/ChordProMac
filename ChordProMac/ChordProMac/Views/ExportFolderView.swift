//
//  ExportFolderView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 05/09/2024.
//

import SwiftUI
import OSLog

struct ExportFolderView: View {

    /// The observable state of the delegate
    @EnvironmentObject private var appDelegate: AppDelegate

    /// The observable state of the scene
    @StateObject private var sceneState = SceneState()

    @State private var title: String = "My Songs"

    @State private var subtitle: String = "ChordPro"

    /// Present an export dialog
    @State private var exportFolderDialog = false
    /// The song as PDF
    @State private var pdf: Data?

    @State private var chordProRunning: Bool = false

    /// The current selected folder
    @State private var currentFolder: String? = ExportFolderView.exportFolderTitle
    var body: some View {
        ScrollView {
            VStack {
                VStack (alignment: .leading) {
                    Text("Create a PDF songbook with all the songs in a folder using your current settings.")

                    Label(
                        title: { Text("The songs will be ordered in the songbook by the name of your files.").font(.caption) },
                        icon: { Image(systemName: "info.circle.fill") }
                    )

//Label("The songs will be ordered in the songbook by the name of your files.", systemImage: "info.circle.fill")
                    //Text("The songs will be ordered in the songbook by the name of your files.")
//                        .font(.caption)
                        .padding([.horizontal, .top])
                }
                .padding(.horizontal)
                VStack {
                    UserFileButtonView(userFile: UserFileItem.exportFolder, action: {
                        currentFolder = ExportFolderView.exportFolderTitle
                    })
                }
                .wrapSettingsSection(title: "The folder with your songs")
                VStack {
                    Text("The title of the songbook:")
                        .font(.headline)
                    TextField(text: $title, prompt: Text("My songbook")) {
                        Text("Label")
                    }
//                    Text("This name will be used as suggestion for your file name.")
//                        .font(.caption)
//                        .padding(.bottom)
                    Text("The author of the songbook:")
                        .font(.headline)
                    TextField(text: $subtitle, prompt: Text("My name")) {
                        Text("Label")
                    }
                    Text("This is you by default.")
                        .font(.caption)
                }
                .wrapSettingsSection(title: "The front page")
                Button(action: {
                    makeSongbook()
                }, label: {
                    Text("Make songbook")
                })
                .padding(.top)
            }
            .padding(.top)
            .disabled(currentFolder == nil || title.isEmpty || chordProRunning)
        }
        .frame(width: 300, height: 460, alignment: .top)
        .overlay {
            ProgressView()
                .opacity(chordProRunning ? 1 : 0)
        }

        .sheet(isPresented: $sceneState.showLog) {
            LogView()
        }
        .task {
            subtitle = NSFullUserName()
        }
        .errorAlert(error: $sceneState.alertError, log: $sceneState.showLog)
        .fileExporter(
            isPresented: $exportFolderDialog,
            document: ExportDocument(pdf: pdf),
            contentType: .pdf,
            // swiftlint:disable:next line_length
            defaultFilename: title
        ) { _ in
            Logger.pdfBuild.notice("Export completed")
        }
        .environmentObject(sceneState)
    }

    @MainActor private func makeSongbook() {

        chordProRunning = true

        /// Create the TOC

        var text: [String] = ["{title: " + title + "}"]
        text.append("{subtitle: " + subtitle + "}")
        text.append("{+pdf.fonts.title.size:40}")
        text.append("{+pdf.fonts.subtitle.size:20}")
        text.append("{+pdf.margintop:100}")
        if let coverImage = Bundle.main.url(forResource: "/lib/ChordPro/res/icons/chordpro-icon.png", withExtension: nil) {
            let coverURL = sceneState.temporaryDirectoryURL.appendingPathComponent("SongBook", conformingTo: .png)
            try? FileManager.default.copyItem(at: coverImage, to: coverURL)
            text.append("{image anchor=\"page\" x=\"50%\" y=\"50%\" scale=\"100%\" src=\"" + coverURL.path + "\"}")
        }
        text.append("{new_page}")

        /// Create json config
        if let json = Bundle.main.url(forResource: "SongBook/SongBook.json", withExtension: nil) {

            do {
                let content = try String(contentsOf: json, encoding: .utf8)
                let replaced = content.replacingOccurrences(of: "TEMPLATEPATH", with: sceneState.sourceURL.path)
                try replaced.write(to: sceneState.configURL, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                Logger.application.error("\(error.localizedDescription, privacy: .public)")
            }

        }

        var songsURL: [String] = []

        if let songsFolder = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder) {
            /// Get access to the URL
            _ = songsFolder.startAccessingSecurityScopedResource()
            if
                let items = FileManager.default.enumerator(at: songsFolder, includingPropertiesForKeys: nil) {
                while let item = items.nextObject() as? URL {
                    if ChordProDocument.fileExtension.contains(item.pathExtension) {
                        songsURL.append(item.path)
                    }
                }
            }
            /// Close access to the URL
            songsFolder.stopAccessingSecurityScopedResource()
        }

        do {
            try songsURL.sorted().joined(separator: "\n").write(to: sceneState.songListURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("ERROR WRITING SONG LIST")
        }

        Task {
            do {
                /// Create the PDF with **ChordPro**
                let pdf = try await Terminal.exportDocument(
                    text: text.joined(separator: "\n"),
                    settings: AppSettings.load(),
                    sceneState: sceneState,
                    songList: true
                )
                /// Set the PDF as Data
                self.pdf = pdf.data
                /// Show the export dialog
                exportFolderDialog = true
                /// The PDF is not outdated
                sceneState.preview.outdated = false
                /// Set the status
                sceneState.exportStatus = pdf.status
            } catch {
                print(error)
                /// Show an error
                sceneState.alertError = error
                /// Set the status
                sceneState.exportStatus = .pdfCreationError
            }
            chordProRunning = false
        }
    }



    /// Get the current selected export folder
    private static var exportFolderTitle: String? {
        UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder)?.lastPathComponent
    }
}
