import Foundation

/// Planificateur de révisions (SM-2).
///
/// Une règle d'orthographe comprise le lundi est oubliée le jeudi. La seule
/// parade connue est la répétition espacée : revoir chaque élément juste avant
/// de l'oublier, et espacer davantage à chaque succès. L'algorithme SM-2, publié
/// par Piotr Woźniak, fait exactement cela avec trois nombres par élément —
/// facilité, intervalle, nombre de réussites consécutives.
///
/// Deux familles d'éléments sont suivies : les **règles** (`rule:...`) et les
/// **mots** (`word:...`). L'orthographe se joue sur les deux.
@MainActor
final class SpacedRepetition: ObservableObject {
    static let shared = SpacedRepetition()

    @Published private(set) var records: [String: MasteryRecord] = [:]

    private let storageKey = "limb.mastery.v1"
    private let defaults: UserDefaults
    private let isEphemeral: Bool

    private init() {
        defaults = .standard
        isEphemeral = false
        load()
    }

    /// Instance isolée pour les aperçus et les tests : n'écrit jamais dans les
    /// réglages de l'utilisateur.
    init(preview seed: [String: MasteryRecord] = [:]) {
        defaults = UserDefaults(suiteName: "limb-preview-\(UUID().uuidString)") ?? .standard
        isEphemeral = true
        records = seed
    }

    // =========================================================================
    // MARK: - Clés
    // =========================================================================

    static func ruleKey(_ ruleId: String) -> String { "rule:" + ruleId }
    static func wordKey(_ french: String) -> String { "word:" + french.lowercased() }

    // =========================================================================
    // MARK: - Mise à jour
    // =========================================================================

    /// Enregistre une réponse et replanifie l'élément.
    ///
    /// `score` va de 0 à 1. SM-2 raisonne sur une note de 0 à 5 ; on convertit,
    /// et on considère qu'en dessous de 0,6 la réponse est un échec — seuil
    /// classique, qui remet l'élément au lendemain plutôt que de laisser filer
    /// un savoir fragile.
    @discardableResult
    func record(key: String, score: Double, now: Date = Date()) -> MasteryRecord {
        var record = records[key] ?? .fresh(key: key, now: now)
        let clamped = max(0, min(1, score))
        let quality = clamped * 5.0
        record.lastScore = clamped

        if clamped < 0.6 {
            // Échec : on repart de zéro sur les intervalles, mais on garde la
            // facilité acquise (moins un peu) — sinon un mauvais jour effacerait
            // des semaines d'apprentissage.
            record.repetitions = 0
            record.interval = 1
            record.lapses += 1
        } else {
            record.repetitions += 1
            switch record.repetitions {
            case 1:  record.interval = 1
            case 2:  record.interval = 6
            default: record.interval = Int((Double(record.interval) * record.easiness).rounded())
            }
        }

        // Formule SM-2 de mise à jour de la facilité.
        let delta = 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
        record.easiness = max(1.3, min(2.8, record.easiness + delta))
        record.interval = max(1, min(record.interval, 365))
        record.dueDate = Calendar.current.date(byAdding: .day, value: record.interval, to: now) ?? now

        records[key] = record
        persist()
        return record
    }

    func record(ruleId: String, score: Double) {
        record(key: Self.ruleKey(ruleId), score: score)
    }

    func record(word: String, score: Double) {
        record(key: Self.wordKey(word), score: score)
    }

    // =========================================================================
    // MARK: - Consultation
    // =========================================================================

    func mastery(key: String) -> MasteryRecord? { records[key] }

    func strength(ruleId: String) -> Double {
        records[Self.ruleKey(ruleId)]?.strength ?? 0
    }

    /// Maîtrise d'un module : moyenne des forces de ses règles. Les règles
    /// jamais travaillées comptent pour zéro — sinon un module à peine entamé
    /// afficherait fièrement 100 %.
    func mastery(of module: OrthoModule) -> Double {
        let rules = OrthoRules.rules(for: module)
        guard !rules.isEmpty else { return 0 }
        let total = rules.reduce(0.0) { $0 + strength(ruleId: $1.id) }
        return total / Double(rules.count)
    }

    /// Les éléments à revoir aujourd'hui, les plus en retard d'abord.
    func dueKeys(at date: Date = Date(), limit: Int = 20) -> [String] {
        records.values
            .filter { $0.isDue(at: date) }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(limit)
            .map(\.key)
    }

    /// Les règles à revoir aujourd'hui.
    func dueRules(at date: Date = Date(), limit: Int = 10) -> [OrthoRule] {
        dueKeys(at: date, limit: 200)
            .filter { $0.hasPrefix("rule:") }
            .compactMap { OrthoRules.rule(id: String($0.dropFirst(5))) }
            .prefix(limit)
            .map { $0 }
    }

    /// Les règles jamais travaillées, dans l'ordre du programme — ce que
    /// l'apprenant devrait découvrir ensuite.
    func nextUnseenRules(upTo level: ProficiencyLevel, limit: Int = 5) -> [OrthoRule] {
        OrthoRules.all
            .filter { $0.level <= level && records[Self.ruleKey($0.id)] == nil }
            .prefix(limit)
            .map { $0 }
    }

    /// Nombre de règles considérées comme acquises (intervalle d'au moins 21
    /// jours — le seuil au-delà duquel une notion tient sans révision rapprochée).
    var masteredRuleCount: Int {
        records.values.filter { $0.key.hasPrefix("rule:") && $0.interval >= 21 }.count
    }

    var trackedWordCount: Int {
        records.values.filter { $0.key.hasPrefix("word:") }.count
    }

    var masteredWordCount: Int {
        records.values.filter { $0.key.hasPrefix("word:") && $0.interval >= 21 }.count
    }

    // =========================================================================
    // MARK: - Persistance
    // =========================================================================

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: MasteryRecord].self, from: data)
        else { return }
        records = decoded
    }

    private func persist() {
        guard !isEphemeral, let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func reset() {
        records = [:]
        defaults.removeObject(forKey: storageKey)
    }
}
