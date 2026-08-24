import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MLX ne tourne QUE sur un appareil réel. Sur le simulateur iOS, le runtime
// C++/Metal de MLX s'interrompt (SIGABRT) au chargement — l'app planterait au
// lancement, et les tests hébergés par l'app avant même de démarrer. Le drapeau
// LIMB_MLX_REAL est posé par project.yml pour le seul SDK iphoneos : appareil
// réel = vrai Gemma 4, simulateur/aperçus/CI = moteur déterministe.
#if LIMB_MLX_REAL
import MLX
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
#if canImport(HuggingFace)
import HuggingFace
#endif
#if canImport(Tokenizers)
import Tokenizers
#endif
#endif

/// **Gemma 4 4B**, en 4 bits, tournant entièrement sur l'iPhone via MLX-Swift
/// (Neural Engine + Metal).
///
/// Cycle de vie :
///   • premier lancement -> téléchargement depuis HuggingFace, en morceaux
///     parallèles, puis cache local ;
///   • lancements suivants -> 100 % hors ligne ;
///   • MLX absent (aperçus, simulateur, CI) -> moteur déterministe, l'app reste
///     entièrement utilisable grâce au contenu embarqué.
///
/// L'app n'est **jamais** bloquée par ce service : tout le contenu pédagogique
/// existe hors ligne. Gemma enrichit, il ne conditionne pas.
@MainActor
final class GemmaService: ObservableObject {
    static let shared = GemmaService()

    // =========================================================================
    // MARK: - Choix du modèle
    // =========================================================================

    /// Les dépôts candidats, dans l'ordre de préférence.
    ///
    /// Limbator vise **Gemma 4 4B** : c'est le meilleur rapport qualité/mémoire
    /// pour du français correct — un modèle plus petit hésite sur les accords et
    /// invente des accents. On garde toutefois une variante plus légère en
    /// second : sur un iPhone dont la mémoire est déjà entamée, mieux vaut un
    /// modèle qui se charge qu'un modèle idéal que le système tue (jetsam).
    /// Le choix se fait au premier lancement et se retient.
    enum Variant: String, CaseIterable {
        case gemma4_4b  = "mlx-community/gemma-4-4b-it-4bit"
        case gemma4_e2b = "mlx-community/gemma-4-e2b-it-4bit"

        /// Nom court, pour l'affichage.
        var label: String {
            switch self {
            case .gemma4_4b:  return "Gemma 4 · 4B"
            case .gemma4_e2b: return "Gemma 4 · E2B"
            }
        }

        /// Taille approximative du téléchargement, en gigaoctets.
        var approximateGigabytes: Double {
            switch self {
            case .gemma4_4b:  return 2.6
            case .gemma4_e2b: return 3.6
            }
        }

        /// Dossier de cache — le nom encode la variante : changer de modèle ne
        /// peut donc pas mélanger deux jeux de poids.
        var directoryName: String { "LimbatorMLX_" + rawValue.replacingOccurrences(of: "/", with: "_") }
    }

    @Published private(set) var isReady: Bool = false
    @Published private(set) var isWarmingUp: Bool = false
    @Published private(set) var bootProgress: Double = 0
    @Published private(set) var statusMessage: String = "Pregătim Gemma…"
    @Published private(set) var lastError: String?
    @Published private(set) var loadFailed: Bool = false

    /// La variante retenue. Persistée : une fois qu'un modèle s'est chargé sur
    /// cet appareil, on ne rejoue pas la sélection à chaque lancement.
    @Published private(set) var variant: Variant = {
        let stored = UserDefaults.standard.string(forKey: "limb.gemma.variant") ?? ""
        return Variant(rawValue: stored) ?? .gemma4_4b
    }()

    private var generationTask: Task<Void, Never>?

    #if LIMB_MLX_REAL
    private var container: ModelContainer?
    #endif

    // =========================================================================
    // MARK: - Stockage
    // =========================================================================

    /// Les poids vivent dans Application Support, exclus de la sauvegarde iCloud
    /// (plusieurs gigaoctets qu'il serait absurde de synchroniser).
    var modelDirectory: URL { directory(for: variant) }

    func directory(for variant: Variant) -> URL {
        // `urls(for:in:)` renvoie un tableau : l'indexer directement serait un
        // arrêt brutal si le sandbox refusait le domaine. Le repli sur le
        // dossier temporaire garde l'app vivante, quitte à retélécharger.
        let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = support.appendingPathComponent(variant.directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutable = dir
            try? mutable.setResourceValues(values)
        }
        return dir
    }

    /// Le modèle est complet si config.json, tokenizer.json et au moins un
    /// fichier de poids **réel** sont présents. Le seuil de taille n'est pas
    /// cosmétique : un `.safetensors` tronqué (téléchargement coupé) passerait
    /// pour valide, MLX chargerait des poids corrompus et l'app planterait en
    /// boucle au lancement.
    var isModelComplete: Bool { isModelComplete(for: variant) }

    func isModelComplete(for variant: Variant) -> Bool {
        let fm = FileManager.default
        let dir = directory(for: variant)
        let config = dir.appendingPathComponent("config.json")
        let tokenizer = dir.appendingPathComponent("tokenizer.json")
        guard fm.fileExists(atPath: config.path),
              fm.fileExists(atPath: tokenizer.path),
              let contents = try? fm.contentsOfDirectory(atPath: dir.path) else { return false }
        return contents.contains { name in
            guard name.hasSuffix(".safetensors") else { return false }
            let path = dir.appendingPathComponent(name).path
            let size = ((try? fm.attributesOfItem(atPath: path))?[.size] as? Int64) ?? 0
            return size > 100 * 1024 * 1024
        }
    }

    private func remember(_ variant: Variant) {
        self.variant = variant
        UserDefaults.standard.set(variant.rawValue, forKey: "limb.gemma.variant")
    }

    private init() {}

    // =========================================================================
    // MARK: - Chargement
    // =========================================================================

    func warmUp() async {
        guard !isWarmingUp else { return }
        if isReady && !loadFailed { return }

        // Coupe-circuit anti boucle de plantage.
        //
        // Charger plusieurs gigaoctets de poids peut faire tuer l'app par iOS
        // (watchdog, jetsam) — sans exception Swift à rattraper, puisque le
        // processus meurt. On pose donc une trace AVANT le chargement risqué et
        // on la retire après. Si elle est encore là au lancement suivant, c'est
        // que le précédent est mort en route. À la troisième mort d'affilée, on
        // renonce pour cette session : l'app reste parfaitement utilisable hors
        // ligne, et le lancement d'après retentera à zéro.
        let defaults = UserDefaults.standard
        if hasBreadcrumb {
            let deaths = defaults.integer(forKey: Self.crashCountKey) + 1
            defaults.set(deaths, forKey: Self.crashCountKey)
            if deaths >= 3 {
                clearBreadcrumb(resetCount: true)
                lastError = L.t("gemma.error.repeated_failure")
                statusMessage = L.t("gemma.status.offline")
                loadFailed = true
                isReady = true
                return
            }
        }

        isWarmingUp = true
        loadFailed = false
        lastError = nil
        statusMessage = L.t("gemma.status.starting")

        // Le téléchargement dure plusieurs minutes. iOS suspend l'app au
        // verrouillage et la session URLSession meurt avec elle : on garde
        // l'écran allumé le temps du chargement, puis on rend la main.
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = true
        #endif

        do {
            try await loadModel { @Sendable [weak self] progress, label in
                Task { @MainActor in
                    self?.bootProgress = progress
                    self?.statusMessage = label
                }
            }
            statusMessage = L.t("gemma.status.ready")
            loadFailed = false
            isReady = true
        } catch {
            // Erreur Swift propre (pas une mort du processus) : on retire la
            // trace pour ne pas la confondre avec un plantage natif.
            clearBreadcrumb()
            lastError = "\(variant.label) — \(error.localizedDescription)"
            statusMessage = L.t("gemma.status.offline")
            loadFailed = true
            // On reste « prêt » : le contenu embarqué suffit à tout faire.
            isReady = true
        }

        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
        isWarmingUp = false
    }

    /// Nouvelle tentative explicite (bouton des réglages) : on réarme tout.
    func retryLoad() async {
        clearBreadcrumb(resetCount: true)
        loadFailed = false
        isReady = false
        await warmUp()
    }

    // =========================================================================
    // MARK: - Trace de plantage
    // =========================================================================
    //
    // La trace doit survivre à une **mort du processus** : c'est toute sa
    // raison d'être. `UserDefaults` écrit sur disque quand il le décide, et
    // l'app peut être tuée dans la seconde qui suit la pose de la trace — les
    // allocations Metal échouent parfois d'emblée. Une trace perdue, c'est le
    // coupe-circuit qui ne se déclenche jamais et l'app qui meurt au lancement
    // indéfiniment. On écrit donc un fichier, de façon atomique et synchrone.

    private static let breadcrumbFileName = "gemma-loading.breadcrumb"
    private static let crashCountKey      = "limb.gemma.loadCrashCount.v1"

    private var breadcrumbURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent(Self.breadcrumbFileName)
    }

    private var hasBreadcrumb: Bool {
        FileManager.default.fileExists(atPath: breadcrumbURL.path)
    }

    private func placeBreadcrumb() {
        // `.atomic` force l'écriture avant le retour : c'est exactement la
        // garantie qui manquait.
        try? Data("loading".utf8).write(to: breadcrumbURL, options: .atomic)
    }

    private func clearBreadcrumb(resetCount: Bool = false) {
        try? FileManager.default.removeItem(at: breadcrumbURL)
        if resetCount { UserDefaults.standard.set(0, forKey: Self.crashCountKey) }
    }

    private func loadModel(progress: @Sendable @escaping (Double, String) -> Void) async throws {
        #if LIMB_MLX_REAL
        // 1) Télécharger si nécessaire. On essaie les variantes dans l'ordre :
        //    si le dépôt visé n'existe pas ou refuse le téléchargement, on
        //    bascule sur la suivante plutôt que de laisser l'app sans modèle.
        if !isModelComplete {
            var lastFailure: Error?
            for candidate in Variant.allCases {
                if isModelComplete(for: candidate) { remember(candidate); break }
                remember(candidate)
                progress(0, L.t("gemma.status.downloading", candidate.label))
                let mirror = Task { @MainActor [weak self] in
                    while !Task.isCancelled {
                        let value = MLXModelDownloader.shared.overallProgress
                        self?.bootProgress = value * 0.95
                        self?.statusMessage = L.t("gemma.status.downloading_percent",
                                                  candidate.label, Int(value * 100))
                        try? await Task.sleep(nanoseconds: 300_000_000)
                    }
                }
                await MLXModelDownloader.shared.ensureDownloaded(repo: candidate.rawValue,
                                                                 into: directory(for: candidate))
                mirror.cancel()
                if isModelComplete(for: candidate) { break }
                if case .error(let message) = MLXModelDownloader.shared.state {
                    lastFailure = GemmaError.downloadFailed(message)
                }
            }
            guard isModelComplete else {
                throw lastFailure ?? GemmaError.downloadFailed(L.t("gemma.error.incomplete"))
            }
        }

        // 2) Retirer la configuration audio : Limbator est un projet texte, et
        //    le module audio de gemma4 n'est pas implémenté côté mlx-swift-lm —
        //    sa construction déclenche une interruption C non rattrapable.
        progress(0.96, L.t("gemma.status.preparing"))
        sanitizeConfigRemoveAudio()

        // 3) Réveiller Metal AVANT tout réglage mémoire MLX : sur un MTLDevice
        //    froid, fixer la limite de cache interrompt le processus.
        Self.warmMetalDevice()
        Self.setCacheLimitBytes(256 * 1024 * 1024)

        // 4) Trace posée juste avant l'étape risquée (projection mémoire de
        //    plusieurs gigaoctets + allocations Metal).
        placeBreadcrumb()

        progress(0.98, L.t("gemma.status.loading"))
        let modelDir = modelDirectory
        // 5) Chargement depuis le disque, hors du fil principal : la projection
        //    mémoire et l'analyse des poids dépassent dix secondes, ce que le
        //    watchdog d'iOS sanctionne par une mise à mort s'il s'agit du
        //    MainActor.
        let tokenizerLoader = #huggingFaceTokenizerLoader()
        let loaded = try await Task.detached(priority: .userInitiated) {
            try await loadModelContainer(from: modelDir, using: tokenizerLoader)
        }.value

        container = loaded
        clearBreadcrumb(resetCount: true)
        progress(1.0, L.t("gemma.status.ready"))
        #else
        // Aperçus SwiftUI, simulateur, intégration continue.
        for step in 0...20 {
            try? await Task.sleep(nanoseconds: 50_000_000)
            progress(Double(step) / 20,
                     step < 20 ? L.t("gemma.status.starting") : L.t("gemma.status.ready"))
        }
        #endif
    }

    // =========================================================================
    // MARK: - Réglages MLX
    // =========================================================================

    #if LIMB_MLX_REAL
    /// Force l'initialisation synchrone du MTLDevice avant tout réglage mémoire.
    nonisolated static func warmMetalDevice() {
        let warmup = MLXArray([1.0, 2.0])
        warmup.eval()
        _ = warmup.shape
    }

    /// Borne le cache GPU. On ne fixe **pas** de limite dure de mémoire : sur
    /// les iPhone récents elle se déclenche au-dessus du jeu de travail réel et
    /// interrompt le processus.
    nonisolated static func setCacheLimitBytes(_ bytes: Int) {
        MLX.Memory.cacheLimit = bytes
    }

    private func sanitizeConfigRemoveAudio() {
        patchJSONRemovingKeys(modelDirectory.appendingPathComponent("config.json"),
                              keys: ["audio_config"])
        patchJSONRemovingKeys(modelDirectory.appendingPathComponent("processor_config.json"),
                              keys: ["feature_extractor", "audio_seq_length", "audio_ms_per_token"])
    }

    private func patchJSONRemovingKeys(_ url: URL, keys: [String]) {
        guard let data = try? Data(contentsOf: url),
              var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }
        let present = keys.filter { json[$0] != nil }
        guard !present.isEmpty else { return }
        for key in present { json.removeValue(forKey: key) }
        guard let patched = try? JSONSerialization.data(withJSONObject: json,
                                                        options: [.prettyPrinted, .sortedKeys]) else { return }
        try? patched.write(to: url, options: .atomic)
    }
    #endif

    // =========================================================================
    // MARK: - Génération
    // =========================================================================

    func stream(systemPrompt: String,
                userPrompt: String,
                maxTokens: Int = 512,
                temperature: Float = 0.6) -> AsyncThrowingStream<String, Error> {

        AsyncThrowingStream { continuation in
            generationTask?.cancel()
            generationTask = Task { [weak self] in
                guard let self else { continuation.finish(); return }

                #if LIMB_MLX_REAL
                guard let container = await self.container else {
                    // Erreur typée : le générateur bascule proprement sur le
                    // contenu embarqué. Surtout ne pas produire de texte
                    // bidon, qui ferait échouer le décodage JSON en aval.
                    continuation.finish(throwing: GemmaError.notReady)
                    return
                }

                let safeSystem = String(systemPrompt.prefix(4_000))
                let safeUser   = String(userPrompt.prefix(4_000))
                let safeMax    = max(16, min(maxTokens, 4_096))
                let safeTemp   = max(0.0, min(temperature, 1.5))
                // Gemma n'a pas de rôle « system » distinct : l'instruction se
                // préfixe au tour utilisateur, comme le veut son gabarit.
                let composed = safeSystem.isEmpty ? safeUser : safeSystem + "\n\n" + safeUser

                do {
                    try await container.perform { ctx in
                        let input = try await ctx.processor.prepare(
                            input: UserInput(prompt: composed))
                        let params = GenerateParameters(
                            maxTokens: safeMax,
                            temperature: safeTemp,
                            topP: 0.95,
                            repetitionPenalty: 1.05,
                            repetitionContextSize: 20)
                        let iterator = try TokenIterator(
                            input: input, model: ctx.model, cache: nil, parameters: params)
                        let generation = MLXLMCommon.generate(
                            input: input, context: ctx, iterator: iterator)
                        for await item in generation {
                            if Task.isCancelled { break }
                            if case .chunk(let text) = item { continuation.yield(text) }
                        }
                        continuation.finish()
                    }
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
                #else
                // Moteur déterministe : rend le texte demandé mot à mot, ce qui
                // suffit à faire vivre l'interface de chat en aperçu.
                let words = userPrompt.split(separator: " ").map(String.init)
                for word in words {
                    try? await Task.sleep(nanoseconds: 25_000_000)
                    continuation.yield(word + " ")
                }
                continuation.finish()
                #endif
            }
        }
    }

    /// Variante en un coup, décodée en type Swift.
    func generateJSON<T: Decodable>(_ type: T.Type,
                                    systemPrompt: String,
                                    userPrompt: String,
                                    maxTokens: Int = 1024) async throws -> T {
        guard isReady, !loadFailed else { throw GemmaError.notReady }

        var raw = ""
        for try await chunk in stream(systemPrompt: systemPrompt,
                                      userPrompt: userPrompt,
                                      maxTokens: maxTokens,
                                      temperature: 0.5) {
            raw += chunk
            if raw.count > 200_000 { break }
        }
        let cleaned = Self.extractJSON(from: raw)
        guard cleaned.hasPrefix("{") || cleaned.hasPrefix("[") else {
            throw GemmaError.malformedJSON(raw)
        }
        guard let data = cleaned.data(using: .utf8), !data.isEmpty else {
            throw GemmaError.malformedJSON(raw)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Extrait le premier objet ou tableau JSON équilibré du texte produit.
    /// Un modèle bavard enrobe volontiers sa réponse de commentaires ; on ne
    /// garde que ce qui se décode.
    static func extractJSON(from text: String) -> String {
        guard let start = text.firstIndex(where: { $0 == "{" || $0 == "[" }) else { return text }
        let open = text[start]
        let close: Character = open == "{" ? "}" : "]"
        var depth = 0
        var inString = false
        var escaped = false
        var end: String.Index?
        for index in text[start...].indices {
            let ch = text[index]
            if escaped { escaped = false; continue }
            if ch == "\\" { escaped = true; continue }
            if ch == "\"" { inString.toggle(); continue }
            guard !inString else { continue }
            if ch == open { depth += 1 }
            else if ch == close {
                depth -= 1
                if depth == 0 { end = index; break }
            }
        }
        guard let end else { return String(text[start...]) }
        return String(text[start...end])
    }

    func cancel() {
        generationTask?.cancel()
        generationTask = nil
    }

    enum GemmaError: LocalizedError {
        case notReady
        case malformedJSON(String)
        case downloadFailed(String)

        var errorDescription: String? {
            switch self {
            case .notReady:              return L.t("gemma.error.not_ready")
            case .malformedJSON(let s):  return L.t("gemma.error.bad_json", String(s.prefix(120)))
            case .downloadFailed(let m): return L.t("gemma.error.download", m)
            }
        }
    }
}
