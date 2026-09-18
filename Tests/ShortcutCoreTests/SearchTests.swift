import XCTest
@testable import ShortcutCore
final class SearchTests: XCTestCase {
    private var engine: SearchEngine { get throws { SearchEngine(items: try Catalog.load()) } }
    func testCatalogIntegrity() throws {
        let items = try Catalog.load()
        XCTAssertGreaterThanOrEqual(items.count, 60)
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
        for item in items {
            XCTAssertFalse(item.titleHe.isEmpty)
            XCTAssertFalse(item.titleEn.isEmpty)
            XCTAssertFalse(item.descriptionHe.isEmpty)
            XCTAssertFalse(item.descriptionEn.isEmpty)
            XCTAssertFalse(item.macShortcut.isEmpty)
            XCTAssertFalse(item.keywords.isEmpty)
        }
    }
    func testHebrewNaturalLanguage() throws {
        for (query, expected) in [
            ("איך אני מצלם חלק מהמסך", "screenshot-area"),
            ("פתיחת טאב שסגרתי", "reopen-tab"),
            ("מחיקת מילה", "delete-word"),
            ("עברית לאנגלית", "language"),
            ("מחיקת קובץ", "trash"),
            ("סגירת אפליקציה", "quit"),
            ("כיוון פסקה לימין לשמאל", "paragraph-rtl"),
            ("כיוון פסקה לאנגלית", "paragraph-ltr"),
            ("חלונות האפליקציה הנוכחית", "app-windows"),
            ("איך עושים ctrl shift t במק", "reopen-tab")
        ] { XCTAssertEqual(try engine.search(query).first?.id, expected, query) }
    }
    func testEnglishAndWindowsShortcuts() throws {
        for (query, expected) in [
            ("how do I force quit", "force-quit"),
            ("windows alt tab", "app-switch"),
            ("delete word", "delete-word"),
            ("CTRL + SHIFT + T", "reopen-tab"),
            ("control c", "copy"),
            ("Ctrl A", "select-all"),
            ("Ctrl I", "italic"),
            ("Ctrl +", "zoom-in"),
            ("Ctrl -", "zoom-out"),
            ("⌘ ,", "settings"),
            ("⌘ C", "copy"),
            ("reopen closed tab", "reopen-tab"),
            ("screenshot selection", "screenshot-area"),
            ("paragraph direction right to left", "paragraph-rtl"),
            ("current app windows", "app-windows")
        ] { XCTAssertEqual(try engine.search(query).first?.id, expected, query) }
    }
    func testTypos() throws {
        XCTAssertEqual(try engine.search("screeshot selection").first?.id, "screenshot-area")
        XCTAssertEqual(try engine.search("מחיקת מילהה").first?.id, "delete-word")
    }
    func testNormalization() {
        XCTAssertEqual(SearchEngine.normalize("  CONTROL + Shift + T  "), "ctrl shift t")
        XCTAssertEqual(SearchEngine.normalize("מְחִיקַת"), SearchEngine.normalize("מחיקת"))
        XCTAssertEqual(SearchEngine.normalize("מסך"), SearchEngine.normalize("מסכ"))
    }
    func testEmptyUnknownAndLimits() throws {
        for q in ["", "  ", "איך אני", "zzzzqqqq", "🍕🍕"] { XCTAssertTrue(try engine.search(q).isEmpty, q) }
        XCTAssertLessThanOrEqual(try engine.search("חלון", limit: 2).count, 2)
        XCTAssertTrue(try engine.search("copy", limit: 0).isEmpty)
    }
    func testDeterministicRanking() throws {
        XCTAssertEqual(try engine.search("צילום מסך"), try engine.search("צילום מסך"))
        XCTAssertEqual(try engine.search("delete word").first?.macShortcut, "⌥ ⌫")
    }
    func testCategorySearchReturnsEveryShortcutInEveryCategory() throws {
        let items = try Catalog.load()
        let queries = [
            "General": ["כללי", "general"],
            "Text": ["טקסט", "text"],
            "Navigation": ["ניווט", "navigation"],
            "Browser": ["דפדפן", "browser"],
            "Finder": ["קבצים", "finder"],
            "Windows": ["חלונות", "windows"],
            "System": ["מערכת", "system"],
            "Language": ["שפה", "language"],
            "Screenshots": ["צילומי מסך", "screenshots"]
        ]
        for (category, categoryQueries) in queries {
            let expected = Set(items.filter { $0.category == category }.map(\.id))
            XCTAssertFalse(expected.isEmpty, "Missing test data for \(category)")
            for query in categoryQueries {
                let results = Set(try engine.search(query, limit: 100).map(\.id))
                XCTAssertTrue(expected.isSubset(of: results), "\(query) did not return every \(category) shortcut")
            }
        }
    }
}
