import Foundation
public struct ShortcutItem: Identifiable, Codable, Equatable {
    public let id: String
    public let titleHe: String
    public let titleEn: String
    public let descriptionHe: String
    public let descriptionEn: String
    public let keywords: [String]
    public let category: String
    public let windowsShortcut: String?
    public let macShortcut: String
}
public enum Catalog {
    public static func load() throws -> [ShortcutItem] {
        // SwiftPM's generated accessor uses the build directory as a fallback.
        // Resolve the copied bundle explicitly so the .app also works on another Mac.
        let bundle: Bundle
        if let packagedURL = Bundle.main.url(forResource: "ShortcutFinder_ShortcutCore", withExtension: "bundle"),
           let packaged = Bundle(url: packagedURL) { bundle = packaged }
        else { bundle = Bundle.module }
        guard let url = bundle.url(forResource: "shortcuts", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        return try JSONDecoder().decode([ShortcutItem].self, from: Data(contentsOf: url))
    }
}
public struct SearchEngine {
    private let items: [ShortcutItem]
    public init(items: [ShortcutItem]) { self.items = items }
    public static func normalize(_ text: String) -> String {
        var s = text.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX")).lowercased()
        s = String(s.unicodeScalars.filter { !CharacterSet.nonBaseCharacters.contains($0) })
        for (a,b) in [("⌘"," cmd "),("⌥"," alt "),("⌃"," ctrl "),("⇧"," shift "),("⌫"," backspace "),("←"," left "),("→"," right "),("↑"," up "),("↓"," down "),("`"," grave "),("ם","מ"),("ן","נ"),("ץ","צ"),("ף","פ"),("ך","כ")] { s = s.replacingOccurrences(of: a, with: b) }
        s = s.replacingOccurrences(of: #"\+\s*$"#, with: " plus ", options: .regularExpression)
        for (symbol, name) in [("−", "minus"), ("-", "minus"), (",", "comma"), (".", "period"), ("[", "leftbracket"), ("]", "rightbracket"), ("{", "leftbrace"), ("}", "rightbrace"), ("|", "verticalbar")] {
            s = s.replacingOccurrences(of: symbol, with: " \(name) ")
        }
        let words = s.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let aliases = ["control":"ctrl", "command":"cmd", "option":"alt", "windows":"win", "escape":"esc", "return":"enter"]
        return words.map { aliases[$0] ?? $0 }.joined(separator: " ")
    }
    private static let stop = Set(normalize("איך אני את של לי במק במאק עושים לעשות אפשר רוצה how do i to the a on mac please can my").split(separator: " ").map(String.init))
    private static func tokens(_ s: String) -> [String] {
        let words = normalize(s).split(separator: " ").map(String.init)
        let hasModifier = words.contains { ["ctrl", "cmd", "alt", "shift", "win"].contains($0) }
        return words.filter { !stop.contains($0) || (hasModifier && ["a", "i"].contains($0)) }
    }
    private static func distance(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        var row = Array(0...y.count)
        for (i,c) in x.enumerated() {
            var next = [i+1]
            for (j,d) in y.enumerated() { next.append(min(next[j]+1, row[j+1]+1, row[j]+(c == d ? 0 : 1))) }
            row = next
        }
        return row[y.count]
    }
    private static func categoryTerms(for category: String) -> [String] {
        switch category {
        case "Text": return ["text", "טקסט", "כתיבה", "עריכת טקסט"]
        case "General": return ["general", "כללי", "בסיסי"]
        case "Navigation": return ["navigation", "ניווט", "תנועה"]
        case "Browser": return ["browser", "דפדפן", "גלישה"]
        case "Finder": return ["finder", "קבצים", "תיקיות"]
        case "Windows": return ["windows", "חלונות", "אפליקציות"]
        case "System": return ["system", "מערכת"]
        case "Language": return ["language", "שפה", "מקלדת"]
        case "Screenshots": return ["screenshots", "צילום מסך", "צילומי מסך"]
        default: return [category]
        }
    }
    public func search(_ query: String, limit: Int = 30) -> [ShortcutItem] {
        var q = Self.tokens(query)
        // “windows alt tab” names the source platform, not a Win-key chord.
        if q.first == "win", q.count > 2, q.contains("alt"), !q.contains("ctrl") { q.removeFirst() }
        guard !q.isEmpty, limit > 0 else { return [] }
        let phrase = q.joined(separator: " ")
        let modifiers: Set<String> = ["ctrl","alt","cmd","shift","win"]
        let chord = !Set(q).isDisjoint(with: modifiers)
        return items.compactMap { item -> (ShortcutItem, Double)? in
            let fields = [item.titleHe, item.titleEn] + item.keywords + Self.categoryTerms(for: item.category)
            let normalized = fields.map { Self.tokens($0).joined(separator: " ") }
            let words = Set(normalized.flatMap { $0.split(separator: " ").map(String.init) })
            let chords = [item.windowsShortcut ?? "", item.macShortcut].map { Set(Self.tokens($0)) }
            if chord, chords.contains(Set(q)) { return (item, 1000) }
            var score = 0.0, matched = 0
            for token in q {
                let best = words.map { word -> Double in
                    if word == token { return 12 }
                    if token.count >= 3 && word.hasPrefix(token) { return 8 }
                    if token.count >= 4 && abs(word.count-token.count) <= 1 && Self.distance(token, word) <= 1 { return 6 }
                    return 0
                }.max() ?? 0
                if best > 0 { matched += 1 }; score += best
            }
            guard Double(matched)/Double(q.count) >= 0.65 else { return nil }
            if normalized.contains(phrase) { score += 70 }
            else if normalized.contains(where: { $0.contains(phrase) }) { score += 30 }
            score += Double(matched)/Double(q.count)*20
            return (item,score)
        }.sorted { $0.1 == $1.1 ? $0.0.id < $1.0.id : $0.1 > $1.1 }.prefix(limit).map(\.0)
    }
}
