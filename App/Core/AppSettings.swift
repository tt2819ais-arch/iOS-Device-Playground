import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var titleKey: LocalizedStringKey {
        switch self {
        case .system: return "theme_system"
        case .light:  return "theme_light"
        case .dark:   return "theme_dark"
        }
    }
    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, ru
    var id: String { rawValue }
    var titleKey: LocalizedStringKey {
        switch self {
        case .system: return "lang_system"
        case .en:     return "lang_english"
        case .ru:     return "lang_russian"
        }
    }
    var flag: String {
        switch self {
        case .system: return "globe"
        case .en:     return "🇬🇧"
        case .ru:     return "🇷🇺"
        }
    }
}

final class AppSettings: ObservableObject {
    @AppStorage("app.theme") private var themeRaw: String = AppTheme.system.rawValue
    @AppStorage("app.language") private var languageRaw: String = AppLanguage.system.rawValue

    var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
        set { themeRaw = newValue.rawValue; objectWillChange.send() }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .system }
        set { languageRaw = newValue.rawValue; objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var locale: Locale {
        switch language {
        case .system: return .current
        case .en:     return Locale(identifier: "en")
        case .ru:     return Locale(identifier: "ru")
        }
    }
}
