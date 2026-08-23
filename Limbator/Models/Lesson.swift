import Foundation
import SwiftUI

/// Un thème du parcours. Le curriculum couvre A1 → C1 en quatorze étapes ;
/// chaque thème porte, en plus du vocabulaire, un **point d'orthographe**
/// (`orthoFocus`) travaillé en contexte — c'est la colonne vertébrale de Limbator.
struct LessonTopic: Identifiable, Hashable, Codable {
    let id: String
    let slug: String
    /// Titre dans la langue de l'apprenant (source roumaine).
    let title: String
    /// Titre français — toujours affiché à côté, avec sa vraie orthographe.
    let frenchTitle: String
    let iconName: String
    let colorHex: UInt32
    let difficulty: ProficiencyLevel
    let estimatedMinutes: Int
    /// Résumé, source roumaine.
    let summary: String
    /// Le module d'orthographe travaillé en fil rouge dans cette leçon.
    let orthoFocus: OrthoModule

    var accent: Color { Color(hex: colorHex) }
    var localizedTitle: String   { ContentL10n.s(title) }
    var localizedSummary: String { ContentL10n.s(summary) }

    var icon: LimbIcon { LimbIcon(rawValue: iconName) ?? .bookOpen }

    static let curriculum: [LessonTopic] = [
        .init(id: "01", slug: "greetings", title: "Salutări și prezentare",
              frenchTitle: "Salutations et présentations", iconName: "greeting",
              colorHex: 0x2A6DF4, difficulty: .a1, estimatedMinutes: 8,
              summary: "Bonjour, enchanté, je m'appelle… și accentul din «enchanté»",
              orthoFocus: .accents),
        .init(id: "02", slug: "numbers", title: "Numere și cifre",
              frenchTitle: "Les nombres", iconName: "numbers",
              colorHex: 0xE8C56A, difficulty: .a1, estimatedMinutes: 10,
              summary: "De la zéro la mille — și celebrul «quatre-vingts» cu s",
              orthoFocus: .plurals),
        .init(id: "03", slug: "family", title: "Familia",
              frenchTitle: "La famille", iconName: "family",
              colorHex: 0xFF7BA9, difficulty: .a1, estimatedMinutes: 12,
              summary: "Membrii familiei, posesivele mon/ma/mes",
              orthoFocus: .homophones),
        .init(id: "04", slug: "food", title: "Mâncare și băutură",
              frenchTitle: "Manger et boire", iconName: "food",
              colorHex: 0x2ED9A3, difficulty: .a1, estimatedMinutes: 14,
              summary: "Pain, fromage, café — și articolele partitive du/de la",
              orthoFocus: .accents),
        .init(id: "05", slug: "city", title: "Orașul și direcțiile",
              frenchTitle: "La ville et les directions", iconName: "city",
              colorHex: 0x4FD1F5, difficulty: .a2, estimatedMinutes: 14,
              summary: "Rue, boulevard, à gauche, tout droit — și «à» cu accent grav",
              orthoFocus: .homophones),
        .init(id: "06", slug: "shopping", title: "Cumpărături",
              frenchTitle: "Les courses", iconName: "shoppingBag",
              colorHex: 0x8B6BFF, difficulty: .a2, estimatedMinutes: 12,
              summary: "Prețuri, mărimi, «combien ça coûte ?» — și circonflexul din coûter",
              orthoFocus: .roTraps),
        .init(id: "07", slug: "weather", title: "Vremea și anotimpurile",
              frenchTitle: "Le temps et les saisons", iconName: "cloudSun",
              colorHex: 0x4361EE, difficulty: .a2, estimatedMinutes: 9,
              summary: "Il fait beau, il pleut, l'été — și expresiile impersonale",
              orthoFocus: .silentLetters),
        .init(id: "08", slug: "verbs-present", title: "Verbe la prezent",
              frenchTitle: "Les verbes au présent", iconName: "gear",
              colorHex: 0x2A6DF4, difficulty: .a2, estimatedMinutes: 18,
              summary: "être, avoir, aller, faire — și terminația «-ent» care nu se aude",
              orthoFocus: .verbEndings),
        .init(id: "09", slug: "past", title: "Trecutul și acordurile",
              frenchTitle: "Le passé composé et les accords", iconName: "clock",
              colorHex: 0x2ED9A3, difficulty: .b1, estimatedMinutes: 22,
              summary: "être ou avoir ? Și acordul participiului — inima ortografiei",
              orthoFocus: .agreements),
        .init(id: "10", slug: "emotions", title: "Emoții și sentimente",
              frenchTitle: "Les émotions", iconName: "heart",
              colorHex: 0xFF7BA9, difficulty: .a2, estimatedMinutes: 10,
              summary: "Heureux, inquiet, ému — și femininele neregulate",
              orthoFocus: .plurals),
        .init(id: "11", slug: "work", title: "Munca și școala",
              frenchTitle: "Le travail et les études", iconName: "briefcase",
              colorHex: 0x4FD1F5, difficulty: .b1, estimatedMinutes: 15,
              summary: "Métiers, bureau, entretien — și dublele consoane din «professionnel»",
              orthoFocus: .doubleLetters),
        .init(id: "12", slug: "travel", title: "Călătorii în Franța",
              frenchTitle: "Voyager en France", iconName: "plane",
              colorHex: 0xE8C56A, difficulty: .b1, estimatedMinutes: 16,
              summary: "Gare, billet, hôtel — și circonflexul care ascunde un S",
              orthoFocus: .roTraps),
        .init(id: "13", slug: "culture", title: "Cultură franceză",
              frenchTitle: "La culture française", iconName: "theatre",
              colorHex: 0x8B6BFF, difficulty: .b2, estimatedMinutes: 18,
              summary: "Literatură, cinema, gastronomie — și numele proprii",
              orthoFocus: .silentLetters),
        .init(id: "14", slug: "writing", title: "Scrisul îngrijit",
              frenchTitle: "Écrire sans fautes", iconName: "quill",
              colorHex: 0xE4344A, difficulty: .c1, estimatedMinutes: 24,
              summary: "E-mail, scrisoare, eseu — toate regulile puse la treabă",
              orthoFocus: .agreements)
    ]

    /// Lookup sûr par slug — jamais d'index brut dans les vues.
    static func topic(slug: String) -> LessonTopic {
        curriculum.first(where: { $0.slug == slug }) ?? fallback
    }

    static func first(at level: ProficiencyLevel) -> LessonTopic {
        curriculum.first(where: { $0.difficulty == level }) ?? fallback
    }

    /// Thèmes accessibles à un niveau donné (le niveau et tout ce qui est en dessous).
    static func upTo(_ level: ProficiencyLevel) -> [LessonTopic] {
        let list = curriculum.filter { $0.difficulty <= level }
        return list.isEmpty ? curriculum : list
    }

    /// Filet de sécurité : garantit qu'aucun accès ne peut sortir du tableau.
    static let fallback = LessonTopic(
        id: "00", slug: "greetings", title: "Salutări și prezentare",
        frenchTitle: "Salutations et présentations", iconName: "greeting",
        colorHex: 0x2A6DF4, difficulty: .a1, estimatedMinutes: 8,
        summary: "Bonjour, enchanté, je m'appelle…", orthoFocus: .accents)
}

// =============================================================================
// MARK: - Vocabulaire
// =============================================================================

/// Une carte de vocabulaire. Trois champs sont propres à Limbator :
/// `spellingNote` (le piège orthographique du mot), `syllables` (découpe pour
/// l'épellation) et `silentLetters` (positions des lettres muettes).
struct VocabCard: Identifiable, Codable, Hashable {
    let id: UUID
    /// Le mot français, orthographe exacte.
    let french: String
    /// Transcription API.
    let phonetic: String
    /// Traduction dans la langue de l'apprenant (source roumaine).
    let translation: String
    /// Genre grammatical : "m", "f", "" (verbe, adverbe…).
    let gender: String
    let exampleSentence: String
    let exampleTranslation: String
    /// Le piège d'orthographe de ce mot, source roumaine. nil = pas de piège.
    let spellingNote: String?
    let category: String

    init(id: UUID = .init(), french: String, phonetic: String, translation: String,
         gender: String = "", exampleSentence: String, exampleTranslation: String,
         spellingNote: String? = nil, category: String) {
        self.id = id; self.french = french; self.phonetic = phonetic
        self.translation = translation; self.gender = gender
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.spellingNote = spellingNote; self.category = category
    }

    var localizedTranslation: String        { ContentL10n.s(translation) }
    var localizedExampleTranslation: String { ContentL10n.s(exampleTranslation) }
    var localizedSpellingNote: String?      { spellingNote.map(ContentL10n.s) }

    /// Article défini correct — utile pour afficher le genre sans ambiguïté.
    var withArticle: String {
        guard !gender.isEmpty else { return french }
        let first = french.lowercased().first.map(String.init) ?? ""
        // Élision devant voyelle ou h muet : on ne devine pas le h aspiré ici,
        // FrenchPhonology.startsWithAspirateH s'en charge.
        if "aeiouéèêàâîïôûù".contains(first) && !FrenchPhonology.startsWithAspirateH(french) {
            return "l'" + french
        }
        return (gender == "f" ? "la " : "le ") + french
    }

    /// Clé de maîtrise pour la répétition espacée.
    var masteryKey: String { "word:" + french.lowercased() }
}

// =============================================================================
// MARK: - Contenu de leçon
// =============================================================================

struct LessonContent: Identifiable, Codable {
    let id: UUID
    let topicSlug: String
    /// Texte d'introduction dans la langue de l'apprenant.
    let introduction: String
    let cards: [VocabCard]
    let phrases: [Phrase]
    /// Astuce de grammaire, source roumaine.
    let grammarTip: String?
    /// Note culturelle, source roumaine.
    let culturalNote: String?
    /// L'encadré orthographe de la leçon : la règle du jour, appliquée au thème.
    let orthoSpotlight: OrthoSpotlight?

    struct Phrase: Codable, Identifiable, Hashable {
        let id: UUID
        let french: String
        let translation: String
        /// Contexte d'emploi, source roumaine.
        let context: String

        init(id: UUID = .init(), french: String, translation: String, context: String) {
            self.id = id; self.french = french
            self.translation = translation; self.context = context
        }

        var localizedTranslation: String { ContentL10n.s(translation) }
        var localizedContext: String     { ContentL10n.s(context) }
    }

    /// L'encadré « orthographe » d'une leçon : une règle, deux exemples, un piège.
    struct OrthoSpotlight: Codable, Hashable {
        let module: OrthoModule
        /// Titre, source roumaine.
        let title: String
        /// Énoncé, source roumaine.
        let rule: String
        /// Paires (juste, faux) en français.
        let rightWrong: [Pair]

        struct Pair: Codable, Hashable, Identifiable {
            var id: String { right }
            let right: String
            let wrong: String
        }

        var localizedTitle: String { ContentL10n.s(title) }
        var localizedRule: String  { ContentL10n.s(rule) }
    }

    init(id: UUID = .init(), topicSlug: String, introduction: String,
         cards: [VocabCard], phrases: [Phrase],
         grammarTip: String? = nil, culturalNote: String? = nil,
         orthoSpotlight: OrthoSpotlight? = nil) {
        self.id = id; self.topicSlug = topicSlug
        self.introduction = introduction
        self.cards = cards; self.phrases = phrases
        self.grammarTip = grammarTip; self.culturalNote = culturalNote
        self.orthoSpotlight = orthoSpotlight
    }

    var localizedIntroduction: String { ContentL10n.s(introduction) }
    var localizedGrammarTip: String?  { grammarTip.map(ContentL10n.s) }
    var localizedCulturalNote: String? { culturalNote.map(ContentL10n.s) }
}
