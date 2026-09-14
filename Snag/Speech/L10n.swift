// Five languages, chosen in the app and not by the phone: English, Naijá
// (Nigerian Pidgin), Yorùbá, Hausa, Igbo. Every string the app shows is
// written in English in `Strings`, `ReportText` and `Prompts`, and looked
// up here by that English text in the language the tenant chose. A word
// with no translation falls back to English — and `make l10n-check` fails
// the build if there is one, so the fallback is never seen.
//
// The translations are drafts by the developer, not a native speaker's.
// R5 in the release ledger is a native speaker reading each one; until
// then the language picker says so.
import Foundation
import Observation

enum Language: String, CaseIterable, Sendable {
    case english = "en", pidgin = "pcm", yoruba = "yo", hausa = "ha", igbo = "ig"

    /// The language's own name for itself, which is how a picker lists languages.
    var name: String {
        switch self {
        case .english: "English"
        case .pidgin: "Naijá (Pidgin)"
        case .yoruba: "Yorùbá"
        case .hausa: "Hausa"
        case .igbo: "Igbo"
        }
    }

    var table: [String: String] {
        switch self {
        case .english: [:]
        case .pidgin: Translations.pidgin
        case .yoruba: Translations.yoruba
        case .hausa: Translations.hausa
        case .igbo: Translations.igbo
        }
    }
}

/// The choice, observable, so the whole tree re-renders when it changes:
/// the strings are looked up statically and no view depends on them.
@MainActor
@Observable
final class L10nState {
    static let shared = L10nState()
    var language: Language = L10n.language
}

enum L10n {
    nonisolated(unsafe) private static var cached: Language?

    /// The chosen language; English until chosen. Read often, so cached;
    /// `set` writes the default and the cache together.
    static var language: Language {
        get {
            if let cached { return cached }
            let l = Language(rawValue: UserDefaults.standard.string(forKey: "pref.language") ?? "") ?? .english
            cached = l
            return l
        }
        set {
            cached = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "pref.language")
            Task { @MainActor in L10nState.shared.language = newValue }
        }
    }

    static func t(_ english: String) -> String {
        language == .english ? english : (language.table[english] ?? english)
    }
}

func t(_ english: String) -> String { L10n.t(english) }
