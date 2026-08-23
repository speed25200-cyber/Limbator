import Foundation
import AVFoundation
import CryptoKit
import Combine
import os.log

/// La voix de Limbator.
///
/// Quatre moteurs, essayés dans cet ordre :
///
/// 1. **Azure neural fr-FR** — la prosodie la plus expressive, si une clé est
///    configurée et le réseau disponible. Facultatif.
/// 2. **VITS neural embarqué** — voix française féminine ou masculine, sur
///    l'appareil, sans réseau. Le moteur de référence.
/// 3. **Apple Premium / Enhanced fr-FR** — contrairement à des langues moins
///    dotées, le français est très bien servi par Apple : ce palier n'est pas
///    un pis-aller.
/// 4. **Apple compacte fr-FR** — toujours présente, toujours intelligible.
///
/// Une app de dictée impose deux exigences que la lecture de vocabulaire
/// n'a pas : la voix doit être **stable** (deux écoutes de la même phrase
/// doivent être identiques, sinon l'apprenant croit avoir mal entendu) et
/// **modulable** (vitesse réduite, lecture mot à mot, épellation). Le cache sur
/// disque assure la première, les modes de lecture la seconde.
@MainActor
final class TTSService: NSObject, ObservableObject {
    static let shared = TTSService()

    // =========================================================================
    // MARK: - État
    // =========================================================================

    enum Engine: String {
        case azure          // 1. neural en ligne, expressif
        case neuralOnDevice // 2. VITS embarqué
        case applePremium   // 3. voix Premium/Enhanced fr-FR
        case appleCompact   // 4. voix compacte fr-FR

        var badge: String {
            switch self {
            case .azure:          return "Azure"
            case .neuralOnDevice: return "Neural"
            case .applePremium:   return "Premium"
            case .appleCompact:   return "iOS"
            }
        }
    }

    enum Gender: String, CaseIterable, Identifiable {
        case feminine, masculine
        var id: String { rawValue }
        var label: String { self == .feminine ? "Feminină" : "Masculină" }
        var localizedLabel: String { ContentL10n.s(label) }
    }

    /// Manière de lire un texte. La dictée les utilise toutes.
    enum Delivery {
        /// Débit naturel.
        case natural
        /// Ralenti, pour réécouter un passage difficile.
        case slow
        /// Mot à mot, avec une pause entre chaque mot.
        case wordByWord
        /// Épelé lettre par lettre, accents nommés.
        case spelled
        /// Scandé par syllabes.
        case syllables
    }

    @Published private(set) var currentEngine: Engine = .appleCompact
    @Published private(set) var isSpeaking: Bool = false
    @Published private(set) var isLoaded: Bool = false
    /// Ce que fait réellement le moteur, en clair — visible dans les réglages.
    /// Un utilisateur qui trouve la voix médiocre doit pouvoir savoir pourquoi.
    @Published private(set) var engineDiagnostic: String = ""

    @Published var playbackRate: Float = 1.0
    @Published var gender: Gender = {
        let stored = UserDefaults.standard.string(forKey: "limb.tts.gender") ?? ""
        return Gender(rawValue: stored) ?? .feminine
    }() {
        didSet { UserDefaults.standard.set(gender.rawValue, forKey: "limb.tts.gender") }
    }

    /// Refuser le réseau même si une clé Azure existe (choix de l'utilisateur,
    /// respecté sans discussion).
    @Published var preferOnDevice: Bool = UserDefaults.standard.bool(forKey: "limb.tts.onDeviceOnly") {
        didSet { UserDefaults.standard.set(preferOnDevice, forKey: "limb.tts.onDeviceOnly") }
    }

    var azureAvailable: Bool { AzureTTS.isConfigured && !preferOnDevice }
    var isNeuralActive: Bool { currentEngine == .azure || currentEngine == .neuralOnDevice }

    // =========================================================================
    // MARK: - Interne
    // =========================================================================

    private let log = Logger(subsystem: "com.limbator.app", category: "tts")
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private let cache = AudioCache()
    private var neuralVoices: [NeuralVoiceEngine.Voice: NeuralVoiceEngine] = [:]
    private var speechContinuation: CheckedContinuation<Void, Never>?

    override private init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    // =========================================================================
    // MARK: - Chargement
    // =========================================================================

    func preloadVoice() async {
        // Les deux voix embarquées se chargent en parallèle : l'utilisateur peut
        // basculer de l'une à l'autre sans attendre.
        async let feminine = NeuralVoiceEngine.load(voice: .feminine, logger: log)
        async let masculine = NeuralVoiceEngine.load(voice: .masculine, logger: log)
        let (f, m) = await (feminine, masculine)
        if let f { neuralVoices[.feminine] = f }
        if let m { neuralVoices[.masculine] = m }

        isLoaded = true
        refreshEngineChoice()
    }

    /// Décide quel moteur mène la cascade et l'explique.
    private func refreshEngineChoice() {
        if azureAvailable {
            currentEngine = .azure
            engineDiagnostic = L.t("tts.diag.azure")
            return
        }
        if neuralVoices[neuralVoice(for: gender)] != nil {
            currentEngine = .neuralOnDevice
            engineDiagnostic = L.t("tts.diag.neural")
            return
        }
        if bestAppleVoice(preferPremium: true) != nil {
            currentEngine = .applePremium
            engineDiagnostic = L.t("tts.diag.apple_premium")
            return
        }
        currentEngine = .appleCompact
        engineDiagnostic = L.t("tts.diag.apple_compact")
    }

    /// À appeler après un changement de réglage (genre, hors-ligne, clé Azure).
    func settingsChanged() {
        refreshEngineChoice()
    }

    private func neuralVoice(for gender: Gender) -> NeuralVoiceEngine.Voice {
        gender == .feminine ? .feminine : .masculine
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        // `.spokenAudio` demande au système le traitement adapté à la parole ;
        // `.duckOthers` baisse la musique de l'utilisateur au lieu de la couper.
        try? session.setCategory(.playback, mode: .spokenAudio,
                                 options: [.duckOthers, .allowBluetooth])
        try? session.setActive(true, options: [])
    }

    // =========================================================================
    // MARK: - Lecture
    // =========================================================================

    /// Prononce un texte français.
    func speak(_ text: String, delivery: Delivery = .natural) async {
        cancel()
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        isSpeaking = true
        defer { isSpeaking = false }

        switch delivery {
        case .natural:
            await utter(cleaned, rate: playbackRate)
        case .slow:
            await utter(cleaned, rate: max(0.4, playbackRate * 0.6))
        case .syllables:
            await utter(FrenchSpeller.syllabified(cleaned), rate: max(0.5, playbackRate * 0.75))
        case .spelled:
            let spelled = cleaned.contains(" ")
                ? FrenchSpeller.spellSentence(cleaned)
                : FrenchSpeller.spell(cleaned)
            await utter(spelled, rate: max(0.5, playbackRate * 0.85))
        case .wordByWord:
            // Une phrase par morceaux : chaque mot est synthétisé seul, ce qui
            // supprime les liaisons et laisse entendre les finales muettes —
            // exactement ce qu'un correcteur de dictée veut faire réentendre.
            for word in cleaned.split(separator: " ").map(String.init) {
                if Task.isCancelled { break }
                await utter(word, rate: max(0.5, playbackRate * 0.8))
                try? await Task.sleep(nanoseconds: 220_000_000)
            }
        }
    }

    /// Raccourci historique, conservé pour la lisibilité des vues.
    func speakSlow(_ text: String) async { await speak(text, delivery: .slow) }
    func spell(_ text: String) async { await speak(text, delivery: .spelled) }

    // =========================================================================
    // MARK: - Cascade
    // =========================================================================

    private func utter(_ text: String, rate: Float) async {
        let key = cacheKey(text: text, rate: rate)

        // 1. Le cache. Deux écoutes de la même phrase doivent être rigoureusement
        //    identiques : en dictée, une variation de synthèse se confond avec
        //    une différence de contenu.
        if let cached = cache.fetch(key: key) {
            await play(cached)
            return
        }

        // 2. Azure, si configuré et autorisé.
        if azureAvailable {
            let voice = gender == .feminine ? AzureTTS.feminineVoice : AzureTTS.masculineVoice
            if let url = await AzureTTS.synthesize(text: text, voice: voice, rate: rate, style: "calm") {
                cache.store(key: key, url: url)
                await play(url)
                return
            }
            // Repli sur les voix standard : certains abonnements n'ouvrent pas
            // les voix multilingues.
            let fallbackVoice = gender == .feminine ? AzureTTS.feminineFallback : AzureTTS.masculineFallback
            if let url = await AzureTTS.synthesize(text: text, voice: fallbackVoice, rate: rate) {
                cache.store(key: key, url: url)
                await play(url)
                return
            }
        }

        // 3. VITS embarqué.
        if let engine = neuralVoices[neuralVoice(for: gender)],
           let url = await engine.synthesize(text: text, speed: rate) {
            cache.store(key: key, url: url)
            await play(url)
            return
        }

        // 4. Apple. AVSpeechSynthesizer n'expose pas de PCM exploitable sur iOS :
        //    on lit directement, sans mise en cache.
        await speakWithApple(text, rate: rate)
    }

    private func speakWithApple(_ text: String, rate: Float) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestAppleVoice(preferPremium: true) ?? AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * max(0.35, min(rate, 1.6))
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.05

        // On attend la fin par le délégué plutôt qu'en interrogeant
        // `isSpeaking` en boucle : la boucle rate les énoncés très courts —
        // typiquement une seule lettre en mode épellation.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            speechContinuation = continuation
            synthesizer.speak(utterance)
        }
    }

    /// La meilleure voix française installée. Les voix Premium et Enhanced ne
    /// sont présentes que si l'utilisateur les a téléchargées dans les réglages
    /// d'iOS ; on prend la meilleure disponible, et on tient compte du genre choisi.
    private func bestAppleVoice(preferPremium: Bool) -> AVSpeechSynthesisVoice? {
        let french = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("fr") }
        guard !french.isEmpty else { return nil }

        let wanted: AVSpeechSynthesisVoiceGender = gender == .feminine ? .female : .male
        func pick(_ quality: AVSpeechSynthesisVoiceQuality) -> AVSpeechSynthesisVoice? {
            french.first { $0.quality == quality && $0.gender == wanted }
                ?? french.first { $0.quality == quality }
        }
        if preferPremium, let premium = pick(.premium) { return premium }
        if let enhanced = pick(.enhanced) { return enhanced }
        return french.first { $0.gender == wanted } ?? french.first
    }

    private func play(_ url: URL) async {
        // Vérifier avant d'ouvrir : AVAudioPlayer lève une erreur opaque sur un
        // fichier absent ou tronqué, et l'utilisateur n'entendrait rien sans
        // comprendre pourquoi.
        guard FileManager.default.fileExists(atPath: url.path) else {
            log.error("Lecture impossible : fichier absent")
            return
        }
        let size = ((try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? NSNumber)?.intValue ?? 0
        guard size > 44 else {          // taille minimale d'un WAV valide
            log.error("Lecture impossible : fichier trop court (\(size) octets)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            audioPlayer = player
            // La vitesse est déjà appliquée à la synthèse et la clé de cache en
            // tient compte : la réappliquer ici déformerait la hauteur du son.
            player.enableRate = false
            player.prepareToPlay()
            player.play()
            while player.isPlaying {
                try? await Task.sleep(nanoseconds: 60_000_000)
                if Task.isCancelled { player.stop(); break }
            }
        } catch {
            log.error("AVAudioPlayer a échoué : \(error.localizedDescription)")
        }
    }

    func cancel() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        audioPlayer = nil
        finishSpeechContinuation()
        isSpeaking = false
    }

    private func finishSpeechContinuation() {
        speechContinuation?.resume()
        speechContinuation = nil
    }

    // =========================================================================
    // MARK: - Prononciation de l'apprenant
    // =========================================================================

    /// Note la prononciation d'un enregistrement, de 0 à 1.
    ///
    /// L'évaluation acoustique réelle demande un encodeur audio embarqué ; en
    /// attendant, cette note est **explicitement approximative** et l'interface
    /// le dit à l'utilisateur plutôt que de faire passer un nombre inventé pour
    /// une mesure. Elle se fonde sur ce qui est réellement mesurable ici : la
    /// durée de l'enregistrement rapportée à la longueur attendue du texte.
    func approximateSpeechScore(french: String, recordingURL: URL) async -> Double {
        let expectedSyllables = max(1, FrenchPhonology.syllabify(french).count)
        // Une syllabe française dure environ 0,2 s à débit normal.
        let expectedDuration = Double(expectedSyllables) * 0.2

        guard let player = try? AVAudioPlayer(contentsOf: recordingURL) else { return 0.5 }
        let actual = player.duration
        guard actual > 0.15 else { return 0.2 }     // rien n'a été dit

        let ratio = actual / expectedDuration
        // Une lecture deux fois trop lente ou deux fois trop rapide s'écarte
        // clairement du modèle ; entre les deux, on récompense la proximité.
        let closeness = 1.0 - min(1.0, abs(log(max(ratio, 0.01))) / log(2.5))
        return max(0.25, min(0.95, 0.45 + 0.5 * closeness))
    }

    // =========================================================================
    // MARK: - Cache
    // =========================================================================

    private func cacheKey(text: String, rate: Float) -> String {
        let engineTag = azureAvailable ? "azure" : currentEngine.rawValue
        let raw = "\(text)|\(gender.rawValue)|\(Int(rate * 100))|\(engineTag)"
        return SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func clearAudioCache() { cache.clear() }
    var audioCacheBytes: Int64 { cache.totalBytes() }
}

// =============================================================================
// MARK: - Délégué de la synthèse Apple
// =============================================================================

extension TTSService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finishSpeechContinuation() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finishSpeechContinuation() }
    }
}

// =============================================================================
// MARK: - Cache audio sur disque
// =============================================================================

/// Cache LRU des sorties vocales, plafonné à 60 Mo.
///
/// Il sert deux buts : la latence (une phrase déjà entendue repart
/// instantanément) et surtout la **constance**. En dictée, l'apprenant réécoute
/// la même phrase cinq ou six fois ; elle doit sonner exactement pareil à
/// chaque fois.
final class AudioCache {
    private let directory: URL
    private let limit: Int64 = 60 * 1024 * 1024
    private let log = Logger(subsystem: "com.limbator.app", category: "tts.cache")

    init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directory = base.appendingPathComponent("Limbator/tts", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func fetch(key: String) -> URL? {
        let url = directory.appendingPathComponent("\(key).wav")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        // Marquer l'accès pour la politique LRU.
        try? FileManager.default.setAttributes([.modificationDate: Date()],
                                               ofItemAtPath: url.path)
        return url
    }

    func store(key: String, url: URL) {
        let target = directory.appendingPathComponent("\(key).wav")
        do {
            if FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.removeItem(at: target)
            }
            try FileManager.default.copyItem(at: url, to: target)
            evictIfNeeded()
        } catch {
            log.error("Mise en cache impossible : \(error.localizedDescription)")
        }
    }

    func totalBytes() -> Int64 {
        entries().reduce(0) { $0 + $1.size }
    }

    func clear() {
        for entry in entries() { try? FileManager.default.removeItem(at: entry.url) }
    }

    private struct Entry { let url: URL; let size: Int64; let modified: Date }

    private func entries() -> [Entry] {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]) else { return [] }
        return items.map { url in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            return Entry(url: url,
                         size: Int64(values?.fileSize ?? 0),
                         modified: values?.contentModificationDate ?? .distantPast)
        }
    }

    private func evictIfNeeded() {
        let all = entries()
        let total = all.reduce(Int64(0)) { $0 + $1.size }
        guard total > limit else { return }
        var freed: Int64 = 0
        let needed = total - limit
        for entry in all.sorted(by: { $0.modified < $1.modified }) {
            try? FileManager.default.removeItem(at: entry.url)
            freed += entry.size
            if freed >= needed { break }
        }
    }
}
