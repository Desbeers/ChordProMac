//
//  MacEditorView+highlight.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 11/06/2024.
//

import AppKit

extension MacEditorView {
    /// The regex for chords
    static let chordRegex = try! NSRegularExpression(pattern: "\\[([\\w#b\\/]+)\\]", options: .caseInsensitive)
    /// The regex for directives
    static let directiveRegex = try! NSRegularExpression(pattern: "\\{.*\\}")
    /// The regex for comments
    static let commentsRegex = try! NSRegularExpression(pattern: "#.*\\s")



    /// Highlight the text in the editor
    /// - Parameters:
    ///   - text: The text
    ///   - font: The current `NSFont`
    /// - Returns: A highlighted text
    static func highlight(view: NSTextView, font: NSFont, range: NSRange) {

        //let typingAttributes = view.typingAttributes

        //let range = NSRange(location: range.location, length: range.length - 1)

        //let highlightedString = NSMutableAttributedString(string: text)
        //let all = NSRange(location: 0, length: text.utf16.count)

        let text = view.textStorage?.string ?? ""
        /// Make all text in the default style
        view.textStorage?.setAttributes(
            [
                .foregroundColor: NSColor.textColor,
                .font: font
            ], range: range)

        view.textStorage?.addAttribute(.font, value: font, range: range)
        view.textStorage?.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)

        let directives = directiveRegex.matches(in: text, options: [], range: range)
        directives.forEach { directive in
            view.textStorage?.addAttribute(
                .foregroundColor,
                value: NSColor.systemTeal,
                range: directive.range
            )
        }

        let chords = chordRegex.matches(in: text, options: [], range: range)
        chords.forEach { chord in
                view.textStorage?.addAttribute(
                    .foregroundColor,
                    value: NSColor.systemRed,
                    range: chord.range
                )
        }

        let comments = commentsRegex.matches(in: text, options: [], range: range)
        comments.forEach { comment in
            view.textStorage?.addAttribute(
                .foregroundColor,
                value: NSColor.systemGray,
                range: comment.range
            )
        }

        /// The attributes for the next typing
        view.typingAttributes = [
            .foregroundColor: NSColor.textColor,
            .font: font
        ]
    }
}
