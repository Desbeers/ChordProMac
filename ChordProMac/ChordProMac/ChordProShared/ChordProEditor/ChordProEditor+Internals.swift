//
//  ChordProEditor+Internals.swift
//  ChordProShared
//
//  Created by Nick Berendsen on 27/06/2024.
//

import Foundation

extension ChordProEditor {

    public struct Internals: Sendable {

        public init(
            directive: ChordProDirective? = nil,
            directiveArgument: String = "",
            directiveRange: NSRange? = nil,
            clickedDirective: Bool = false,
            selectedRange: NSRange = NSRange(),
            textView: TextView? = nil
        ) {
            self.directive = directive
            self.directiveArgument = directiveArgument
            self.directiveRange = directiveRange
            self.clickedDirective = clickedDirective
            self.selectedRange = selectedRange
            self.textView = textView
        }

        public var directive: ChordProDirective?
        public var directiveArgument: String
        public var directiveRange: NSRange?
        /// Click detection
        public var clickedDirective: Bool = false
        public var selectedRange = NSRange()
        public var textView: TextView?
    }
}
