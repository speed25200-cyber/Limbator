import Foundation
import SwiftUI

/// Les dix mini-jeux. Les trois derniers (`dictation`, `accentHunt`,
/// `homophoneDuel`) sont spécifiques à Limbator : ils entraînent l'orthographe,
/// pas seulement le vocabulaire.
enum GameKind: String, CaseIterable, Identifiable, Codable {
    case match
    case wordPuzzle
    case listening
    case speaking
    case flashRecall
    case storyChoice
    case wheelOfFortune
    case dictation
    case accentHunt
    case homophoneDuel

    var id: String { rawValue }

    /// Titre source en roumain (localisé à l'affichage).
    var title: String {
        switch self {
        case .match:          return "Perechi"
        case .wordPuzzle:     return "Construiește fraza"
        case .listening:      return "Ureche fină"
        case .speaking:       return "Studio vocal"
        case .flashRecall:    return "Flash memorie"
        case .storyChoice:    return "Alege-ți drumul"
        case .wheelOfFortune: return "Roata Parisului"
        case .dictation:      return "Dictare fulger"
        case .accentHunt:     return "Vânătoare de accente"
        case .homophoneDuel:  return "Duel de homofone"
        }
    }

    var subtitle: String {
        switch self {
        case .match:          return "Leagă franceza de română"
        case .wordPuzzle:     return "Pune cuvintele în ordine"
        case .listening:      return "Recunoaște ce auzi"
        case .speaking:       return "Pronunția ta, notată de IA"
        case .flashRecall:    return "Trei secunde per carte"
        case .storyChoice:    return "O scenă, mai multe căi"
        case .wheelOfFortune: return "Norocul îți alege proba"
        case .dictation:      return "Scrie exact ce auzi"
        case .accentHunt:     return "Pune accentele la locul lor"
        case .homophoneDuel:  return "a sau à ? ce sau se ?"
        }
    }

    var localizedTitle: String    { ContentL10n.s(title) }
    var localizedSubtitle: String { ContentL10n.s(subtitle) }

    var icon: LimbIcon {
        switch self {
        case .match:          return .layers
        case .wordPuzzle:     return .puzzlePiece
        case .listening:      return .ear
        case .speaking:       return .micFill
        case .flashRecall:    return .lightning
        case .storyChoice:    return .fork
        case .wheelOfFortune: return .wheel
        case .dictation:      return .quill
        case .accentHunt:     return .accent
        case .homophoneDuel:  return .duel
        }
    }

    var color: Color {
        switch self {
        case .match:          return Theme.bleuFrance
        case .wordPuzzle:     return Theme.lavande
        case .listening:      return Theme.azur
        case .speaking:       return Theme.grenat
        case .flashRecall:    return Theme.or
        case .storyChoice:    return Theme.emeraude
        case .wheelOfFortune: return Theme.rose
        case .dictation:      return Color(hex: 0x6C7BFF)
        case .accentHunt:     return Color(hex: 0xD9A441)
        case .homophoneDuel:  return Color(hex: 0xB06BFF)
        }
    }

    /// Le jeu entraîne-t-il directement l'orthographe ?
    var isOrthographic: Bool {
        switch self {
        case .dictation, .accentHunt, .homophoneDuel: return true
        default: return false
        }
    }
}

/// Un tour de jeu à choix multiple. `correctIndex` est **toujours** validé à la
/// construction : il ne peut pas sortir des bornes de `options`.
struct GameRound: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: String
    /// La consigne, déjà localisée.
    let prompt: String
    /// La cible française (mot ou phrase) — c'est elle que lit la voix.
    let frenchTarget: String
    let options: [String]
    let correctIndex: Int
    /// Explication facultative affichée après la réponse (déjà localisée).
    let explanation: String?

    init(id: UUID = .init(), kind: String, prompt: String,
         frenchTarget: String, options: [String], correctIndex: Int,
         explanation: String? = nil) {
        self.id = id; self.kind = kind; self.prompt = prompt
        self.frenchTarget = frenchTarget
        self.options = options
        // Verrou anti-crash : un index hors bornes rendrait tout le round injouable.
        self.correctIndex = options.isEmpty ? 0 : min(max(0, correctIndex), options.count - 1)
        self.explanation = explanation
    }

    /// Le round est-il exploitable ? (au moins deux options, une cible non vide)
    var isPlayable: Bool { options.count >= 2 && !frenchTarget.isEmpty }

    var correctAnswer: String {
        options.indices.contains(correctIndex) ? options[correctIndex] : ""
    }
}

struct GameScore: Codable, Hashable {
    var correct: Int = 0
    var total: Int = 0
    var streak: Int = 0
    var bestStreak: Int = 0
    var xpEarned: Int = 0

    var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }

    mutating func register(correct isRight: Bool, xp: Int) {
        total += 1
        if isRight {
            correct += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
            xpEarned += xp
        } else {
            streak = 0
        }
    }
}
