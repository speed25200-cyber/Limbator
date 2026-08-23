import Foundation
import SwiftUI

/// Le profil, les séries, l'expérience, les badges — et le **profil de fautes**,
/// qui est ce que Limbator suit de plus utile : savoir qu'un apprenant se
/// trompe surtout sur les accords, et pas sur les accents, change ce qu'on lui
/// propose demain.
@MainActor
final class ProgressTracker: ObservableObject {
    static let shared = ProgressTracker()

    @Published var profile: UserProfile {
        didSet {
            persist()
            // L'interface suit la langue maternelle choisie, pas la langue du
            // système : un Roumain vivant en France veut Limbator en roumain.
            L.lang = profile.nativeLanguageId
        }
    }

    @Published var sessionMinutesToday: Int = 0
    /// Dernier badge décroché — l'interface s'en sert pour la célébration.
    @Published var freshBadge: Badge?

    private let storageKey: String
    private let defaults: UserDefaults
    private let isEphemeral: Bool

    private init() {
        storageKey = "limb.user.profile.v1"
        defaults = .standard
        isEphemeral = false
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = decoded
        } else {
            profile = .empty
        }
        breakStreakIfLapsed()
        // `didSet` ne se déclenche pas pour l'affectation initiale : on applique
        // la langue explicitement.
        L.lang = profile.nativeLanguageId
    }

    /// Instance isolée pour les aperçus et les tests.
    init(preview seed: UserProfile) {
        storageKey = "limb.preview.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: "limb-preview-\(UUID().uuidString)") ?? .standard
        isEphemeral = true
        profile = seed
        L.lang = seed.nativeLanguageId
    }

    // =========================================================================
    // MARK: - Expérience et badges
    // =========================================================================

    func awardXP(_ amount: Int) {
        guard amount > 0 else { return }
        profile.xp += amount
        if profile.xp >= 100 { unlock("first_word") }
    }

    func completeLesson(_ slug: String, xp: Int = 50) {
        let alreadyDone = profile.completedLessons.contains(slug)
        profile.completedLessons.insert(slug)
        // Une leçon refaite rapporte moins : on récompense l'avancée, pas la
        // répétition d'un acquis.
        awardXP(alreadyDone ? xp / 5 : xp)
        bumpStreak()
    }

    func unlock(_ code: String) {
        guard !profile.badgesEarned.contains(code), let badge = Badge.badge(code: code) else { return }
        profile.badgesEarned.insert(code)
        freshBadge = badge
    }

    func clearFreshBadge() { freshBadge = nil }

    // =========================================================================
    // MARK: - Dictées
    // =========================================================================

    /// Enregistre le résultat d'une dictée : moyenne, badges, profil de fautes.
    func recordDictation(_ verdict: OrthoVerdict) {
        let previousTotal = Double(profile.dictationsDone) * profile.dictationAverage
        profile.dictationsDone += 1
        profile.dictationAverage =
            (previousTotal + verdict.outOfTwenty) / Double(profile.dictationsDone)

        for mistake in verdict.mistakes {
            profile.mistakeCounts[mistake.kind.rawValue, default: 0] += 1
        }

        // Le barème : une dictée parfaite vaut nettement plus, parce qu'en
        // orthographe la différence entre 19 et 20 est la seule qui compte.
        let xp = verdict.isPerfect ? 120 : Int(40 + 60 * verdict.score)
        awardXP(xp)

        unlock("first_dictee")
        if verdict.isPerfect { unlock("dictee_20") }
        if profile.dictationsDone >= 10 { unlock("dictee_10") }
        bumpStreak()
    }

    /// Enregistre une faute isolée (exercice, jeu) dans le profil de fautes.
    func recordMistake(_ kind: OrthoErrorKind) {
        profile.mistakeCounts[kind.rawValue, default: 0] += 1
    }

    /// Vérifie si un module vient d'être maîtrisé et décerne le badge associé.
    func checkModuleMastery(_ module: OrthoModule, mastery: Double) {
        guard mastery >= 0.8 else { return }
        switch module {
        case .accents:    unlock("accent_master")
        case .homophones: unlock("homophone_pro")
        case .agreements: unlock("accord_expert")
        default: break
        }
    }

    // =========================================================================
    // MARK: - Séries
    // =========================================================================

    func bumpStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let last = profile.lastActiveDay {
            let lastDay = calendar.startOfDay(for: last)
            let gap = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if gap == 0 {
                // Déjà compté aujourd'hui.
            } else if gap == 1 {
                profile.streakDays += 1
            } else {
                profile.streakDays = 1
            }
        } else {
            profile.streakDays = 1
        }
        profile.bestStreak = max(profile.bestStreak, profile.streakDays)
        profile.lastActiveDay = today

        switch profile.streakDays {
        case 3:  unlock("streak_3")
        case 7:  unlock("streak_7")
        case 30: unlock("streak_30")
        default: break
        }
    }

    /// Au lancement : si plus d'un jour s'est écoulé, la série est rompue.
    /// Le record, lui, reste acquis.
    private func breakStreakIfLapsed() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let last = profile.lastActiveDay else { return }
        let lastDay = calendar.startOfDay(for: last)
        let gap = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        if gap > 1 { profile.streakDays = 0 }
    }

    // =========================================================================
    // MARK: - Lecture
    // =========================================================================

    /// Le module que l'apprenant devrait travailler en priorité : celui où il
    /// se trompe le plus. À égalité (ou au tout début, quand il n'y a aucune
    /// faute enregistrée) on renvoie le premier module de son niveau.
    var priorityModule: OrthoModule {
        if let worst = profile.topWeaknesses.first { return worst.module }
        return OrthoModule.allCases.first { $0.entryLevel <= profile.level } ?? .accents
    }

    /// Progression vers l'objectif du jour, entre 0 et 1.
    var dailyProgress: Double {
        guard profile.dailyGoalMinutes > 0 else { return 0 }
        return min(1, Double(sessionMinutesToday) / Double(profile.dailyGoalMinutes))
    }

    var earnedBadges: [Badge] {
        Badge.catalog.filter { profile.badgesEarned.contains($0.code) }
    }

    // =========================================================================
    // MARK: - Persistance
    // =========================================================================

    private func persist() {
        guard !isEphemeral, let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func reset() {
        profile = .empty
        defaults.removeObject(forKey: storageKey)
        SpacedRepetition.shared.reset()
    }
}
