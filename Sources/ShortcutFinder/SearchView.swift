import SwiftUI
import AppKit
import ShortcutCore

struct SearchView: View {
    @ObservedObject var model: AppModel
    @State private var query = ""
    @State private var selected = 0
    @State private var window: NSWindow?
    @State private var focusRequest = 0
    @State private var selectedCategory: String?
    @Environment(\.openSettings) private var openSettings
    private var he: Bool { model.hebrew }
    @State private var results: [ShortcutItem] = []
    private var empty: Bool { query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var displayedResults: [ShortcutItem] {
        let source = empty ? model.items.sorted { (he ? $0.titleHe : $0.titleEn) < (he ? $1.titleHe : $1.titleEn) } : results
        guard let selectedCategory else { return source }
        return source.filter { $0.category == selectedCategory }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "keyboard.fill").font(.title3).foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 3) {
                    Text("KeyMate").font(.headline)
                    Text(he ? "מ־Windows למק, בקיצור" : "From Windows to Mac, in a keystroke").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("⌘").font(.title2.weight(.light)).foregroundStyle(.tertiary)
            }
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                DirectionalSearchField(
                    text: $query,
                    placeholder: he ? "חפש פעולה או קיצור דרך…" : "Search an action or shortcut…",
                    rightToLeft: he,
                    focusRequest: focusRequest,
                    submit: { model.saveRecentSearch(query) },
                    moveSelection: { delta in selected = min(max(0, selected + delta), max(0, displayedResults.count - 1)) }
                ).frame(height: 20)
                if !query.isEmpty {
                    Button { query = ""; focusRequest += 1 } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).accessibilityLabel(he ? "ניקוי חיפוש" : "Clear search")
                }
            }.padding(10).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
            HStack {
                Menu {
                    Button(he ? "כל הקטגוריות" : "All categories") { selectedCategory = nil }
                    Divider()
                    ForEach(categoryOrder, id: \.self) { category in
                        Button(categoryName(category)) { selectedCategory = category }
                    }
                } label: {
                    Label(selectedCategory.map(categoryName) ?? (he ? "כל הקטגוריות" : "All categories"), systemImage: "line.3.horizontal.decrease.circle")
                }
                .menuStyle(.borderlessButton)
                .buttonStyle(.bordered)
                .controlSize(.small)
                Spacer()
                if selectedCategory != nil {
                    Button(he ? "ניקוי" : "Clear") { selectedCategory = nil }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let error = model.loadError {
                ContentUnavailableView(he ? "טעינת המאגר נכשלה" : "Catalog could not load", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if empty && selectedCategory == nil {
                if model.recentSearches.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text(he ? "אין עדיין חיפושים אחרונים" : "No recent searches yet")
                            .font(.headline)
                        Text(he ? "חפש פעולה או קיצור דרך, והוא יופיע כאן." : "Search for an action or shortcut and it will appear here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 34)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(he ? "חיפושים אחרונים" : "Recent searches").font(.headline)
                        ForEach(model.recentSearches, id: \.self) { recent in
                            Button { query = recent; focusRequest += 1 } label: {
                                HStack { Text(recent); Spacer(); Image(systemName: "clock.arrow.circlepath") }
                                    .padding(8).frame(maxWidth: .infinity).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.top, 4)
                }
                Spacer()
            } else if displayedResults.isEmpty {
                ContentUnavailableView(he ? "לא נמצאו קיצורים" : "No shortcuts found", systemImage: "magnifyingglass", description: Text(he ? "נסה פעולה קצרה כמו ״צילום מסך״, או קיצור כמו Ctrl C." : "Try a shorter action such as screenshot, or a shortcut like Ctrl C."))
                Spacer()
            } else {
                Text(he ? "\(displayedResults.count) תוצאות" : "\(displayedResults.count) results").font(.caption).foregroundStyle(.secondary)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 7) {
                            ForEach(Array(displayedResults.enumerated()), id: \.element.id) { index, item in
                                resultCard(item, selected: selected == index).id(item.id)
                                    .onTapGesture {
                                        selected = index
                                        model.saveRecentSearch(query)
                                    }
                            }
                        }
                    }.onChange(of: selected) { _, value in
                        if displayedResults.indices.contains(value) { proxy.scrollTo(displayedResults[value].id, anchor: .center) }
                    }
                }
            }
            Divider()
            HStack {
                Button { NSApp.activate(ignoringOtherApps: true); openSettings() } label: { Label(he ? "הגדרות" : "Settings", systemImage: "gearshape") }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
                Button(role: .destructive) { NSApp.terminate(nil) } label: { Label(he ? "יציאה" : "Quit", systemImage: "power") }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }.font(.caption)
        }
        .padding(14).frame(width: 370, height: 460)
        .preferredColorScheme(model.appearanceMode.colorScheme)
        .environment(\.layoutDirection, he ? .rightToLeft : .leftToRight)
        .background(WindowReader { window = $0 })
        .onAppear { focusSearch() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { event in
            if let w = event.object as? NSWindow, w === window { focusSearch() }
        }
        .onChange(of: query) { _, value in results = model.search(value); selected = 0 }
        .onExitCommand { window?.orderOut(nil) }
        .onKeyPress(.downArrow) { selected = min(selected + 1, max(0, displayedResults.count - 1)); return .handled }
        .onKeyPress(.upArrow) { selected = max(0, selected - 1); return .handled }
    }
    private func categoryName(_ category: String) -> String {
        guard he else { return category }
        return ["General": "כללי", "Text": "טקסט", "Navigation": "ניווט", "Browser": "דפדפן", "Finder": "קבצים", "Windows": "חלונות", "System": "מערכת", "Language": "שפה", "Screenshots": "צילום מסך"][category] ?? category
    }
    private var categoryOrder: [String] {
        ["General", "Text", "Navigation", "Browser", "Finder", "Windows", "System", "Language", "Screenshots"]
    }
    private func focusSearch() {
        Task { @MainActor in
            await Task.yield()
            focusRequest += 1
        }
    }
    private func resultCard(_ item: ShortcutItem, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(he ? item.titleHe : item.titleEn).font(.subheadline.weight(.semibold))
                Spacer()
                Text(categoryName(item.category)).font(.caption2).foregroundStyle(.secondary)
            }
            HStack {
                Text(item.macShortcut).font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .environment(\.layoutDirection, .leftToRight).textSelection(.enabled)
            }
            if let windows = item.windowsShortcut {
                Text("Windows: \(windows)").font(.caption.monospaced()).foregroundStyle(.secondary).environment(\.layoutDirection, .leftToRight)
            }
            Text(he ? item.descriptionHe : item.descriptionEn)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.indigo.opacity(0.10) : Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.indigo.opacity(0.4) : .clear))
    }
}

private struct WindowReader: NSViewRepresentable {
    let resolve: (NSWindow) -> Void
    func makeNSView(context: Context) -> ReaderView { let v = ReaderView(); v.resolve = resolve; return v }
    func updateNSView(_ nsView: ReaderView, context: Context) {}
    final class ReaderView: NSView {
        var resolve: ((NSWindow) -> Void)?
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window { DispatchQueue.main.async { self.resolve?(window) } }
        }
    }
}
