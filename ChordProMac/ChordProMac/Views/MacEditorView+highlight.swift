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
    /// The line height multiplier for the editor text
    static let lineHeightMultiple: Double = 1.2
    /// The style of a paragraph in the editor
    static let paragraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = MacEditorView.lineHeightMultiple
        return style
    }()

    /// Highlight the text in the editor
    /// - Parameters:
    ///   - view: The `NSTextView`
    ///   - font: The current `NSFont`
    ///   - range: The `NSRange` to highlight
    /// - Returns: A highlighted text
    static func highlight(view: NSTextView, font: NSFont, range: NSRange) {
        let text = view.textStorage?.string ?? ""
        /// Make all text in the default style
        view.textStorage?.setAttributes(
            [
                .paragraphStyle: MacEditorView.paragraphStyle,
                .foregroundColor: NSColor.textColor,
                .font: font
            ], 
            range: range
        )
        /// Highlight directives
        let directives = directiveRegex.matches(in: text, options: [], range: range)
        directives.forEach { directive in
            view.textStorage?.addAttribute(
                .foregroundColor,
                value: NSColor.systemIndigo,
                range: directive.range
            )
        }
        /// Highlight chords
        let chords = chordRegex.matches(in: text, options: [], range: range)
        chords.forEach { chord in
                view.textStorage?.addAttribute(
                    .foregroundColor,
                    value: NSColor.systemRed,
                    range: chord.range
                )
        }
        /// Highlight comments
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
            .paragraphStyle: MacEditorView.paragraphStyle,
            .foregroundColor: NSColor.textColor,
            .font: font
        ]
    }
}
