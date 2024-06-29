//
//  UserFileButtonView.swift
//  ChordProShared
//
//  Created by Nick Berendsen on 26/06/2024.
//

import SwiftUI

/// SwiftUI `View`to select a file
///
/// I don't use the `SwiftUI` '.fileImporter' here because it is too limited;
/// especially on macOS versions lower than 14.
/// So, I just call a good o'l NSOpenPanel here.`
///
/// - Note: A file can be a *normal* file but also a folder
public struct UserFileButtonView<T: UserFile>: View {
    /// Public init
    public init(bookmark: T, action: @escaping () -> Void) {
        self.bookmark = bookmark
        self.action = action
    }
    /// The bookmark to select
    let bookmark: T
    /// The action when a file is selected
    let action: () -> Void
    /// The label of the button
    @State private var label: String?
    /// The body of the `View`
    public var body: some View {
        Button(
            action: {
                Task {
                    if let url = try? await Utils.openPanel(bookmark: bookmark, action: action) {
                        label = url.deletingPathExtension().lastPathComponent
                    }
                }
            },
            label: {
                Label(label ?? "Select", systemImage: bookmark.icon)
            }
        )
        .task {
            label = bookmark.label
        }
    }
}
