import Foundation

/// Fait travailler Gemma — sans jamais le laisser se tromper devant l'apprenant.
///
/// Un modèle de quatre milliards de paramètres écrit un français convaincant,
/// mais il invente : il place un accent de trop, propose un homophone comme
/// bonne réponse, accorde un participe qui ne doit pas l'être. En orthographe,
/// une erreur d'énoncé est pire que pas d'énoncé du tout — l'apprenant retient
/// la faute.
///
/// La règle appliquée partout ici est donc la même :
///
/// > **Le contenu vérifié est la source de vérité. Gemma enrichit, puis on
/// > réancre sa sortie sur les valeurs vérifiées ; ce qui ne peut pas être
/// > réancré est jeté.**
///
/// Concrètement : la liste de vocabulaire lui est donnée, il ne peut pas en
/// sortir ; ses exemples ne sont retenus que s'ils contiennent réellement le
/// mot ; et les exercices d'orthographe ne lui sont **jamais** confiés — ils
/// viennent des banques vérifiées, où la bonne réponse est juste par
/// construction.
@MainActor
final class ContentGenerator: ObservableObject {

    static let shared = ContentGenerator()
    private init() {}

    private let gemma = GemmaService.shared
    private var cache: [String: Any] = [:]

    // =========================================================================
    // MARK: - Leçons
    // =========================================================================

    func lesson(topic: LessonTopic, native: NativeLanguage,
                level: ProficiencyLevel) async throws -> LessonContent {
        let key = "lesson:\(topic.slug):\(native.id):\(level.rawValue)"
        if let cached = cache[key] as? LessonContent { return cached }

        let seed = ContentSeeds.lesson(topic: topic)
        guard !seed.cards.isEmpty else { cache[key] = seed; return seed }

        // La liste autoritaire : ces mots et ces sens sont les seuls autorisés.
        var authoritative: [String: VocabCard] = [:]
        for card in seed.cards { authoritative[normalize(card.french)] = card }
        let wordList = seed.cards.enumerated()
            .map { index, card in "\(index + 1). \(card.french) = \(card.localizedTranslation)" }
            .joined(separator: "\n")

        let system = """
        You are an expert teacher of FRENCH writing for the iOS app Limbator.
        The learner's native language is \(native.englishName) (ISO \(native.id)).
        Write the introduction, every translation, exampleTranslation, grammarTip
        and culturalNote in \(native.englishName).
        Write French ONLY in flawless orthography: every accent (é è ê ë à â î ï ô ù û),
        every cedilla (ç), every ligature (œ), every silent letter, every agreement.

        AUTHORITATIVE WORD LIST for the topic "\(topic.frenchTitle)" — these French
        words and their EXACT meanings are the only vocabulary you may teach:
        \(wordList)

        HARD RULES:
        - Produce ONE card per word above, spelled EXACTLY as written, in order.
        - Use ONLY the given meaning for each word. Never re-translate it.
        - Do NOT invent, add or substitute any French word not on the list.
        - exampleSentence: ONE short, grammatically correct French sentence that
          CONTAINS that exact word, spelled exactly as given.
        - spellingNote: in \(native.englishName), one sentence naming the real
          orthographic difficulty of that word (accent, double consonant, silent
          letter, gender). If the word has no difficulty, use an empty string.
        Output STRICT minified JSON, no markdown, no commentary. Schema:
        {"introduction":"native","cards":[{"french":"","phonetic":"IPA","translation":"native","gender":"m|f|","exampleSentence":"French using the word","exampleTranslation":"native","spellingNote":"native or empty","category":"native"}],"grammarTip":"native","culturalNote":"native"}
        """
        let user = """
        Topic: "\(topic.frenchTitle)". Level: \(level.rawValue).
        Spelling focus of this lesson: \(topic.orthoFocus.rawValue).
        Generate one card for EACH word in the authoritative list, in order. Generate now.
        """

        do {
            let raw: GeneratedLesson = try await gemma.generateJSON(
                GeneratedLesson.self, systemPrompt: system, userPrompt: user, maxTokens: 1800)

            // Réancrage. Le mot français et sa traduction sont FORCÉS aux valeurs
            // vérifiées, même si le modèle a associé un bon mot à un mauvais sens.
            // Son exemple n'est gardé que s'il contient réellement le mot ; sa note
            // d'orthographe que si elle n'est pas vide.
            var seen = Set<String>()
            var kept: [VocabCard] = []
            for generated in raw.cards {
                let normalized = normalize(generated.french)
                guard let reference = authoritative[normalized], !seen.contains(normalized) else { continue }
                seen.insert(normalized)

                let exampleIsUsable = !generated.exampleSentence.isEmpty
                    && normalize(generated.exampleSentence).contains(normalize(reference.french))

                kept.append(VocabCard(
                    french: reference.french,                       // vérifié
                    phonetic: generated.phonetic.isEmpty ? reference.phonetic : generated.phonetic,
                    translation: reference.localizedTranslation,    // vérifié
                    gender: reference.gender,                       // vérifié
                    exampleSentence: exampleIsUsable ? generated.exampleSentence : reference.exampleSentence,
                    exampleTranslation: (exampleIsUsable && !generated.exampleTranslation.isEmpty)
                        ? generated.exampleTranslation : reference.localizedExampleTranslation,
                    spellingNote: generated.spellingNote?.nilIfBlank ?? reference.localizedSpellingNote,
                    category: reference.category))
            }

            // Sans une majorité franche de cartes réancrées, la génération n'a
            // rien apporté : on sert la leçon vérifiée.
            guard kept.count >= max(4, seed.cards.count / 2) else {
                cache[key] = seed
                return seed
            }

            let content = LessonContent(
                topicSlug: topic.slug,
                introduction: raw.introduction.nilIfBlank ?? seed.localizedIntroduction,
                cards: kept,
                phrases: seed.phrases,                              // expressions vérifiées
                grammarTip: raw.grammarTip?.nilIfBlank ?? seed.localizedGrammarTip,
                culturalNote: raw.culturalNote?.nilIfBlank ?? seed.localizedCulturalNote,
                orthoSpotlight: seed.orthoSpotlight)                // encadré vérifié
            cache[key] = content
            return content
        } catch {
            cache[key] = seed
            return seed
        }
    }

    // =========================================================================
    // MARK: - Manches de jeu
    // =========================================================================

    /// Les manches ne passent **pas** par Gemma.
    ///
    /// Un quiz dont la bonne réponse est fausse détruit la confiance de
    /// l'apprenant plus vite que n'importe quelle absence de contenu — et sur
    /// des homophones, un modèle de cette taille se trompe régulièrement. Le
    /// vivier vérifié fournit une variété suffisante : `GameSeeds` combine 169
    /// cartes, 24 familles d'homophones et 84 exercices écrits à la main.
    func gameRounds(kind: GameKind, level: ProficiencyLevel,
                    count: Int = 10, seed: UInt64 = 0) -> [GameRound] {
        GameSeeds.rounds(kind: kind, level: level, count: count, seed: seed)
            .filter(\.isPlayable)
    }

    // =========================================================================
    // MARK: - Dictées
    // =========================================================================

    /// Une dictée neuve, écrite par Gemma pour travailler une règle précise.
    ///
    /// La phrase produite n'est acceptée que si elle **contient réellement** ce
    /// qu'elle prétend faire travailler : on vérifie qu'un mot de la règle y
    /// figure, que la longueur est raisonnable, et que le français passe les
    /// contrôles de plausibilité. Sinon, on renvoie une dictée vérifiée.
    func dictation(targeting rule: OrthoRule, native: NativeLanguage,
                   level: ProficiencyLevel) async -> DictationItem {
        // Chaîne de replis totale : aucune branche ne peut rendre nil, et
        // aucune n'indexe un tableau.
        let fallback = DictationBank.dictations(targeting: rule.id).first
            ?? DictationBank.dictations(upTo: level).first
            ?? DictationBank.all.first
            ?? DictationItem(text: "Bonjour.", translation: "Bună ziua.", level: .a1)

        let examples = rule.examples.map(\.correct).joined(separator: " · ")
        let system = """
        You write dictation sentences for FRENCH learners whose native language is
        \(native.englishName).

        The sentence must exercise this exact spelling rule:
        \(rule.title) — \(rule.statement)
        Canonical examples of the rule: \(examples)

        HARD RULES:
        - ONE French sentence, between 6 and 16 words, level \(level.rawValue).
        - It MUST contain at least one word that the rule applies to.
        - Flawless orthography: every accent, cedilla, agreement, silent letter.
        - Ordinary vocabulary. No proper nouns other than common French cities.
        - End with a full stop, a question mark or an exclamation mark.
        - Provide a faithful translation in \(native.englishName).
        Output STRICT minified JSON: {"text":"French sentence","translation":"native"}
        """

        do {
            let generated: GeneratedDictation = try await gemma.generateJSON(
                GeneratedDictation.self, systemPrompt: system,
                userPrompt: "Write the sentence now.", maxTokens: 220)

            let text = generated.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let translation = generated.translation.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isUsableDictation(text, translation: translation, rule: rule) else { return fallback }

            return DictationItem(text: text, translation: translation, level: level,
                                 targetRules: [rule.id], hint: rule.localizedMnemonic,
                                 theme: rule.module.rawValue)
        } catch {
            return fallback
        }
    }

    /// Les contrôles qu'une phrase doit passer pour être dictée à quelqu'un.
    func isUsableDictation(_ text: String, translation: String, rule: OrthoRule) -> Bool {
        let words = text.split(separator: " ")
        guard words.count >= 5, words.count <= 20 else { return false }
        guard !translation.isEmpty else { return false }
        guard text.rangeOfCharacter(from: CharacterSet(charactersIn: ".!?…")) != nil else { return false }
        // Ni balise résiduelle, ni guillemet de code, ni accolade JSON échappée.
        guard !text.contains("{"), !text.contains("}"), !text.contains("\\") else { return false }
        // Le modèle doit avoir répondu en français, pas dans la langue de consigne.
        guard text.contains(" ") , !text.lowercased().hasPrefix("the ") else { return false }

        // La phrase doit réellement mettre la règle à l'épreuve : au moins un mot
        // porteur du phénomène. Sans ce contrôle, on dicterait « Bonjour à tous »
        // en prétendant travailler l'accord du participe passé.
        let lowered = text.lowercased()
        switch rule.module {
        case .accents:
            return FrenchPhonology.hasDiacritics(text)
        case .doubleLetters, .roTraps:
            // Une consonne doublée ou un signe diacritique : sans l'un des deux,
            // la phrase ne met à l'épreuve ni les doubles ni les pièges roumains.
            return hasDoubledConsonant(lowered) || FrenchPhonology.hasDiacritics(text)
        case .homophones:
            guard let set = OrthoSeeds.homophoneSet(id: String(rule.id.dropFirst("homophones.".count)))
            else { return true }
            let tokens = Set(OrthographyEngine.tokenize(lowered).map(\.text))
            return !tokens.isDisjoint(with: Set(set.forms.map { $0.lowercased() }))
        case .verbEndings:
            return lowered.contains("é") || lowered.contains("er ") || lowered.hasSuffix("er.")
                || lowered.contains("ez ") || lowered.contains("ent ") || lowered.contains("ais")
                || lowered.contains("ait")
        case .agreements:
            return lowered.contains(" est ") || lowered.contains(" sont ")
                || lowered.contains(" ai ") || lowered.contains(" a ")
                || lowered.contains(" ont ") || lowered.contains(" avons ")
        case .plurals:
            return lowered.contains("s ") || lowered.contains("x ")
                || lowered.hasSuffix("s.") || lowered.hasSuffix("x.")
        case .silentLetters:
            return !OrthographyEngine.tokenize(lowered)
                .filter { !$0.isPunctuation }
                .allSatisfy { OrthographyEngine.silentTail($0.text).isEmpty }
        }
    }

    private func hasDoubledConsonant(_ text: String) -> Bool {
        let characters = Array(text)
        guard characters.count > 1 else { return false }
        for index in 0..<(characters.count - 1) where characters[index] == characters[index + 1]
            && characters[index].isLetter
            && !FrenchPhonology.vowelLetters.contains(characters[index]) {
            return true
        }
        return false
    }

    // =========================================================================
    // MARK: - Scènes d'histoire
    // =========================================================================

    func storyScenes(story: Story, chapter: StoryChapter, native: NativeLanguage,
                     level: ProficiencyLevel) async -> [StoryScene] {
        let key = "story:\(story.slug):\(chapter.index):\(native.id)"
        if let cached = cache[key] as? [StoryScene] { return cached }
        let verified = StorySeeds.scenes(story: story, chapter: chapter)

        let system = """
        You continue an interactive French-learning story, scene by scene.
        The reader's native language is \(native.englishName). Level: \(level.rawValue).

        - Each scene pairs a French paragraph with a faithful translation in
          \(native.englishName) — same facts, nothing added or removed.
        - Flawless French orthography: accents, cedillas, agreements, silent letters.
        - Highlight 3 key words per scene. Every highlighted "french" word MUST
          appear EXACTLY as written somewhere in that scene's French paragraph.
        - "choice" is null except possibly on the final scene of the chapter.
        - Stay strictly inside THIS story and chapter: same characters, same place.
        Output a JSON array:
        [{"paragraphFrench":"","paragraphNative":"","highlightedVocab":[{"french":"","translation":"","phonetic":""}],"choice":null}]
        4 scenes.
        """
        let user = """
        Story: \(story.frenchTitle). Chapter \(chapter.index): \(chapter.titleFrench).
        Synopsis: \(story.synopsis)
        Each scene follows from the previous one.
        """

        do {
            let generated: [GeneratedScene] = try await gemma.generateJSON(
                [GeneratedScene].self, systemPrompt: system, userPrompt: user, maxTokens: 2400)

            // Une scène n'est gardée que si les deux paragraphes existent et si
            // CHAQUE mot mis en avant figure vraiment dans le texte français —
            // sinon la mise en surbrillance porterait sur un mot absent, et le
            // glossaire enseignerait un mot que la scène ne contient pas.
            let usable = generated
                .map { $0.toScene() }
                .filter { scene in
                    let french = scene.paragraphFrench.trimmingCharacters(in: .whitespacesAndNewlines)
                    let nativeText = scene.paragraphNative.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !french.isEmpty, !nativeText.isEmpty, !scene.highlightedVocab.isEmpty else { return false }
                    let normalizedParagraph = normalize(french)
                    return scene.highlightedVocab.allSatisfy { word in
                        !word.french.isEmpty && !word.translation.isEmpty
                            && normalizedParagraph.contains(normalize(word.french))
                    }
                }

            guard usable.count >= 3 else {
                cache[key] = verified
                return verified
            }
            cache[key] = usable
            return usable
        } catch {
            cache[key] = verified
            return verified
        }
    }

    // =========================================================================
    // MARK: - Tuteur
    // =========================================================================

    func tutorReply(question: String, native: NativeLanguage,
                    level: ProficiencyLevel) -> AsyncThrowingStream<String, Error> {
        let language = native.englishName
        // Un modèle de cette taille suit très fortement les exemples : la
        // consigne de langue doit être ferme, répétée, et accompagnée d'un
        // échantillon dans la langue visée. Sans cela, il répond en français —
        // ce qui est exactement ce que l'apprenant ne comprend pas encore.
        let system = """
        You are the Limbator tutor. You teach FRENCH to a student whose native
        language is \(language).

        ABSOLUTE RULE — YOU ANSWER IN \(language.uppercased()):
        - Write 100 % of every explanation in \(language).
        - Do NOT explain in French and do NOT explain in English.
        - The only French you may write is the word, phrase or sentence you are
          teaching, always wrapped in *asterisks*, immediately followed by its
          meaning in \(language).

        SPELLING IS YOUR SUBJECT (all of this written in \(language)):
        - Every French form you write must carry its exact orthography: accents,
          cedilla, ligature, agreement, silent letters. A missing accent in your
          own answer teaches the mistake.
        - When two spellings sound alike, give the SUBSTITUTION TEST, not a rule
          to memorise: « a » or « à » → try replacing it with « avait ».
        - If you are not certain a spelling or rule is right, say so plainly in
          \(language) instead of guessing. Never invent a French word.

        \(Self.tutorExample(for: native.id))

        Be concise: at most four short sentences, or a short bulleted list.
        Warm, precise, encouraging. The student writes in \(language); you answer
        in \(language).
        """
        return gemma.stream(systemPrompt: system, userPrompt: question,
                            maxTokens: 700, temperature: 0.45)
    }

    /// Un exemple question/réponse dans la langue de l'apprenant. Une seule
    /// ligne, mais c'est elle qui décide de la langue de toute la conversation.
    private static func tutorExample(for code: String) -> String {
        switch code {
        case "ro":
            return "Exemplu — Întrebare: «Cum scriu: a sau à?»  Răspuns: «Încearcă să înlocuiești cu *avait*. Merge? Atunci scrii *a*, verbul. Nu merge? Atunci scrii *à*, prepoziția.»"
        case "fr":
            return "Exemple — Question : « a ou à ? »  Réponse : « Remplace par *avait*. Ça passe ? C'est le verbe, donc *a*. Ça ne passe pas ? C'est la préposition, donc *à*. »"
        default:
            return "Example — Q: “a or à?”  A: “Try replacing it with *avait*. Does it work? Then it is the verb, so *a*. It doesn't? Then it is the preposition, so *à*.”"
        }
    }

    // =========================================================================
    // MARK: - Outils
    // =========================================================================

    /// Comparaison insensible à la casse, aux accents et aux espaces multiples.
    /// Elle sert **uniquement** à reconnaître le mot que le modèle a voulu
    /// écrire : la graphie finalement affichée est toujours celle du contenu
    /// vérifié, accents compris.
    private func normalize(_ value: String) -> String {
        FrenchPhonology.stripAccents(value)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    func clearCache() { cache.removeAll() }
}

// =============================================================================
// MARK: - Décodage
// =============================================================================

private struct GeneratedLesson: Decodable {
    let introduction: String
    let cards: [GeneratedCard]
    let grammarTip: String?
    let culturalNote: String?
}

private struct GeneratedCard: Decodable {
    let french: String
    let phonetic: String
    let translation: String
    let gender: String?
    let exampleSentence: String
    let exampleTranslation: String
    let spellingNote: String?
    let category: String?
}

private struct GeneratedDictation: Decodable {
    let text: String
    let translation: String
}

private struct GeneratedScene: Decodable {
    let paragraphFrench: String
    let paragraphNative: String
    let highlightedVocab: [HighlightedWord]
    let choice: StoryChoice?

    func toScene() -> StoryScene {
        StoryScene(paragraphFrench: paragraphFrench,
                   paragraphNative: paragraphNative,
                   highlightedVocab: highlightedVocab,
                   choice: choice,
                   orthoHighlight: nil)
    }
}

private extension String {
    /// La chaîne, ou nil si elle ne contient que des espaces. Évite d'afficher
    /// une note vide générée par le modèle à la place d'une note vérifiée.
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
