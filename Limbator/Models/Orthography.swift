import Foundation
import SwiftUI

// =============================================================================
// MARK: - Modules d'orthographe
// =============================================================================

/// Les huit chantiers de l'orthographe française couverts par Limbator.
/// Chaque module a ses règles (`OrthoRule`), ses exercices (`OrthoDrill`) et
/// son propre indicateur de maîtrise, entraîné par répétition espacée.
enum OrthoModule: String, CaseIterable, Identifiable, Codable {
    case accents            // é è ê ë à â î ï ô ù û ç
    case homophones         // a/à, ou/où, ces/ses/c'est/s'est…
    case verbEndings        // -é / -er / -ez, -ai / -ais, -ent muet
    case agreements         // accord du participe passé, de l'adjectif
    case plurals            // -al/-aux, -ou/-oux, féminins irréguliers
    case doubleLetters      // consonnes doubles : appeler, adresse, attention
    case silentLetters      // lettres finales muettes, h muet / h aspiré
    case roTraps            // pièges roumain -> français (cognats, genres, circonflexe)

    var id: String { rawValue }

    /// Titre source en roumain (traduit à l'affichage par ContentL10n).
    var title: String {
        switch self {
        case .accents:       return "Accente"
        case .homophones:    return "Homofone"
        case .verbEndings:   return "Terminații verbale"
        case .agreements:    return "Acorduri"
        case .plurals:       return "Plurale și feminine"
        case .doubleLetters: return "Consoane duble"
        case .silentLetters: return "Litere mute"
        case .roTraps:       return "Capcane româno-franceze"
        }
    }

    var subtitle: String {
        switch self {
        case .accents:       return "é è ê ë à â î ï ô û ç — unde și de ce"
        case .homophones:    return "a / à, ou / où, c'est / s'est, ces / ses"
        case .verbEndings:   return "-é, -er, -ez : testul cu «vendre»"
        case .agreements:    return "Participiul trecut cu être și avoir"
        case .plurals:       return "-al → -aux, bijou, caillou, chou…"
        case .doubleLetters: return "appeler, adresse, attention"
        case .silentLetters: return "petit, grand, temps — și h mut"
        case .roTraps:       return "fereastră → fenêtre : S-ul devine accent"
        }
    }

    var localizedTitle: String { ContentL10n.s(title) }
    var localizedSubtitle: String { ContentL10n.s(subtitle) }

    var iconName: String {           // SF Symbol
        switch self {
        case .accents:       return "textformat.abc.dottedunderline"
        case .homophones:    return "arrow.triangle.branch"
        case .verbEndings:   return "text.append"
        case .agreements:    return "link"
        case .plurals:       return "square.stack.3d.up.fill"
        case .doubleLetters: return "square.on.square"
        case .silentLetters: return "speaker.slash.fill"
        case .roTraps:       return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .accents:       return Theme.or
        case .homophones:    return Theme.lavande
        case .verbEndings:   return Theme.bleuFrance
        case .agreements:    return Theme.emeraude
        case .plurals:       return Theme.azur
        case .doubleLetters: return Theme.rose
        case .silentLetters: return Color(hex: 0x9AA7C7)
        case .roTraps:       return Theme.grenat
        }
    }

    /// Niveau à partir duquel le module devient pertinent.
    var entryLevel: ProficiencyLevel {
        switch self {
        case .accents, .doubleLetters, .roTraps: return .a1
        case .homophones, .silentLetters:        return .a2
        case .verbEndings, .plurals:             return .a2
        case .agreements:                        return .b1
        }
    }
}

// =============================================================================
// MARK: - Règles
// =============================================================================

/// Un exemple canonique attaché à une règle : la forme juste, la faute typique,
/// et le sens dans la langue de l'apprenant.
struct OrthoExample: Codable, Hashable, Identifiable {
    var id: String { correct }
    /// Forme correcte en français.
    let correct: String
    /// Forme fautive fréquente (nil si la règle n'a pas de faute canonique).
    let wrong: String?
    /// Sens / commentaire dans la langue maternelle (source roumaine).
    let gloss: String
}

/// Une règle d'orthographe : énoncé, exemples, exceptions, moyen mnémotechnique.
/// L'`id` est stable — il sert de clé de maîtrise pour la répétition espacée.
struct OrthoRule: Identifiable, Codable, Hashable {
    let id: String                 // ex. "accents.cedille"
    let module: OrthoModule
    let title: String              // source roumaine
    let statement: String          // l'énoncé de la règle, source roumaine
    let examples: [OrthoExample]
    let exceptions: [String]       // formes en français, telles quelles
    let mnemonic: String?          // truc de mémorisation, source roumaine
    let level: ProficiencyLevel

    var localizedTitle: String     { ContentL10n.s(title) }
    var localizedStatement: String { ContentL10n.s(statement) }
    var localizedMnemonic: String? { mnemonic.map(ContentL10n.s) }
}

// =============================================================================
// MARK: - Homophones
// =============================================================================

/// Une famille d'homophones : plusieurs graphies pour un même son.
/// Le cœur pédagogique est le `test` de substitution, seul moyen fiable de
/// choisir la bonne graphie.
struct HomophoneSet: Identifiable, Codable, Hashable {
    let id: String                 // ex. "a-a-accent"
    let sound: String              // notation API, ex. "/a/"
    let level: ProficiencyLevel
    let members: [Member]

    struct Member: Codable, Hashable, Identifiable {
        var id: String { form }
        /// La graphie française, ex. "à".
        let form: String
        /// Nature grammaticale, source roumaine, ex. "prepoziție".
        let nature: String
        /// Test de substitution, source roumaine, ex. "Nu poate fi înlocuit cu «avait»".
        let test: String
        /// Phrase d'exemple en français.
        let example: String
        /// Traduction de l'exemple, source roumaine.
        let gloss: String

        var localizedNature: String { ContentL10n.s(nature) }
        var localizedTest: String   { ContentL10n.s(test) }
        var localizedGloss: String  { ContentL10n.s(gloss) }
    }

    /// Les graphies de la famille, dans l'ordre déclaré.
    var forms: [String] { members.map(\.form) }

    func member(_ form: String) -> Member? {
        members.first { $0.form == form }
    }
}

// =============================================================================
// MARK: - Exercices
// =============================================================================

/// Un exercice d'orthographe unitaire.
///
/// `sentence` contient toujours le marqueur `___` à l'emplacement de la réponse,
/// sauf pour `.correction` où la phrase est fournie **fautive** et doit être
/// réécrite. `answer` est la forme attendue exacte (accents compris).
struct OrthoDrill: Identifiable, Codable, Hashable {
    let id: UUID
    let ruleId: String
    let module: OrthoModule
    let kind: Kind
    /// Consigne dans la langue de l'apprenant (source roumaine).
    let instruction: String
    /// La phrase française, avec `___` là où la réponse s'insère.
    let sentence: String
    /// La réponse exacte attendue.
    let answer: String
    /// Propositions fausses (QCM). Vide pour la saisie libre.
    let distractors: [String]
    /// Explication après réponse, source roumaine.
    let explanation: String
    /// L'exercice a-t-il été écrit par Gemma ?
    ///
    /// L'interface le signale. Ce n'est pas une coquetterie : l'apprenant a le
    /// droit de savoir ce qui vient d'un contenu vérifié et ce qui vient d'un
    /// modèle — même quand, comme ici, la bonne réponse reste juste par
    /// construction.
    let isGenerated: Bool

    enum Kind: String, Codable, CaseIterable {
        case choice       // QCM : choisir la bonne graphie
        case fill         // saisie libre du mot manquant
        case accent       // (dés)accentuer un mot proposé sans accent
        case correction   // repérer et corriger la faute dans la phrase
    }

    init(id: UUID = .init(), ruleId: String, module: OrthoModule, kind: Kind,
         instruction: String, sentence: String, answer: String,
         distractors: [String] = [], explanation: String,
         isGenerated: Bool = false) {
        self.id = id; self.ruleId = ruleId; self.module = module; self.kind = kind
        self.instruction = instruction; self.sentence = sentence
        self.answer = answer; self.distractors = distractors
        self.explanation = explanation
        self.isGenerated = isGenerated
    }

    var localizedInstruction: String { ContentL10n.s(instruction) }
    var localizedExplanation: String { ContentL10n.s(explanation) }

    /// La phrase complète, réponse insérée — c'est elle que la voix lit.
    var solvedSentence: String {
        sentence.replacingOccurrences(of: "___", with: answer)
    }

    /// Options mélangées de façon déterministe (l'ordre ne bouge pas entre deux
    /// rendus SwiftUI de la même question, sinon l'utilisateur voit les boutons
    /// sauter à chaque redessin).
    var shuffledOptions: [String] {
        let all = ([answer] + distractors)
        guard all.count > 1 else { return all }
        // Tri stable par empreinte (id + option) : aléatoire à l'œil, constant en mémoire.
        return all.sorted { lhs, rhs in
            OrthoDrill.seedHash(id.uuidString + lhs) < OrthoDrill.seedHash(id.uuidString + rhs)
        }
    }

    /// Empreinte déterministe (FNV-1a 64 bits) — indépendante du `hashValue`
    /// Swift, qui est volontairement randomisé à chaque lancement du processus.
    static func seedHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in s.utf8 {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01B3
        }
        return h
    }
}

// =============================================================================
// MARK: - Dictée
// =============================================================================

/// Une dictée : une phrase française lue par la voix neurale, que l'apprenant
/// doit écrire exactement. Le cœur de l'app.
struct DictationItem: Identifiable, Codable, Hashable {
    let id: UUID
    /// Le texte français exact (ponctuation et majuscules comprises).
    let text: String
    /// Traduction dans la langue de l'apprenant (source roumaine).
    let translation: String
    let level: ProficiencyLevel
    /// Identifiants des règles réellement mises à l'épreuve par cette phrase.
    let targetRules: [String]
    /// Indice facultatif affiché avant l'écoute (source roumaine).
    let hint: String?
    /// Thème (pour filtrer / varier).
    let theme: String

    init(id: UUID = .init(), text: String, translation: String,
         level: ProficiencyLevel, targetRules: [String] = [],
         hint: String? = nil, theme: String = "general") {
        self.id = id; self.text = text; self.translation = translation
        self.level = level; self.targetRules = targetRules
        self.hint = hint; self.theme = theme
    }

    var localizedTranslation: String { ContentL10n.s(translation) }
    var localizedHint: String? { hint.map(ContentL10n.s) }

    /// Nombre de mots — sert à calibrer la difficulté et le barème.
    var wordCount: Int {
        text.split(whereSeparator: { $0 == " " || $0 == "\u{00A0}" }).count
    }
}

// =============================================================================
// MARK: - Diagnostic d'erreur
// =============================================================================

/// Taxonomie pédagogique des fautes d'orthographe françaises.
/// C'est elle qui transforme un simple « faux » en leçon utilisable.
enum OrthoErrorKind: String, Codable, CaseIterable, Hashable {
    case accentMissing        // eleve -> élève
    case accentWrong          // élève écrit «élêve» / «éleve»
    case accentExtra          // «bélle» pour «belle»
    case cedillaMissing       // francais -> français
    case cedillaExtra         // «çe» pour «ce»
    case tremaMissing         // «Noel» -> «Noël»
    case doubleConsonant      // «apeler» -> «appeler» (ou l'inverse)
    case silentLetter         // «peti» -> «petit»
    case homophone            // «a» pour «à» : même son, autre mot
    case verbEnding           // «manger» pour «mangé»
    case agreement            // «les fleurs cueilli» -> «cueillies»
    case elision              // «le ami» -> «l'ami»
    case apostrophe           // apostrophe absente ou mal placée
    case hyphen               // trait d'union manquant / en trop
    case ligature             // «oeuf» -> «œuf»
    case capitalization       // majuscule manquante ou parasite
    case punctuation          // point, virgule, point d'interrogation
    case spacing              // espace (fine insécable devant ; : ! ?)
    case romanianInterference // graphie calquée sur le roumain
    case wordOrder            // mots intervertis
    case missingWord          // mot oublié
    case extraWord            // mot en trop
    case typo                 // faute de frappe sans catégorie

    /// Libellé court, source roumaine.
    var label: String {
        switch self {
        case .accentMissing:        return "Accent lipsă"
        case .accentWrong:          return "Accent greșit"
        case .accentExtra:          return "Accent în plus"
        case .cedillaMissing:       return "Sedilă lipsă (ç)"
        case .cedillaExtra:         return "Sedilă în plus"
        case .tremaMissing:         return "Tremă lipsă (ë ï ü)"
        case .doubleConsonant:      return "Consoană dublă"
        case .silentLetter:         return "Literă mută"
        case .homophone:            return "Homofon"
        case .verbEnding:           return "Terminație verbală"
        case .agreement:            return "Acord"
        case .elision:              return "Eliziune (l')"
        case .apostrophe:           return "Apostrof"
        case .hyphen:               return "Cratimă"
        case .ligature:             return "Ligatură (œ æ)"
        case .capitalization:       return "Majusculă"
        case .punctuation:          return "Punctuație"
        case .spacing:              return "Spațiere"
        case .romanianInterference: return "Influență din română"
        case .wordOrder:            return "Ordinea cuvintelor"
        case .missingWord:          return "Cuvânt lipsă"
        case .extraWord:            return "Cuvânt în plus"
        case .typo:                 return "Greșeală de tastare"
        }
    }

    var localizedLabel: String { ContentL10n.s(label) }

    /// Module d'entraînement recommandé pour corriger ce type de faute.
    var module: OrthoModule {
        switch self {
        case .accentMissing, .accentWrong, .accentExtra,
             .cedillaMissing, .cedillaExtra, .tremaMissing: return .accents
        case .homophone:                                    return .homophones
        case .verbEnding:                                   return .verbEndings
        case .agreement:                                    return .agreements
        case .doubleConsonant:                              return .doubleLetters
        case .silentLetter:                                 return .silentLetters
        case .romanianInterference:                         return .roTraps
        case .elision, .apostrophe, .hyphen, .ligature,
             .capitalization, .punctuation, .spacing,
             .wordOrder, .missingWord, .extraWord, .typo:   return .accents
        }
    }

    /// Poids dans le barème : toutes les fautes ne se valent pas.
    /// 1.0 = faute pleine ; 0.3 = broutille typographique.
    var weight: Double {
        switch self {
        case .homophone, .agreement, .verbEnding,
             .missingWord, .extraWord, .wordOrder:          return 1.0
        case .romanianInterference, .doubleConsonant,
             .silentLetter, .elision:                       return 0.8
        case .accentMissing, .accentWrong, .accentExtra,
             .cedillaMissing, .cedillaExtra, .tremaMissing: return 0.6
        case .apostrophe, .hyphen, .ligature:               return 0.5
        case .capitalization, .punctuation, .spacing:       return 0.3
        case .typo:                                         return 0.7
        }
    }

    var color: Color {
        switch self {
        case .homophone, .agreement, .verbEnding, .missingWord,
             .extraWord, .wordOrder:                        return Theme.grenat
        case .romanianInterference:                         return Theme.rose
        case .doubleConsonant, .silentLetter, .elision:     return Theme.lavande
        case .accentMissing, .accentWrong, .accentExtra,
             .cedillaMissing, .cedillaExtra, .tremaMissing: return Theme.or
        default:                                            return Color(hex: 0x9AA7C7)
        }
    }
}

/// Une faute repérée, localisée et expliquée.
struct OrthoMistake: Identifiable, Hashable {
    let id = UUID()
    let kind: OrthoErrorKind
    /// Le mot attendu (forme correcte).
    let expected: String
    /// Ce que l'apprenant a écrit (vide si le mot manque).
    let written: String
    /// Index du mot dans la phrase attendue (0-based, -1 si mot en trop).
    let wordIndex: Int
    /// Explication ciblée, déjà localisée au moment de la construction.
    let explanation: String
    /// Règle à réviser, si identifiée.
    let ruleId: String?
}

/// Résultat complet de la correction d'une dictée ou d'une saisie libre.
struct OrthoVerdict: Hashable {
    let expected: String
    let written: String
    /// 0…1 — 1 = parfait.
    let score: Double
    let mistakes: [OrthoMistake]
    /// Rendu caractère par caractère pour l'affichage coloré.
    let segments: [DiffSegment]

    var isPerfect: Bool { mistakes.isEmpty }

    /// Note sur 20, à la française — le barème que tout élève français connaît.
    var outOfTwenty: Double { (score * 20).rounded(toPlaces: 1) }

    struct DiffSegment: Hashable, Identifiable {
        let id = UUID()
        let text: String
        let state: State
        enum State: Hashable { case correct, wrong, missing, extra }
    }

    static let empty = OrthoVerdict(expected: "", written: "", score: 0,
                                    mistakes: [], segments: [])
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let d = pow(10.0, Double(max(0, places)))
        return (self * d).rounded() / d
    }
}

// =============================================================================
// MARK: - Maîtrise (répétition espacée)
// =============================================================================

/// État SM-2 d'un item entraîné (règle d'orthographe ou carte de vocabulaire).
struct MasteryRecord: Codable, Hashable, Identifiable {
    var id: String { key }
    /// Clé stable : `"rule:accents.cedille"` ou `"word:fenêtre"`.
    let key: String
    var easiness: Double        // facteur SM-2, borné [1.3 ; 2.8]
    var interval: Int           // en jours
    var repetitions: Int
    var dueDate: Date
    var lapses: Int
    var lastScore: Double       // dernière note 0…1

    static func fresh(key: String, now: Date = Date()) -> MasteryRecord {
        MasteryRecord(key: key, easiness: 2.5, interval: 0, repetitions: 0,
                      dueDate: now, lapses: 0, lastScore: 0)
    }

    /// 0…1 — à quel point l'item est ancré (intervalle rapporté à 60 jours).
    var strength: Double {
        min(1.0, Double(interval) / 60.0)
    }

    func isDue(at date: Date = Date()) -> Bool { dueDate <= date }
}
