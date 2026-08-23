import Foundation

struct UserProfile: Codable {
    var name: String
    var nativeLanguageId: String
    var level: ProficiencyLevel
    var dailyGoalMinutes: Int
    var xp: Int
    var streakDays: Int
    var bestStreak: Int
    var lastActiveDay: Date?
    var completedLessons: Set<String>       // slugs de thèmes
    var unlockedStories: Set<String>
    var badgesEarned: Set<String>
    /// Nombre de dictées terminées et moyenne courante sur 20 — la statistique
    /// dont un apprenant francophile est réellement fier.
    var dictationsDone: Int
    var dictationAverage: Double
    /// Compteur de fautes par catégorie — alimente le « profil de fautes ».
    var mistakeCounts: [String: Int]

    static let empty = UserProfile(
        name: "",
        nativeLanguageId: "ro",
        level: .a1,
        dailyGoalMinutes: 10,
        xp: 0,
        streakDays: 0,
        bestStreak: 0,
        lastActiveDay: nil,
        completedLessons: [],
        unlockedStories: [],
        badgesEarned: [],
        dictationsDone: 0,
        dictationAverage: 0,
        mistakeCounts: [:]
    )

    var nativeLanguage: NativeLanguage { NativeLanguage.byId(nativeLanguageId) }

    var levelTier: Int { max(1, xp / 250 + 1) }
    var xpToNextTier: Int { 250 - (xp % 250) }
    var tierProgress: Double { Double(xp % 250) / 250.0 }

    /// Les trois catégories de fautes les plus fréquentes — la base du plan de révision.
    var topWeaknesses: [OrthoErrorKind] {
        mistakeCounts
            .sorted { ($0.value, $0.key) > ($1.value, $1.key) }
            .prefix(3)
            .compactMap { OrthoErrorKind(rawValue: $0.key) }
    }

    /// Décodage tolérant : un profil enregistré par une version antérieure
    /// (sans les champs dictée) reste lisible au lieu de repartir à zéro.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name              = (try? c.decode(String.self, forKey: .name)) ?? ""
        nativeLanguageId  = (try? c.decode(String.self, forKey: .nativeLanguageId)) ?? "ro"
        level             = (try? c.decode(ProficiencyLevel.self, forKey: .level)) ?? .a1
        dailyGoalMinutes  = (try? c.decode(Int.self, forKey: .dailyGoalMinutes)) ?? 10
        xp                = (try? c.decode(Int.self, forKey: .xp)) ?? 0
        streakDays        = (try? c.decode(Int.self, forKey: .streakDays)) ?? 0
        bestStreak        = (try? c.decode(Int.self, forKey: .bestStreak)) ?? 0
        lastActiveDay     = try? c.decode(Date.self, forKey: .lastActiveDay)
        completedLessons  = (try? c.decode(Set<String>.self, forKey: .completedLessons)) ?? []
        unlockedStories   = (try? c.decode(Set<String>.self, forKey: .unlockedStories)) ?? []
        badgesEarned      = (try? c.decode(Set<String>.self, forKey: .badgesEarned)) ?? []
        dictationsDone    = (try? c.decode(Int.self, forKey: .dictationsDone)) ?? 0
        dictationAverage  = (try? c.decode(Double.self, forKey: .dictationAverage)) ?? 0
        mistakeCounts     = (try? c.decode([String: Int].self, forKey: .mistakeCounts)) ?? [:]
    }

    init(name: String, nativeLanguageId: String, level: ProficiencyLevel,
         dailyGoalMinutes: Int, xp: Int, streakDays: Int, bestStreak: Int,
         lastActiveDay: Date?, completedLessons: Set<String>,
         unlockedStories: Set<String>, badgesEarned: Set<String>,
         dictationsDone: Int, dictationAverage: Double, mistakeCounts: [String: Int]) {
        self.name = name; self.nativeLanguageId = nativeLanguageId
        self.level = level; self.dailyGoalMinutes = dailyGoalMinutes
        self.xp = xp; self.streakDays = streakDays; self.bestStreak = bestStreak
        self.lastActiveDay = lastActiveDay
        self.completedLessons = completedLessons
        self.unlockedStories = unlockedStories
        self.badgesEarned = badgesEarned
        self.dictationsDone = dictationsDone
        self.dictationAverage = dictationAverage
        self.mistakeCounts = mistakeCounts
    }
}

struct Badge: Identifiable, Codable, Hashable {
    var id: String { code }
    let code: String
    /// Titre source en roumain.
    let title: String
    /// Description source en roumain.
    let detail: String
    let rarity: Rarity
    let iconName: String

    enum Rarity: String, Codable, CaseIterable {
        case common, rare, epic, legendary

        var label: String {
            switch self {
            case .common: return "Obișnuit"
            case .rare: return "Rar"
            case .epic: return "Epic"
            case .legendary: return "Legendar"
            }
        }
    }

    var localizedTitle: String  { ContentL10n.s(title) }
    var localizedDetail: String { ContentL10n.s(detail) }

    static let catalog: [Badge] = [
        .init(code: "first_word",     title: "Premier mot",      detail: "Primul tău cuvânt franțuzesc",              rarity: .common,    iconName: "sparkles"),
        .init(code: "streak_3",       title: "Trois jours",      detail: "Trei zile la rând",                          rarity: .common,    iconName: "flame.fill"),
        .init(code: "streak_7",       title: "Une semaine",      detail: "Șapte zile la rând",                         rarity: .rare,      iconName: "flame.circle.fill"),
        .init(code: "streak_30",      title: "Un mois entier",   detail: "Treizeci de zile la rând",                   rarity: .legendary, iconName: "crown.fill"),
        .init(code: "first_dictee",   title: "Première dictée",  detail: "Ai terminat prima dictare",                  rarity: .common,    iconName: "pencil.and.scribble"),
        .init(code: "dictee_20",      title: "Vingt sur vingt",  detail: "O dictare fără nicio greșeală",              rarity: .epic,      iconName: "star.circle.fill"),
        .init(code: "dictee_10",      title: "Dix dictées",      detail: "Zece dictări terminate",                     rarity: .rare,      iconName: "text.book.closed.fill"),
        .init(code: "accent_master",  title: "Roi des accents",  detail: "Modulul de accente stăpânit",                rarity: .epic,      iconName: "textformat.abc.dottedunderline"),
        .init(code: "homophone_pro",  title: "Fin limier",       detail: "Modulul de homofone stăpânit",               rarity: .epic,      iconName: "arrow.triangle.branch"),
        .init(code: "accord_expert",  title: "Maître accord",    detail: "Acordul participiului stăpânit",             rarity: .legendary, iconName: "link.circle.fill"),
        .init(code: "story_done",     title: "Conteur",          detail: "Prima poveste terminată",                    rarity: .common,    iconName: "book.fill"),
        .init(code: "brancusi",       title: "L'atelier",        detail: "Povestea lui Brâncuși, citită până la capăt", rarity: .epic,      iconName: "hammer.fill"),
        .init(code: "perfect_game",   title: "Sans faute",       detail: "100% la un mini-joc",                        rarity: .rare,      iconName: "checkmark.seal.fill"),
        .init(code: "polyglot",       title: "Cent mots",        detail: "O sută de cuvinte stăpânite",                rarity: .epic,      iconName: "text.bubble.fill")
    ]

    static func badge(code: String) -> Badge? {
        catalog.first { $0.code == code }
    }
}
