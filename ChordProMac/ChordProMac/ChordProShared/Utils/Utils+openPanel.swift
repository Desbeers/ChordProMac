//
//  File.swift
//  
//
//  Created by Nick Berendsen on 28/06/2024.
//

import AppKit
import UniformTypeIdentifiers

extension Utils {

    @MainActor public static func openPanel<T: UserFile>(bookmark: T, action: @escaping () -> Void) async throws -> URL {
        /// Make sure we have a window to attach the sheet
        guard let window = NSApp.keyWindow else {
            throw AppError.noKeyWindow
        }
        let selection = try UserFileBookmark.getBookmarkURL(bookmark)
        let dialog = NSOpenPanel()
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = bookmark.utTypes.contains(UTType.folder) ? true : false
        dialog.allowedContentTypes = bookmark.utTypes
        dialog.directoryURL = selection
        dialog.message = bookmark.message
        dialog.prompt = "Select"
        dialog.canCreateDirectories = false
        let result = await dialog.beginSheetModal(for: window)
        /// Throw an error if no file is selected
        guard  result == .OK, let url = dialog.url else {
            throw AppError.noFolderSelected
        }
        /// Create a persistent bookmark for the file the user just selected
        UserFileBookmark.setBookmarkURL(bookmark, url)
        action()
        /// Return the selected url
        return url
    }

}
