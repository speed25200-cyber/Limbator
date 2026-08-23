import Foundation

/// Voix neurales françaises d'Azure — le palier le plus haut de la cascade,
/// utilisé seulement s'il est configuré et si le réseau répond.
///
/// Limbator est parfaitement utilisable sans : les voix neurales embarquées et
/// les voix Premium d'Apple couvrent le français à un très bon niveau. Azure
/// apporte la prosodie expressive (les voix multilingues gèrent les enchaînements
/// et l'intonation de question mieux que n'importe quel modèle embarqué), ce qui
/// se remarque sur les phrases longues d'une dictée de niveau C1.
///
/// **Aucune clé n'est inscrite dans le code.** Une clé versionnée dans un dépôt
/// est une clé compromise. Elle arrive soit des réglages de l'app, soit d'une
/// variable secrète d'intégration continue injectée dans Info.plist au moment
/// de la construction.
enum AzureTTS {

    // Voix neurales françaises retenues. Les variantes « Multilingual » sont
    // les plus expressives du catalogue fr-FR.
    static let feminineVoice  = "fr-FR-VivienneMultilingualNeural"
    static let masculineVoice = "fr-FR-RemyMultilingualNeural"
    /// Repli si le compte ne donne pas accès aux voix multilingues.
    static let feminineFallback  = "fr-FR-DeniseNeural"
    static let masculineFallback = "fr-FR-HenriNeural"

    private enum Keys {
        static let key    = "limb.azure_tts_key"
        static let region = "limb.azure_tts_region"
    }

    /// Réglages de l'app, puis Info.plist (injecté par la CI). Rien d'autre.
    static var key: String {
        let stored = UserDefaults.standard.string(forKey: Keys.key)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !stored.isEmpty { return stored }
        return (Bundle.main.object(forInfoDictionaryKey: "AZURE_TTS_KEY") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var region: String {
        let stored = UserDefaults.standard.string(forKey: Keys.region)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !stored.isEmpty { return stored }
        let plist = (Bundle.main.object(forInfoDictionaryKey: "AZURE_TTS_REGION") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return plist.isEmpty ? "westeurope" : plist
    }

    static var isConfigured: Bool { !key.isEmpty }

    static func setCredentials(key: String, region: String) {
        let defaults = UserDefaults.standard
        defaults.set(key.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Keys.key)
        let cleanedRegion = region.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(cleanedRegion.isEmpty ? "westeurope" : cleanedRegion, forKey: Keys.region)
    }

    static func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: Keys.key)
        UserDefaults.standard.removeObject(forKey: Keys.region)
    }

    /// Synthétise et rend l'URL d'un WAV temporaire.
    /// Rend `nil` sur toute erreur : l'appelant redescend d'un cran dans la cascade.
    ///
    /// `style` accepte un style expressif Azure (« cheerful », « calm »…) ;
    /// Limbator s'en sert pour lire une dictée d'un ton posé et une réplique de
    /// dialogue d'un ton naturel.
    static func synthesize(text: String,
                           voice: String,
                           rate: Float = 1.0,
                           style: String? = nil) async -> URL? {
        let credential = key, area = region
        guard !credential.isEmpty,
              let endpoint = URL(string: "https://\(area).tts.speech.microsoft.com/cognitiveservices/v1")
        else { return nil }

        let body = ssml(text: text, voice: voice, rate: rate, style: style)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(credential, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/ssml+xml", forHTTPHeaderField: "Content-Type")
        request.setValue("riff-24khz-16bit-mono-pcm", forHTTPHeaderField: "X-Microsoft-OutputFormat")
        request.setValue("Limbator", forHTTPHeaderField: "User-Agent")
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200,
                  data.count > 44 else { return nil }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("limb_azure_\(UUID().uuidString).wav")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Construit le SSML. Le texte est échappé : une apostrophe typographique ou
    /// une esperluette dans une phrase de dictée invaliderait le document XML et
    /// ferait échouer la requête sans explication.
    static func ssml(text: String, voice: String, rate: Float, style: String?) -> String {
        let escaped = String(text.prefix(2000))
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")

        let percent = Int((rate - 1.0) * 100)
        var inner = escaped
        if percent != 0 {
            let sign = percent >= 0 ? "+" : ""
            inner = "<prosody rate='\(sign)\(percent)%'>\(inner)</prosody>"
        }
        if let style, !style.isEmpty {
            inner = "<mstts:express-as style='\(style)'>\(inner)</mstts:express-as>"
        }
        return """
        <speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' \
        xmlns:mstts='https://www.w3.org/2001/mstts' xml:lang='fr-FR'>\
        <voice name='\(voice)'>\(inner)</voice></speak>
        """
    }
}
