import Foundation

/// Fabrique les manches de jeu.
///
/// Rien n'est ressaisi ici : le vivier vient des cartes de vocabulaire des
/// quatorze leçons, des familles d'homophones et de la banque de dictées.
/// La bonne réponse est donc **juste par construction** — un quiz ne peut pas
/// contredire une leçon, puisqu'il en est tiré. C'est aussi ce qui permet de
/// générer des manches à l'infini sans écrire une ligne de contenu de plus.
enum GameSeeds {

    /// Toutes les cartes du parcours, dédoublonnées, calculées une seule fois.
    ///
    /// Un mot peut légitimement figurer dans deux leçons — « gare » sert au
    /// thème de la ville comme à celui du voyage. Le garder deux fois ferait
    /// poser la même question deux fois dans une série de dix.
    static let vocabPool: [VocabCard] = {
        var seen = Set<String>()
        var pool: [VocabCard] = []
        for topic in LessonTopic.curriculum {
            for card in ContentSeeds.lesson(topic: topic).cards
            where seen.insert(card.french.lowercased()).inserted {
                pool.append(card)
            }
        }
        return pool
    }()

    /// Les cartes portant au moins un signe diacritique — le vivier de la
    /// chasse aux accents.
    static let accentedPool: [VocabCard] = {
        vocabPool.filter { FrenchPhonology.hasDiacritics($0.french) }
    }()

    // =========================================================================
    // MARK: - Point d'entrée
    // =========================================================================

    static func rounds(kind: GameKind, level: ProficiencyLevel,
                       count: Int, seed: UInt64 = 0) -> [GameRound] {
        switch kind {
        case .match, .flashRecall, .wheelOfFortune:
            return translationRounds(count: count, seed: seed, kind: kind)
        case .listening:
            return listeningRounds(count: count, seed: seed)
        case .wordPuzzle:
            return sentenceRounds(count: count, seed: seed)
        case .speaking:
            return speakingRounds(count: count, seed: seed)
        case .accentHunt:
            return accentRounds(count: count, seed: seed)
        case .homophoneDuel:
            return homophoneRounds(level: level, count: count, seed: seed)
        case .dictation:
            // La dictée n'est pas un questionnaire : elle a son propre écran.
            return []
        case .storyChoice:
            return storyRounds(count: count, seed: seed)
        }
    }

    // =========================================================================
    // MARK: - Traduction (paires, flash, roue)
    // =========================================================================

    private static func translationRounds(count: Int, seed: UInt64, kind: GameKind) -> [GameRound] {
        // On tire large : certaines cartes sont écartées faute de leurres
        // exploitables, et une série de dix doit en compter dix.
        let picks = sample(vocabPool, count: count * 3, seed: seed) { $0.french }
        return picks.compactMap { card in
            let wrong = distractors(for: card, in: vocabPool, seed: seed) { $0.localizedTranslation }
            guard wrong.count >= 2 else { return nil }
            let options = shuffled([card.localizedTranslation] + wrong.prefix(3), seed: seed &+ 1)
            guard let index = options.firstIndex(of: card.localizedTranslation) else { return nil }
            return GameRound(kind: kind.rawValue,
                             prompt: ContentL10n.matchPrompt(card.french),
                             frenchTarget: card.french,
                             options: options,
                             correctIndex: index,
                             explanation: card.localizedSpellingNote)
        }
        .prefix(count)
        .map { $0 }
    }

    // =========================================================================
    // MARK: - Écoute
    // =========================================================================

    private static func listeningRounds(count: Int, seed: UInt64) -> [GameRound] {
        // Les leurres sont choisis parmi les mots qui NE se prononcent PAS
        // comme la cible : proposer deux homophones rendrait la manche
        // impossible à gagner à l'oreille, ce qui n'est pas un exercice, c'est
        // un piège.
        let picks = sample(vocabPool, count: count * 3, seed: seed) { $0.french }
        return picks.compactMap { card in
            let wrong = vocabPool
                .filter { $0.french != card.french && !FrenchPhonology.areHomophones($0.french, card.french) }
                .sorted { rank($0.french, seed) < rank($1.french, seed) }
                .prefix(3)
                .map(\.french)
            guard wrong.count >= 2 else { return nil }
            let options = shuffled([card.french] + wrong, seed: seed &+ 2)
            guard let index = options.firstIndex(of: card.french) else { return nil }
            return GameRound(kind: GameKind.listening.rawValue,
                             prompt: ContentL10n.listeningPrompt(),
                             frenchTarget: card.french,
                             options: options,
                             correctIndex: index,
                             explanation: card.localizedTranslation)
        }
        .prefix(count)
        .map { $0 }
    }

    // =========================================================================
    // MARK: - Phrases
    // =========================================================================

    /// Le puzzle de phrase travaille sur les exemples des leçons : des phrases
    /// courtes, correctes, et déjà traduites.
    private static func sentenceRounds(count: Int, seed: UInt64) -> [GameRound] {
        let usable = vocabPool.filter { card in
            let words = card.exampleSentence.split(separator: " ")
            return words.count >= 3 && words.count <= 8
        }
        let picks = sample(usable, count: count, seed: seed) { $0.french }
        return picks.map { card in
            GameRound(kind: GameKind.wordPuzzle.rawValue,
                      prompt: card.localizedExampleTranslation,
                      frenchTarget: card.exampleSentence,
                      options: card.exampleSentence.split(separator: " ").map(String.init),
                      correctIndex: 0,
                      explanation: nil)
        }
    }

    private static func speakingRounds(count: Int, seed: UInt64) -> [GameRound] {
        sample(vocabPool, count: count, seed: seed, key: { $0.french }).map { card in
            GameRound(kind: GameKind.speaking.rawValue,
                      prompt: card.localizedTranslation,
                      frenchTarget: card.french,
                      options: [card.french],
                      correctIndex: 0,
                      explanation: card.phonetic)
        }
    }

    // =========================================================================
    // MARK: - Chasse aux accents
    // =========================================================================

    private static func accentRounds(count: Int, seed: UInt64) -> [GameRound] {
        let picks = sample(accentedPool, count: count * 3, seed: seed) { $0.french }
        return picks.compactMap { card in
            let variants = accentVariants(of: card.french)
            guard variants.count >= 2 else { return nil }
            let options = shuffled([card.french] + variants.prefix(3), seed: seed &+ 3)
            guard let index = options.firstIndex(of: card.french) else { return nil }
            return GameRound(kind: GameKind.accentHunt.rawValue,
                             prompt: ContentL10n.accentPrompt(),
                             frenchTarget: card.french,
                             options: options,
                             correctIndex: index,
                             explanation: card.localizedSpellingNote ?? card.localizedTranslation)
        }
        .prefix(count)
        .map { $0 }
    }

    /// Fabrique des graphies fautives plausibles : le mot sans ses accents, et
    /// le mot dont un accent a été remplacé par un autre. Ce sont exactement
    /// les deux fautes qu'on fait réellement.
    static func accentVariants(of word: String) -> [String] {
        var variants: [String] = []

        let stripped = FrenchPhonology.stripAccents(word)
        if stripped != word { variants.append(stripped) }

        // Échange aigu / grave sur le premier e accentué.
        let swaps: [Character: Character] = ["é": "è", "è": "é", "ê": "é", "à": "â", "ô": "o", "û": "ù"]
        if let index = word.firstIndex(where: { swaps[$0] != nil }),
           let replacement = swaps[word[index]] {
            var swapped = word
            swapped.replaceSubrange(index...index, with: String(replacement))
            if swapped != word && !variants.contains(swapped) { variants.append(swapped) }
        }

        // Accent posé là où il n'a rien à faire : la faute inverse.
        if let index = word.firstIndex(of: "e"), variants.count < 3 {
            var added = word
            added.replaceSubrange(index...index, with: "é")
            if added != word && !variants.contains(added) { variants.append(added) }
        }

        // Recours : l'accent déplacé sur une autre voyelle. Disponible dès que
        // le mot compte deux voyelles, et c'est une confusion réelle —
        // « hôpital » écrit « hopitâl ». Sans lui, un mot dont le seul accent
        // est un circonflexe sur o n'offrait qu'un leurre, le mot nu, et
        // sortait du jeu.
        if variants.count < 2 {
            let marks = FrenchPhonology.diacriticProfile(word)
            var bare = Array(FrenchPhonology.stripAccents(word))
            if let mark = marks.first, bare.count > 1 {
                let target = bare.indices.first { index in
                    index != mark.index && FrenchPhonology.vowelLetters.contains(bare[index])
                }
                if let target {
                    bare[target] = mark.mark
                    let candidate = String(bare)
                    if candidate != word && !variants.contains(candidate) {
                        variants.append(candidate)
                    }
                }
            }
        }
        return variants
    }

    // =========================================================================
    // MARK: - Duel d'homophones
    // =========================================================================

    private static func homophoneRounds(level: ProficiencyLevel, count: Int,
                                        seed: UInt64) -> [GameRound] {
        let drills = OrthoDrills.homophoneDrills.filter { drill in
            guard let set = OrthoSeeds.homophoneSet(id: String(drill.ruleId.dropFirst("homophones.".count)))
            else { return true }
            return set.level <= level
        }
        let picks = sample(drills, count: count * 2, seed: seed) { $0.id.uuidString }
        return picks.compactMap { drill in
            let options = drill.shuffledOptions
            guard options.count >= 2, let index = options.firstIndex(of: drill.answer) else { return nil }
            return GameRound(kind: GameKind.homophoneDuel.rawValue,
                             prompt: drill.sentence,
                             frenchTarget: drill.solvedSentence,
                             options: options,
                             correctIndex: index,
                             explanation: drill.localizedExplanation)
        }
        .prefix(count)
        .map { $0 }
    }

    // =========================================================================
    // MARK: - Choix narratif
    // =========================================================================

    private static func storyRounds(count: Int, seed: UInt64) -> [GameRound] {
        // Le jeu narratif s'appuie sur les scènes des histoires : chaque scène
        // porteuse d'un embranchement devient une manche.
        var rounds: [GameRound] = []
        for story in Story.builtIn {
            for chapter in story.chapters {
                for scene in StorySeeds.scenes(story: story, chapter: chapter) {
                    guard let choice = scene.choice, choice.options.count >= 2 else { continue }
                    rounds.append(GameRound(
                        kind: GameKind.storyChoice.rawValue,
                        prompt: choice.localizedPrompt,
                        frenchTarget: scene.paragraphFrench,
                        options: choice.options,
                        correctIndex: 0,
                        explanation: scene.localizedParagraphNative))
                }
            }
        }
        return sample(rounds, count: count, seed: seed) { $0.prompt + $0.frenchTarget }
    }

    // =========================================================================
    // MARK: - Tirage déterministe
    // =========================================================================

    /// Un tirage pseudo-aléatoire mais **reproductible** : la même graine donne
    /// la même série. SwiftUI redessine une vue plusieurs fois par seconde ; un
    /// `shuffled()` classique ferait sauter les boutons sous les doigts de
    /// l'utilisateur.
    static func rank(_ value: String, _ seed: UInt64) -> UInt64 {
        OrthoDrill.seedHash(String(seed) + "|" + value)
    }

    static func sample<T>(_ pool: [T], count: Int, seed: UInt64,
                          key: (T) -> String) -> [T] {
        guard !pool.isEmpty, count > 0 else { return [] }
        return pool
            .sorted { rank(key($0), seed) < rank(key($1), seed) }
            .prefix(count)
            .map { $0 }
    }

    static func shuffled(_ values: [String], seed: UInt64) -> [String] {
        values.sorted { rank($0, seed) < rank($1, seed) }
    }

    /// Des leurres tirés du même vivier, jamais égaux à la bonne réponse.
    private static func distractors(for card: VocabCard, in pool: [VocabCard],
                                    seed: UInt64,
                                    value: (VocabCard) -> String) -> [String] {
        let target = value(card)
        var seen = Set([target])
        var out: [String] = []
        for other in pool.sorted(by: { rank($0.french, seed) < rank($1.french, seed) }) {
            let candidate = value(other)
            guard !seen.contains(candidate) else { continue }
            seen.insert(candidate)
            out.append(candidate)
            if out.count == 3 { break }
        }
        return out
    }
}
