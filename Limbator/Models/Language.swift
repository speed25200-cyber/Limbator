import Foundation

/// Langue maternelle de l'apprenant. Limbator est conçu d'abord pour les
/// roumanophones (`ro` en tête de liste, valeur par défaut), mais l'architecture
/// reste multilingue : toute la pédagogie est ancrée dans la langue choisie.
struct NativeLanguage: Identifiable, Hashable, Codable {
    let id: String           // ISO 639-1
    let displayName: String  // Endonyme
    let englishName: String
    let regionCode: String   // ISO 3166 — pour le drapeau dessiné
    let rtl: Bool

    static let all: [NativeLanguage] = [
        .init(id: "ro", displayName: "Română",       englishName: "Romanian",   regionCode: "RO", rtl: false),
        .init(id: "en", displayName: "English",      englishName: "English",    regionCode: "GB", rtl: false),
        .init(id: "it", displayName: "Italiano",     englishName: "Italian",    regionCode: "IT", rtl: false),
        .init(id: "es", displayName: "Español",      englishName: "Spanish",    regionCode: "ES", rtl: false),
        .init(id: "pt", displayName: "Português",    englishName: "Portuguese", regionCode: "PT", rtl: false),
        .init(id: "de", displayName: "Deutsch",      englishName: "German",     regionCode: "DE", rtl: false),
        .init(id: "pl", displayName: "Polski",       englishName: "Polish",     regionCode: "PL", rtl: false),
        .init(id: "hu", displayName: "Magyar",       englishName: "Hungarian",  regionCode: "HU", rtl: false),
        .init(id: "bg", displayName: "Български",    englishName: "Bulgarian",  regionCode: "BG", rtl: false),
        .init(id: "uk", displayName: "Українська",   englishName: "Ukrainian",  regionCode: "UA", rtl: false),
        .init(id: "ru", displayName: "Русский",      englishName: "Russian",    regionCode: "RU", rtl: false),
        .init(id: "el", displayName: "Ελληνικά",     englishName: "Greek",      regionCode: "GR", rtl: false),
        .init(id: "tr", displayName: "Türkçe",       englishName: "Turkish",    regionCode: "TR", rtl: false),
        .init(id: "sq", displayName: "Shqip",        englishName: "Albanian",   regionCode: "AL", rtl: false),
        .init(id: "sr", displayName: "Српски",       englishName: "Serbian",    regionCode: "RS", rtl: false),
        .init(id: "nl", displayName: "Nederlands",   englishName: "Dutch",      regionCode: "NL", rtl: false),
        .init(id: "ar", displayName: "العربية",      englishName: "Arabic",     regionCode: "SA", rtl: true),
        .init(id: "zh", displayName: "中文",          englishName: "Chinese",    regionCode: "CN", rtl: false),
        .init(id: "ja", displayName: "日本語",         englishName: "Japanese",   regionCode: "JP", rtl: false),
        .init(id: "vi", displayName: "Tiếng Việt",   englishName: "Vietnamese", regionCode: "VN", rtl: false)
    ]

    /// La langue enseignée par Limbator.
    static let french = NativeLanguage(
        id: "fr", displayName: "Français", englishName: "French", regionCode: "FR", rtl: false
    )

    /// La langue maternelle de référence de l'app.
    static let romanian = NativeLanguage(
        id: "ro", displayName: "Română", englishName: "Romanian", regionCode: "RO", rtl: false
    )

    /// Résolution sûre par code — ne peut jamais échouer.
    static func byId(_ id: String) -> NativeLanguage {
        all.first(where: { $0.id == id }) ?? romanian
    }
}

/// Niveaux CECRL. Les libellés sont écrits en roumain (langue de l'apprenant
/// cible) puis traduits par `ContentL10n` si une autre langue est choisie.
enum ProficiencyLevel: String, Codable, CaseIterable, Identifiable, Comparable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"

    var id: String { rawValue }

    /// Rang numérique — sert aux comparaisons de difficulté.
    var rank: Int {
        switch self {
        case .a1: return 1; case .a2: return 2; case .b1: return 3
        case .b2: return 4; case .c1: return 5; case .c2: return 6
        }
    }

    static func < (lhs: ProficiencyLevel, rhs: ProficiencyLevel) -> Bool {
        lhs.rank < rhs.rank
    }

    /// Titre court (source roumaine, localisée à l'affichage).
    var title: String {
        switch self {
        case .a1: return "Începător"
        case .a2: return "Elementar"
        case .b1: return "Intermediar"
        case .b2: return "Avansat"
        case .c1: return "Autonom"
        case .c2: return "Măiestrie"
        }
    }

    var subtitle: String {
        switch self {
        case .a1: return "Primele cuvinte și expresii"
        case .a2: return "Conversații simple, prezentul"
        case .b1: return "Trecutul, acordurile de bază"
        case .b2: return "Subjonctiv, nuanțe, texte lungi"
        case .c1: return "Ortografie fără ezitare"
        case .c2: return "Nivel de redactor francez"
        }
    }

    var localizedTitle: String { ContentL10n.s(title) }
    var localizedSubtitle: String { ContentL10n.s(subtitle) }

    var iconName: String {          // SF Symbol
        switch self {
        case .a1: return "leaf"
        case .a2: return "leaf.fill"
        case .b1: return "book.fill"
        case .b2: return "graduationcap.fill"
        case .c1: return "wand.and.stars"
        case .c2: return "crown.fill"
        }
    }

    /// Niveau immédiatement supérieur (le dernier se retourne lui-même).
    var next: ProficiencyLevel {
        let ordered = ProficiencyLevel.allCases
        guard let i = ordered.firstIndex(of: self), i + 1 < ordered.count else { return self }
        return ordered[i + 1]
    }
}
