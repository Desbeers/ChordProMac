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
    /// The observable state of the scene
    @StateObject private var sceneState = SceneState()
    /// Present an export dialog
    @State private var exportFolderDialog = false
    /// The songbook as PDF
    @State private var pdf: Data?
    /// Bool if **ChordPro** is making the songbook
    @State private var chordProRunning: Bool = false
    /// Optional URL to show the custom cover in Quickview
    @State private var coverPreview: URL?
    /// Bool if the dropping is in progress
    @State private var isDropping = false
    /// The current selected folder
    @State private var currentFolder: String? = ExportFolderView.exportFolderTitle
    /// The current selected cover
    @State private var currentCover: String? = ExportFolderView.exportCoverTitle
    /// The body of the `View`
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
                        /// - Note: Monterey is screwing multi-line items when dragged/dropped
                        .onMove { fromOffsets, toOffset in
                            appState.settings.application.fileList.move(fromOffsets: fromOffsets, toOffset: toOffset)
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                    .border(Color.accentColor, width: isDropping ? 2 : 0)
                    .overlay {
                        if appState.settings.application.fileList.isEmpty {
                            Text("Drop a folder with your **ChordPro** files here to view its content and to make a Songbook.")
                                .multilineTextAlignment(.center)
                                .wrapSettingsSection(title: "File List")
                        }
                    }
                    Label(
                        title: { Text("You can reorder the songs by drag and drop") },
                        icon: { Image(systemName: "info.circle") }
                    )
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
                VStack {
                    ScrollView {

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
                        VStack(alignment: .leading) {
                            Toggle(isOn: $appState.settings.application.songbookGenerateCover, label: {
                                Text("Add a standard cover page")
                            })
                            .padding(.bottom)

                            if appState.settings.application.songbookGenerateCover {
                                VStack {
                                    HStack {
                                        Text("Title:")
                                            .frame(width: 60, alignment: .trailing)
                                            .font(.headline)
                                        TextField(
                                            text: $appState.settings.application.songbookTitle,
                                            prompt: Text("Title")
                                        ) {
                                            Text("Title")
                                        }
                                    }
                                    HStack {
                                        Text("Subtitle:")
                                            .frame(width: 60, alignment: .trailing)
                                            .font(.headline)
                                        TextField(
                                            text: $appState.settings.application.songbookSubtitle,
                                            prompt: Text("Subtitle")
                                        ) {
                                            Text("Subtitle")
                                        }
                                    }
                                }
                                .padding([.horizontal, .bottom])
                            }
                            Toggle(isOn: $appState.settings.application.songbookUseCustomCover, label: {
                                Text("Add a custom cover page")

                            })
                            if appState.settings.application.songbookUseCustomCover {
                                VStack {
                                    HStack {
                                        UserFileButtonView(userFile: UserFileItem.songbookCover) {
                                            currentCover = ExportFolderView.exportCoverTitle
                                        }
                                        if let url = UserFileBookmark.getBookmarkURL(UserFileItem.songbookCover) {
                                            Button(
                                                action: {
                                                    coverPreview = url
                                                },
                                                label: {
                                                    Image(systemName: "eye")
                                                }
                                            )
                                        }
                                    }
                                    .disabled(!appState.settings.application.songbookUseCustomCover)
                                    .id(currentCover)
                                    .padding()
                                    Text("Only a PDF can be used as a custom cover")
                                        .font(.caption)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .wrapSettingsSection(title: "The cover page")
                    }

                    .disabled(chordProRunning)
                    Button(action: {
                        makeSongbook()
                    }, label: {
                        Text("Export Songbook")
                    })
                    .padding(.top)
                    .disabled(currentFolder == nil || appState.settings.application.songbookTitle.isEmpty)
                }

            }
            Divider()
            StatusView()
                .padding(.horizontal)
        }
        .frame(width: 600, height: 460, alignment: .top)
        .animation(.default, value: appState.settings.application)
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
        .navigationSubtitle("All the songs in a single PDF")
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
        /// Start with a fresh list
        var songsURL: [String] = []
        /// Collect the songs
        if let songsFolder = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder) {
            /// Get access to the URL
            _ = songsFolder.startAccessingSecurityScopedResource()
            songsURL = appState.settings.application.fileList.filter {$0.enabled == true}.map(\.url.path)
            /// Close access to the URL
            songsFolder.stopAccessingSecurityScopedResource()
        }
        /// Write it to the file list
        do {
            try songsURL
                .joined(separator: "\n")
                .write(to: sceneState.fileListURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            Logger.fileAccess.error("Could not write the file list")
        }
        Task {
            do {
                /// Create the PDF with **ChordPro**
                let pdf = try await sceneState.exportPDF(
                    text: "",
                    songList: true,
                    title: appState.settings.application.songbookTitle,
                    subtitle: appState.settings.application.songbookSubtitle
                )
                /// Set the PDF as Data
                self.pdf = pdf.data
                /// Show the export dialog
                exportFolderDialog = true
            } catch {
                Logger.pdfBuild.error("\(error.localizedDescription, privacy: .public)")
            }
            chordProRunning = false
        }
    }
    /// Get the title of the current selected export folder
    private static var exportFolderTitle: String? {
        UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder)?.lastPathComponent
    }
    /// Get the current selected export cover
    private static var exportCoverTitle: String? {
        UserFileBookmark.getBookmarkURL(UserFileItem.songbookCover)?.lastPathComponent
    }
    /// Get the label for a song count
    private var songCountLabel: String {
        let count = appState.settings.application.fileList.count
        let folder = UserFileBookmark.getBookmarkURL(UserFileItem.exportFolder)
        switch count {
        case 0:
            return folder == nil ? "Select a folder with your **ChordPro** songs" : "There are no songs in this folder"
        default:
            return "Found \(count) **ChordPro** songs in this folder"
        }
    }
}
