import SwiftUI
import AppKit
import ShortcutCore

@main
struct ShortcutFinderApp: App {
    @StateObject private var model = AppModel()
    init() {
        if CommandLine.arguments.contains("--verify-installation") {
            do {
                let items = try Catalog.load()
                guard items.count >= 60 else { throw CocoaError(.fileReadCorruptFile) }
                print("Installation verified: \(items.count) shortcuts")
                exit(0)
            } catch {
                fputs("Catalog verification failed: \(error)\n", stderr)
                exit(1)
            }
        }
    }
    var body: some Scene {
        MenuBarExtra("KeyMate", systemImage: "keyboard") {
            SearchView(model: model)
        }.menuBarExtraStyle(.window)
        Settings { SettingsView(model: model) }
    }
}
