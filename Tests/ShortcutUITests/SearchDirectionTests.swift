import AppKit
import XCTest
@testable import ShortcutFinder

final class SearchDirectionTests: XCTestCase {
    @MainActor
    func testActiveEditorKeepsRTLForEmptyHebrewAndEnglishQueries() {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let field = SearchTextField(frame: NSRect(x: 10, y: 10, width: 360, height: 24))
        field.rtl = true
        field.applyDirection()
        window.contentView?.addSubview(field)
        field.selectText(nil)
        guard let editor = field.currentEditor() as? NSTextView else {
            XCTFail("Expected the native field editor to be active")
            return
        }
        for query in ["", "צילום מסך", "alt tab", "איך עושים Ctrl C"] {
            editor.string = query
            field.applyDirection()
            XCTAssertTrue(field.currentEditor() === editor, "Editing must retain focus")
            XCTAssertEqual(editor.alignment, .right, query)
            XCTAssertEqual(editor.baseWritingDirection, .rightToLeft, query)
            XCTAssertEqual(editor.defaultParagraphStyle?.baseWritingDirection, .rightToLeft, query)
        }
        field.rtl = false
        field.applyDirection()
        XCTAssertEqual(editor.alignment, .left)
        XCTAssertEqual(editor.baseWritingDirection, .leftToRight)
        window.makeFirstResponder(nil)
    }
}
