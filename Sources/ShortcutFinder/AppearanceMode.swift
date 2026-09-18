import AppKit
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case dark, light, system

    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
    var nativeAppearance: NSAppearance? {
        switch self {
        case .dark: return NSAppearance(named: .darkAqua)
        case .light: return NSAppearance(named: .aqua)
        case .system: return nil
        }
    }
    func title(hebrew: Bool) -> String {
        switch self {
        case .dark: return hebrew ? "כהה" : "Dark"
        case .light: return hebrew ? "בהיר" : "Light"
        case .system: return hebrew ? "מערכת" : "System"
        }
    }
}
