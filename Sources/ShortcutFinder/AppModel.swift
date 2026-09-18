import SwiftUI
import AppKit
import ShortcutCore

@MainActor
final class AppModel: ObservableObject {
    @Published var items: [ShortcutItem] = []
    @Published var loadError: String?
    @Published var hotkeyError: String?
    @Published var hebrew = UserDefaults.standard.object(forKey: "hebrew") as? Bool ?? true {
        didSet { UserDefaults.standard.set(hebrew, forKey: "hebrew") }
    }
    @Published var appearanceMode = AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appearanceMode") ?? "system") ?? .system {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
            applyAppearance()
        }
    }
    private func applyAppearance() {
        // A nil appearance follows macOS automatically, including later changes.
        // This also styles the AppKit text field, popover chrome and floating panel.
        NSApplication.shared.appearance = appearanceMode.nativeAppearance
    }
    @Published var hotkeyEnabled = UserDefaults.standard.bool(forKey: "hotkey")
    @Published private(set) var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    private var engine = SearchEngine(items: [])
    func search(_ query: String) -> [ShortcutItem] { engine.search(query) }
    func saveRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        recentSearches = Array(recentSearches.prefix(8))
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
    private let hotkey = GlobalHotkey()
    private var panel: NSPanel?
    init() {
        applyAppearance()
        do { items = try Catalog.load(); engine = SearchEngine(items: items) } catch { loadError = error.localizedDescription }
        if hotkeyEnabled { setHotkey(true) }
    }
    func setHotkey(_ enabled: Bool) {
        hotkey.unregister()
        hotkeyError = nil
        if enabled {
            let status = hotkey.register { [weak self] in self?.showSearch() }
            if status != noErr {
                hotkeyError = hebrew ? "לא ניתן לרשום את הקיצור (\(status)). ייתכן שהוא בשימוש באפליקציה אחרת." : "Could not register shortcut (\(status)). Another app may be using it."
                hotkeyEnabled = false
                UserDefaults.standard.set(false, forKey: "hotkey")
                return
            }
        }
        hotkeyEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "hotkey")
    }
    func showSearch() {
        if panel == nil {
            let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 370, height: 460), styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
            p.title = "KeyMate"
            p.titleVisibility = .hidden
            p.titlebarAppearsTransparent = true
            p.isReleasedWhenClosed = false
            p.level = .floating
            p.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            p.contentView = NSHostingView(rootView: SearchView(model: self))
            panel = p
        }
        panel?.center()
        NSApp.activate(ignoringOtherApps: true)
        panel?.makeKeyAndOrderFront(nil)
    }
}
