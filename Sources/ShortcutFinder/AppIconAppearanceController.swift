import AppKit

/// Keeps the application icon in sync with the current macOS appearance.
/// The menu-bar symbol is intentionally left untouched.
final class AppIconAppearanceController {
    static let shared = AppIconAppearanceController()

    private var lastAppearance: NSAppearance.Name?
    private var appearanceTimer: Timer?

    private init() {}

    func start() {
        updateIcon()
        appearanceTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    private func updateIcon() {
        let appearance = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        guard appearance != lastAppearance else { return }
        lastAppearance = appearance
        let resourceName = appearance == .darkAqua ? "AppIcon-Dark" : "AppIcon-Light"

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return
        }

        NSApp.applicationIconImage = image
    }
}
