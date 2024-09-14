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

    @State private var fileList: [FileListItem] = []

    @State private var addCoverPage: Bool = true

    /// The current selected folder
    @State private var currentFolder: String? = ExportFolderView.exportFolderTitle
    var body: some View {
        HStack {
            ScrollView {
                VStack {
                    VStack (alignment: .leading) {
                        Text("Create a PDF songbook with all the songs in a folder using your current settings.")
                        .padding([.horizontal, .top])
                    }
                    .padding(.horizontal)
                    VStack {
                        UserFileButtonView(userFile: UserFileItem.exportFolder, action: {
                            currentFolder = ExportFolderView.exportFolderTitle
                            makeFileList()
                        })
                    }
                    .wrapSettingsSection(title: "The folder with your songs")
                    VStack {
                        Toggle(isOn: $addCoverPage, label: {
                            Text("Add a standard cover page")
                        })
                        Group {
                            Text("The title of the songbook:")
                                .font(.headline)
                            TextField(text: $title, prompt: Text("My songbook")) {
                                Text("Label")
                            }
                            Text("The author of the songbook:")
                                .font(.headline)
                            TextField(text: $subtitle, prompt: Text("My name")) {
                                Text("Label")
                            }
                            Text("This is you by default.")
                                .font(.caption)
                        }
                        .disabled(!addCoverPage)
                    }
                    .wrapSettingsSection(title: "The front page")
                    Button(action: {
                        makeSongbook()
                    }, label: {
                        Text("Make songbook")
                    })
                    .padding(.top)
                    .disabled(currentFolder == nil || title.isEmpty)
                }
                .padding(.top)
                .disabled(chordProRunning)
            }
            VStack {
                List {
                    ForEach($fileList) { $item in
                        HStack {
                            Toggle(isOn: $item.enabled, label: {
                                Text("Enable")
                            })
                            .labelsHidden()
                            Text(item.url.lastPathComponent)
                        }
                    }
                    .onMove { from, to in
                        fileList.move(fromOffsets: from, toOffset: to)
                    }
                }
                .overlay {
                    if fileList.isEmpty {
                        Text("Select a folder to view its content here.")
                    }
                }
                Label(
                    title: { Text("You can reorder the songs by drag and drop.").font(.caption) },
                    icon: { Image(systemName: "info.circle.fill") }
                )
                .padding()
            }
        }
        .frame(width: 600, height: 460, alignment: .top)
        .overlay {
            ProgressView()
                .opacity(chordProRunning ? 1 : 0)
        }
        .toolbar {
            Spacer()
        }
        //.navigationSubtitle("Create a PDF songbook with all the songs in a folder using your current settings.")
        .sheet(isPresented: $sceneState.showLog) {
            LogView()
        }
        .task {
            subtitle = NSFullUserName()
            makeFileList()
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

    @MainActor private func makeFileList() {
        fileList = []

        if let songsFolder = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder) {
            /// Get access to the URL
            _ = songsFolder.startAccessingSecurityScopedResource()
            if
                let items = FileManager.default.enumerator(at: songsFolder, includingPropertiesForKeys: nil) {
                while let item = items.nextObject() as? URL {
                    if ChordProDocument.fileExtension.contains(item.pathExtension) {
                        fileList.append(.init(url: item, enabled: true))
                    }
                }
            }
            /// Close access to the URL
            songsFolder.stopAccessingSecurityScopedResource()
        }
        fileList.sort {$0.url.path < $1.url.path}
    }

    @MainActor private func makeSongbook() {

        chordProRunning = true

        /// Create the cover page

        var text: [String] = ["{title: " + title + "}"]
        text.append("{subtitle: " + subtitle + "}")
        text.append("{+pdf.fonts.title.size:40}")
        text.append("{+pdf.fonts.subtitle.size:20}")

        text.append("{+pdf.margintop:100}")

        text.append("{+pdf.formats.first.title:[ \"\" \"%{title}\" \"\" ]}")
        text.append("{+pdf.formats.first.subtitle:[ \"\" \"%{subtitle}\" \"\" ]}")

        text.append("{+pdf.formats.first.footer:[ \"Created with ChordPro\" \"\" \"https://www.chordpro.org\" ]}")
        if let coverImage = Bundle.main.url(forResource: "/lib/ChordPro/res/icons/chordpro-icon.png", withExtension: nil) {
            text.append("{image anchor=\"page\" x=\"50%\" y=\"50%\" scale=\"100%\" src=\"" + coverImage.path + "\"}")
        }

        var songsURL: [String] = []

        //fileList = []

        if let songsFolder = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder) {
            /// Get access to the URL
            _ = songsFolder.startAccessingSecurityScopedResource()
            songsURL = fileList.filter {$0.enabled == true}.map(\.url.path)
            /// Close access to the URL
            songsFolder.stopAccessingSecurityScopedResource()
        }

        do {
            try songsURL.joined(separator: "\n").write(to: sceneState.fileListURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("ERROR WRITING SONG LIST")
        }

        Task {
            do {
                /// Create the cover PDF with **ChordPro**
                _ = try await Terminal.exportDocument(
                    text: text.joined(separator: "\n"),
                    settings: AppSettings.load(),
                    sceneState: sceneState,
                    cover: true
                )

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
