import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled
    @State private var loginMessage: String?
    private var he: Bool { model.hebrew }
    var body: some View {
        Form {
            Section(he ? "מראה" : "Appearance") {
                Picker(he ? "מצב תצוגה" : "Theme", selection: $model.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title(hebrew: he)).tag(mode)
                    }
                }.pickerStyle(.segmented)
                Text(he ? "מצב מערכת מתאים את המראה להגדרות ה־Mac." : "System follows your Mac’s appearance settings.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(he ? "כללי" : "General") {
                Toggle(he ? "ממשק בעברית" : "Hebrew interface", isOn: $model.hebrew)
                Toggle(he ? "הפעלה בכניסה למחשב" : "Launch at login", isOn: Binding(get: { loginEnabled }, set: setLogin))
                if let loginMessage { Text(loginMessage).font(.caption).foregroundStyle(.secondary) }
                if SMAppService.mainApp.status == .requiresApproval {
                    Button(he ? "פתיחת פריטי התחברות" : "Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                }
            }
            Section(he ? "חיפוש מכל אפליקציה" : "Search from any app") {
                Toggle(he ? "הפעל קיצור גלובלי" : "Enable global hotkey", isOn: Binding(get: { model.hotkeyEnabled }, set: model.setHotkey))
                Text("⌃ ⌥ K").font(.body.monospaced()).environment(\.layoutDirection, .leftToRight)
                Text(he ? "פותח חלון חיפוש צף מכל אפליקציה. אפשר לכבות אותו כאן." : "Opens a floating search window from any app. Disable it here if needed.").font(.caption).foregroundStyle(.secondary)
                Button(he ? "פתיחת חלון החיפוש" : "Open search window") { model.showSearch() }
                if let error = model.hotkeyError { Text(error).foregroundStyle(.red).font(.caption) }
            }
            Section {
                Text(he ? "כל החיפושים מתבצעים במחשב. אין שירות רשת ואין צורך במפתח API." : "All searches run on this Mac. No network service or API key is needed.").font(.caption)
            }
        }.formStyle(.grouped).padding().frame(width: 460)
            .preferredColorScheme(model.appearanceMode.colorScheme)
            .environment(\.layoutDirection, he ? .rightToLeft : .leftToRight)
            .onAppear { loginEnabled = SMAppService.mainApp.status == .enabled }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in loginEnabled = SMAppService.mainApp.status == .enabled }
    }
    private func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginEnabled = SMAppService.mainApp.status == .enabled
            loginMessage = SMAppService.mainApp.status == .requiresApproval ? (he ? "יש לאשר בהגדרות פריטי התחברות." : "Approval is required in Login Items settings.") : nil
        } catch {
            loginEnabled = SMAppService.mainApp.status == .enabled
            loginMessage = (he ? "לא ניתן לעדכן הפעלה אוטומטית: " : "Could not update login setting: ") + error.localizedDescription
        }
    }
}
