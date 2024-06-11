//
//  MacEditorView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 11/06/2024.
//

import SwiftUI

struct MacEditorView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> CustomTextView {
        let textView = CustomTextView(
            text: text,
            font: font
        )
        textView.delegate = context.coordinator

        return textView
    }

    func updateNSView(_ view: CustomTextView, context: Context) {
        
        if view.textView.string != text {
            view.textView.string = text
            view.selectedRanges = context.coordinator.selectedRanges
            let all = NSRange(location: 0, length: text.utf16.count)
            MacEditorView.highlight(view: view.textView, font: font, range: all)
        }
        view.font = font
    }
}

extension MacEditorView {

    // MARK: Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacEditorView
        var selectedRanges: [NSValue] = []

        var highlightRange = NSRange()

        init(_ parent: MacEditorView) {
            self.parent = parent
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            let composeText = textView.string as NSString
            highlightRange = NSRange(location: 0, length: composeText.length)
            if replacementString?.count ?? 0 > 1 {
                /// Full highlighting
                highlightRange = NSRange(location: 0, length: composeText.length)
            } else {
                /// Highlight only the current paragraph
                highlightRange = composeText.paragraphRange(for: textView.selectedRange)
            }
            return true
        }

        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            self.parent.text = textView.string
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            MacEditorView.highlight(view: textView, font: parent.font, range: highlightRange)
            self.selectedRanges = textView.selectedRanges
            parent.text = textView.string
        }

        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            self.parent.text = textView.string
        }
    }
}

extension MacEditorView {

    // MARK: CustomTextView

    final class CustomTextView: NSView {

        var font: NSFont {
            didSet {
                textView.font = font
            }
        }

        weak var delegate: NSTextViewDelegate?

        var text: String {
            didSet {
                textView.string = text
            }
        }

        var selectedRanges: [NSValue] = [] {
            didSet {
                guard selectedRanges.count > 0 else {
                    return
                }
                textView.selectedRanges = selectedRanges
            }
        }

        private lazy var scrollView: NSScrollView = {
            let scrollView = NSScrollView()
            scrollView.drawsBackground = true
            scrollView.borderType = .noBorder
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalRuler = false
            scrollView.autoresizingMask = [.width, .height]
            scrollView.translatesAutoresizingMaskIntoConstraints = false

            return scrollView
        }()

        lazy var textView: NSTextView = {
            let contentSize = scrollView.contentSize
            let textStorage = NSTextStorage()


            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)


            let textContainer = NSTextContainer(containerSize: scrollView.frame.size)
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(
                width: contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )

            layoutManager.addTextContainer(textContainer)


            let textView = NSTextView(frame: .zero, textContainer: textContainer)
            textView.autoresizingMask = .width
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.delegate = self.delegate
            textView.drawsBackground = true
            textView.font = self.font
            textView.isEditable = true
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.minSize = NSSize(width: 0, height: contentSize.height)
            textView.textColor = NSColor.labelColor
            textView.allowsUndo = true
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.textContainerInset = .init(width: 4, height: 8)

            return textView
        }()

        // MARK: Init

        init(text: String, font: NSFont) {
            self.font = font
            self.text = text

            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Life cycle

        override func viewWillDraw() {
            super.viewWillDraw()

            setupScrollViewConstraints()
            setupTextView()
        }

        func setupScrollViewConstraints() {
            scrollView.translatesAutoresizingMaskIntoConstraints = false

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
    }
}
