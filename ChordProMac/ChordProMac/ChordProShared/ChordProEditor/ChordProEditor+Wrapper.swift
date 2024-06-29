//
//  ChordProEditor+Wrapper.swift
//  ChordProShared
//
//  Created by Nick Berendsen on 27/06/2024.
//

import AppKit

extension ChordProEditor {

    // MARK: The wrapper for the editor

    /// A wrapper for
    /// - `NSScrollView`
    /// - `NSTextView`
    /// - `NSRulerView`
    public class Wrapper: NSView, ChordProEditorDelegate {

        /// Init the `NSView`
        /// - Parameter frameRect: The rect of the `NSView`
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
        }

        /// Init the `NSView`
        /// - Parameter coder: The `NSCoder`
        required public init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        weak var delegate: NSTextViewDelegate?

        private lazy var scrollView: NSScrollView = {
            let scrollView = NSScrollView()
            scrollView.drawsBackground = true
            scrollView.borderType = .noBorder
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalRuler = false
            scrollView.hasVerticalRuler      = true
            scrollView.rulersVisible         = true
            scrollView.autoresizingMask = [.width, .height]
            scrollView.translatesAutoresizingMaskIntoConstraints = false

            return scrollView
        }()

        lazy var textView: TextView = {
            let contentSize = scrollView.contentSize
            let textContentStorage = NSTextContentStorage()
            let textLayoutManager = NSTextLayoutManager()
            textContentStorage.addTextLayoutManager(textLayoutManager)
            let textContainer = NSTextContainer(containerSize: scrollView.frame.size)
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(
                width: contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            textLayoutManager.textContainer = textContainer

            let textView = TextView(frame: .zero, textContainer: textContainer)
            textView.autoresizingMask = .width
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.delegate = self.delegate
            textView.font = .systemFont(ofSize: 8)
            textView.isEditable = true
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.minSize = NSSize(width: 0, height: contentSize.height)
            textView.textColor = NSColor.labelColor
            textView.allowsUndo = true
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.chordProEditorDelegate = self
            textView.allowsUndo = true
            textView.textContainerInset = .init(width: 4, height: 0)
            textView.drawsBackground = false

            return textView
        }()

        /// The `NSRulerView`
        lazy private var lineNumbers: LineNumbersView = {
            let lineNumbersView = LineNumbersView()
            return lineNumbersView
        }()

        public override func viewWillDraw() {
            super.viewWillDraw()

            setupScrollViewConstraints()
            setupTextView()
        }

        func setupScrollViewConstraints() {

            lineNumbers.scrollView = scrollView
            lineNumbers.orientation = .verticalRuler
            lineNumbers.clientView = textView
            lineNumbers.ruleThickness = 40

            scrollView.verticalRulerView = lineNumbers
            scrollView.documentView = textView

            addSubview(scrollView)

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: topAnchor),
                scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
            ])
        }

        func setupTextView() {
            scrollView.documentView = textView
        }

        // MARK: MacEditorDelegate

        /// A delegate function to update a view
        func selectionNeedsDisplay() {
            lineNumbers.needsDisplay = true
        }
    }
}
