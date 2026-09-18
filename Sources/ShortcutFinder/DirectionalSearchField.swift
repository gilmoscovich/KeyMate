import AppKit
import SwiftUI

/// Set direction on AppKit's actual field editor, not just the SwiftUI container.
struct DirectionalSearchField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var rightToLeft: Bool
    var focusRequest: Int
    var submit: () -> Void
    var moveSelection: (Int) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> SearchTextField {
        let field = SearchTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.cell?.usesSingleLineMode = true
        field.cell?.isScrollable = true
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.setAccessibilityIdentifier("shortcut-search")
        field.delegate = context.coordinator
        return field
    }
    func updateNSView(_ field: SearchTextField, context: Context) {
        context.coordinator.parent = self
        field.rtl = rightToLeft
        if field.stringValue != text { field.stringValue = text }
        field.applyDirection()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = rightToLeft ? .right : .left
        paragraph.baseWritingDirection = rightToLeft ? .rightToLeft : .leftToRight
        field.placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [
            .paragraphStyle: paragraph,
            .font: field.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.placeholderTextColor
        ])
        field.setAccessibilityLabel(placeholder)
        if context.coordinator.lastFocusRequest != focusRequest {
            context.coordinator.lastFocusRequest = focusRequest
            DispatchQueue.main.async { [weak field] in
                guard let field, let window = field.window, window.isKeyWindow else { return }
                if field.currentEditor() == nil { window.makeFirstResponder(field) }
                field.applyDirection()
            }
        }
    }
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: DirectionalSearchField
        var lastFocusRequest: Int?
        init(_ parent: DirectionalSearchField) { self.parent = parent }
        func controlTextDidBeginEditing(_ notification: Notification) {
            (notification.object as? SearchTextField)?.applyDirection()
        }
        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? SearchTextField else { return }
            field.applyDirection()
            parent.text = field.stringValue
        }
        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            // Let the input method handle Return/arrows while composing text.
            guard !textView.hasMarkedText() else { return false }
            switch selector {
            case #selector(NSResponder.insertNewline(_:)): parent.submit()
            case #selector(NSResponder.moveDown(_:)): parent.moveSelection(1)
            case #selector(NSResponder.moveUp(_:)): parent.moveSelection(-1)
            case #selector(NSResponder.cancelOperation(_:)): control.window?.orderOut(nil)
            default: return false
            }
            return true
        }
    }
}

final class SearchTextField: NSTextField {
    var rtl = true
    func applyDirection() {
        let activeEditor = currentEditor() as? NSTextView
        // Changing NSCell attributes during editing can detach the shared editor.
        // Configure the cell before focus, and the active editor while typing.
        guard let editor = activeEditor else {
            cell?.baseWritingDirection = rtl ? .rightToLeft : .leftToRight
            cell?.alignment = rtl ? .right : .left
            return
        }
        guard !editor.hasMarkedText() else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = rtl ? .right : .left
        paragraph.baseWritingDirection = rtl ? .rightToLeft : .leftToRight
        editor.defaultParagraphStyle = paragraph
        editor.baseWritingDirection = rtl ? .rightToLeft : .leftToRight
        editor.alignment = rtl ? .right : .left
        var attributes = editor.typingAttributes
        attributes[.paragraphStyle] = paragraph
        editor.typingAttributes = attributes
    }
    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { applyDirection() }
        return accepted
    }
}
