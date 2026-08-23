import Foundation
import os.log

#if canImport(sherpa_onnx)
import sherpa_onnx
#endif

/// Synthèse vocale neurale VITS sur l'appareil, via sherpa-onnx.
///
/// Vit **hors** du fil principal : l'inférence dure quelques centaines de
/// millisecondes et bloquerait l'interface. Produit un fichier `.wav` sur
/// disque, au taux d'échantillonnage du modèle, que `AVAudioPlayer` sait lire.
///
/// Deux voix françaises sont embarquées, une féminine et une masculine, toutes
/// deux entraînées sur du français : la prononciation des liaisons, des nasales
/// et des e muets est juste — condition non négociable pour une app de dictée,
/// où l'apprenant écrit exactement ce qu'il entend.
///
/// Les modèles Piper passent par le phonémiseur espeak-ng : le dossier
/// `espeak-ng-data` doit accompagner les poids dans le paquet de l'app.
/// Si un fichier manque, `load` renvoie `nil` et la couche supérieure retombe
/// sur les voix Premium d'Apple — qui, pour le français, sont excellentes.
/// Conçu pour ne jamais lever d'exception : chaque chemin d'erreur rend `nil`.
final class NeuralVoiceEngine: @unchecked Sendable {

    /// Les deux voix embarquées.
    enum Voice: String, CaseIterable, Sendable {
        case feminine
        case masculine

        /// Nom du fichier de poids à la racine du paquet.
        var modelResource: String {
            switch self {
            case .feminine:  return "fr_female"
            case .masculine: return "fr_male"
            }
        }

        var tokensResource: String {
            switch self {
            case .feminine:  return "fr_female_tokens"
            case .masculine: return "fr_male_tokens"
            }
        }
    }

    #if canImport(sherpa_onnx)
    private let wrapper: SherpaOnnxOfflineTtsWrapper
    #endif

    let voice: Voice
    private let log: Logger

    // =========================================================================
    // MARK: - Chargement
    // =========================================================================

    /// Tente de charger une voix. Rend `nil` si les fichiers manquent, sont
    /// tronqués, ou si sherpa-onnx n'est pas lié à la compilation.
    static func load(voice: Voice, logger: Logger) async -> NeuralVoiceEngine? {
        await Task.detached(priority: .userInitiated) { () -> NeuralVoiceEngine? in
            #if canImport(sherpa_onnx)
            guard
                let modelURL = Bundle.main.url(forResource: voice.modelResource, withExtension: "onnx"),
                let tokensURL = Bundle.main.url(forResource: voice.tokensResource, withExtension: "txt")
            else {
                logger.notice("Voix neurale \(voice.rawValue, privacy: .public) absente du paquet")
                return nil
            }

            // Un fichier tronqué (téléchargement coupé, réponse 404 de quelques
            // octets) ne fait pas échouer le chargement : il produit du bruit.
            // On vérifie donc des tailles plausibles avant de construire le moteur.
            let fm = FileManager.default
            func byteCount(_ url: URL) -> Int {
                ((try? fm.attributesOfItem(atPath: url.path))?[.size] as? Int) ?? 0
            }
            guard byteCount(modelURL) > 1_000_000, byteCount(tokensURL) > 100 else {
                logger.error("Voix neurale \(voice.rawValue, privacy: .public) incomplète — repli sur Apple")
                return nil
            }

            // Les modèles Piper sont phonémisés par espeak-ng : sans ce dossier
            // le moteur se charge mais ne prononce rien d'intelligible.
            let espeakDir = Bundle.main.resourceURL?
                .appendingPathComponent("espeak-ng-data", isDirectory: true)
            let espeakPath = (espeakDir.map { fm.fileExists(atPath: $0.path) ? $0.path : "" }) ?? ""
            if espeakPath.isEmpty {
                logger.error("espeak-ng-data absent — la voix neurale française serait inintelligible")
                return nil
            }

            let vits = sherpaOnnxOfflineTtsVitsModelConfig(
                model:       modelURL.path,
                lexicon:     "",
                tokens:      tokensURL.path,
                dataDir:     espeakPath,
                noiseScale:  0.667,
                noiseScaleW: 0.8,
                // Légèrement ralenti : en dictée, l'intelligibilité prime sur
                // le naturel. La vitesse reste réglable à la synthèse.
                lengthScale: 1.05)
            let modelConfig = sherpaOnnxOfflineTtsModelConfig(vits: vits)
            var ttsConfig = sherpaOnnxOfflineTtsConfig(model: modelConfig)
            let wrapper = SherpaOnnxOfflineTtsWrapper(config: &ttsConfig)
            return NeuralVoiceEngine(wrapper: wrapper, voice: voice, log: logger)
            #else
            logger.notice("sherpa-onnx non lié à la compilation")
            return nil
            #endif
        }.value
    }

    #if canImport(sherpa_onnx)
    private init(wrapper: SherpaOnnxOfflineTtsWrapper, voice: Voice, log: Logger) {
        self.wrapper = wrapper
        self.voice = voice
        self.log = log
    }
    #else
    private init(voice: Voice, log: Logger) {
        self.voice = voice
        self.log = log
    }
    #endif

    // =========================================================================
    // MARK: - Synthèse
    // =========================================================================

    /// Synthétise et rend l'URL d'un fichier WAV temporaire.
    /// Rend `nil` — jamais d'exception — si l'inférence échoue ou produit du
    /// vide ; la couche supérieure bascule alors sur Apple.
    func synthesize(text: String, speed: Float) async -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let clampedSpeed = max(0.4, min(2.0, speed))

        return await Task.detached(priority: .userInitiated) { [weak self] () -> URL? in
            guard let self else { return nil }
            #if canImport(sherpa_onnx)
            // Un texte très long ou porteur de caractères inattendus peut mettre
            // le moteur en difficulté : on borne franchement.
            let bounded = String(trimmed.prefix(1000))
            let audio = self.wrapper.generate(text: bounded, sid: 0, speed: clampedSpeed)
            let samples = audio.samples
            let sampleRate = Int(audio.sampleRate)
            guard !samples.isEmpty, sampleRate >= 8000, sampleRate <= 48000 else {
                self.log.notice("Synthèse neurale vide ou invalide — repli")
                return nil
            }
            return WAVWriter.write(samples: samples, sampleRate: sampleRate, logger: self.log)
            #else
            return nil
            #endif
        }.value
    }
}

// =============================================================================
// MARK: - Écriture WAV
// =============================================================================

enum WAVWriter {

    /// Encode des échantillons flottants [-1, 1] en WAV PCM 16 bits mono.
    /// Rend `nil` plutôt que de lever : un fichier temporaire manquant ne vaut
    /// pas de faire tomber l'application.
    static func write(samples: [Float], sampleRate: Int, logger: Logger? = nil) -> URL? {
        guard !samples.isEmpty else {
            logger?.notice("WAVWriter : refus d'écrire un tampon vide")
            return nil
        }
        guard sampleRate > 0 else {
            logger?.error("WAVWriter : taux d'échantillonnage invalide (\(sampleRate))")
            return nil
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("limb_tts_\(UUID().uuidString).wav")

        let pcm16: [Int16] = samples.map { sample in
            let clamped = max(-1, min(1, sample))
            return Int16(clamped * Float(Int16.max))
        }
        let dataSize = pcm16.count * MemoryLayout<Int16>.size

        var data = Data()
        data.reserveCapacity(44 + dataSize)
        data.append(Data("RIFF".utf8))
        var chunkSize = UInt32(36 + dataSize).littleEndian
        data.append(Data(bytes: &chunkSize, count: 4))
        data.append(Data("WAVE".utf8))
        data.append(Data("fmt ".utf8))
        var headerSize = UInt32(16).littleEndian;             data.append(Data(bytes: &headerSize, count: 4))
        var format     = UInt16(1).littleEndian;              data.append(Data(bytes: &format, count: 2))
        var channels   = UInt16(1).littleEndian;              data.append(Data(bytes: &channels, count: 2))
        var rate       = UInt32(sampleRate).littleEndian;     data.append(Data(bytes: &rate, count: 4))
        var byteRate   = UInt32(sampleRate * 2).littleEndian; data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = UInt16(2).littleEndian;              data.append(Data(bytes: &blockAlign, count: 2))
        var bits       = UInt16(16).littleEndian;             data.append(Data(bytes: &bits, count: 2))
        data.append(Data("data".utf8))
        var payloadSize = UInt32(dataSize).littleEndian
        data.append(Data(bytes: &payloadSize, count: 4))

        pcm16.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            data.append(Data(bytes: UnsafeRawPointer(base), count: dataSize))
        }

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            logger?.error("WAVWriter : écriture impossible (\(error.localizedDescription))")
            return nil
        }
    }
}
