//
//  ExportFolderView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 05/09/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import OSLog

struct ExportFolderView: View {

    /// The observable state of the application
    @StateObject private var appState = AppState.shared

    /// The observable state of the delegate
    @EnvironmentObject private var appDelegate: AppDelegate

    /// The observable state of the scene
    @StateObject private var sceneState = SceneState()

    /// Present an export dialog
    @State private var exportFolderDialog = false
    /// The songbook as PDF
    @State private var pdf: Data?

    @State private var chordProRunning: Bool = false

    @State private var coverPreview: URL?

    /// Bool if the dropping is in progress
    @State private var isDropping = false

    /// The current selected folder
    @State private var currentFolder: String? = ExportFolderView.exportFolderTitle
    
    /// The current selected cover
    @State private var currentCover: String? = ExportFolderView.exportCoverTitle

    var body: some View {
        VStack {
            HStack {
                VStack {
                    List {
                        ForEach($appState.settings.application.fileList) { $item in
                            HStack {
                                Toggle(isOn: $item.enabled, label: {
                                    Text("Enable")
                                })
                                .labelsHidden()
                                Text(item.url.deletingPathExtension().lastPathComponent)
                            }
                        }
                        .onMove { from, to in
                            appState.settings.application.fileList.move(fromOffsets: from, toOffset: to)
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                    .overlay {
                        if appState.settings.application.fileList.isEmpty {
                            Text("Drop a folder with your **ChordPro** files here to view its content and to make a Songbook.")
                                .multilineTextAlignment(.center)
                                .wrapSettingsSection(title: "File List")
                        }
                    }
                    Label(
                        title: { Text("You can reorder the songs by drag and drop.") },
                        icon: { Image(systemName: "info.circle.fill") }
                    )
                    .font(.caption)
                    //.padding()
                }

                ScrollView {
                    VStack {
                        VStack {
                            UserFileButtonView(userFile: UserFileItem.exportFolder, action: {
                                currentFolder = ExportFolderView.exportFolderTitle
                                makeFileList()
                            })
                            .id(currentFolder)
                            Text(.init(songCountLabel))
                                .font(.caption)
                        }
                        .wrapSettingsSection(title: "The folder with your songs")
                        VStack {
                            Toggle(isOn: $appState.settings.application.songbookGenerateCover, label: {
                                Text("Add a standard cover page")
                            })
                            .padding(.bottom)
                            Group {
                                HStack {
                                    Text("Title:")
                                        .frame(width: 60, alignment: .trailing)
                                        .font(.headline)
                                    TextField(text: $appState.settings.application.songbookTitle, prompt: Text("My songbook")) {
                                        Text("Label")
                                    }
                                }
                                HStack {
                                    Text("Subtitle:")
                                        .frame(width: 60, alignment: .trailing)
                                        .font(.headline)
                                    TextField(text: $appState.settings.application.songbookSubtitle, prompt: Text("My name")) {
                                        Text("Label")
                                    }
                                }
                            }
                            .disabled(!appState.settings.application.songbookGenerateCover)
                            .foregroundColor(appState.settings.application.songbookGenerateCover ? .primary : .secondary)
                            Group {
                                Toggle(isOn: $appState.settings.application.songbookUseCustomCover, label: {
                                    Text("Use a custom PDF cover")
                                })
                                .padding()
                                HStack {
                                    UserFileButtonView(userFile: UserFileItem.songbookCover, action: {
                                        currentCover = ExportFolderView.exportCoverTitle
                                        //makeFileList()
                                    })
                                    if let url = UserFileBookmark.getBookmarkURL(UserFileItem.songbookCover) {
                                        Button(action: {
                                            coverPreview = url
                                        }, label: {
                                            
                                            Image(systemName: "eye")
                                        })
                                    }
                                }
                                .disabled(!appState.settings.application.songbookUseCustomCover)
                            }

                        }
                        .wrapSettingsSection(title: "The front page")
                        Button(action: {
                            makeSongbook()
                        }, label: {
                            Text("Export Songbook")
                        })
                        .padding(.top)
                        .disabled(currentFolder == nil || appState.settings.application.songbookTitle.isEmpty)
                    }
                    //.padding(.top)
                    .disabled(chordProRunning)
                }
            }
            Divider()
            StatusView()
                .padding(.horizontal)
        }
        .frame(width: 600, height: 460, alignment: .top)
        .overlay {
            VStack {
                ProgressView()
                Text("This might take some time...")
                    .font(.caption)
            }
            .padding()
            .background(.thinMaterial)
                .wrapSettingsSection(title: "Making the PDF")
                .opacity(chordProRunning ? 1 : 0)
        }
        .toolbar {
            Spacer()
        }
        .task(id: appState.settings.application.songbookGenerateCover) {
            if appState.settings.application.songbookGenerateCover {
                appState.settings.application.songbookUseCustomCover = false
            }
        }
        .task(id: appState.settings.application.songbookUseCustomCover) {
            if appState.settings.application.songbookUseCustomCover {
                appState.settings.application.songbookGenerateCover = false
            }
        }
        .onDrop(of: [.folder], isTargeted: $isDropping) { itemProvider in
            if let item = itemProvider.first {
                item.loadItem(forTypeIdentifier: UTType.folder.identifier, options: nil) { urlData, _ in
                    if let url = urlData as? URL {
                        Task {
                            UserFileBookmark.setBookmarkURL(UserFileItem.exportFolder, url)
                            currentFolder = url.lastPathComponent
                            makeFileList()
                        }
                    }
                }
            }
            return true
        }
        .fileExporter(
            isPresented: $exportFolderDialog,
            document: ExportDocument(pdf: pdf),
            contentType: .pdf,
            // swiftlint:disable:next line_length
            defaultFilename: appState.settings.application.songbookTitle
        ) { _ in
            Logger.pdfBuild.notice("Export completed")
        }
        .quickLookPreview($coverPreview)
        .environmentObject(appState)
        .environmentObject(sceneState)
    }

    @MainActor private func makeFileList() {
        var fileList: [FileListItem] = []

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
        appState.settings.application.fileList = fileList
    }

    @MainActor private func makeSongbook() {

        chordProRunning = true

        /// Create the cover page

        var text: [String] = ["{title: " + appState.settings.application.songbookTitle + "}"]
        text.append("{subtitle: " + appState.settings.application.songbookSubtitle + "}")
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
            songsURL = appState.settings.application.fileList.filter {$0.enabled == true}.map(\.url.path)
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
    /// Get the current selected export cover
    private static var exportCoverTitle: String? {
        UserFileBookmark.getBookmarkURL(UserFileItem.songbookCover)?.lastPathComponent
    }

    private var songCountLabel: String {
        let count = appState.settings.application.fileList.count
        switch count {
        case 0:
            return "Select a folder with your **ChordPro** songs"
        default:
            return "Found \(count) **ChordPro** songs in the folder"
        }
    }
}
