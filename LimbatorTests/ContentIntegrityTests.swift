import XCTest
@testable import Limbator

/// Le contenu pédagogique est écrit à la main. Ces tests le traitent comme du
/// code : une phrase d'exercice dont la bonne réponse figure aussi parmi les
/// leurres, ou une dictée qui ne contient pas la règle qu'elle prétend
/// travailler, sont des bugs — invisibles à la compilation, visibles en pleine
/// leçon.
final class ContentIntegrityTests: XCTestCase {

    // =========================================================================
    // MARK: - Familles d'homophones
    // =========================================================================

    func testHomophoneSetsAreSound() {
        XCTAssertGreaterThanOrEqual(OrthoSeeds.homophoneSets.count, 20)
        var seenIds = Set<String>()

        for set in OrthoSeeds.homophoneSets {
            XCTAssertTrue(seenIds.insert(set.id).inserted, "identifiant en double : \(set.id)")
            XCTAssertGreaterThanOrEqual(set.members.count, 2,
                                        "famille \(set.id) : au moins deux graphies")

            var seenForms = Set<String>()
            for member in set.members {
                XCTAssertTrue(seenForms.insert(member.form).inserted,
                              "famille \(set.id) : graphie répétée « \(member.form) »")
                XCTAssertFalse(member.test.isEmpty,
                               "« \(member.form) » sans test de substitution — c'est le test "
                               + "qui permet de trancher, pas la définition")
                // La graphie doit apparaître comme MOT ENTIER dans son exemple :
                // sans cela, l'exercice généré ne pourrait pas creuser le trou.
                let words = member.example
                    .split(whereSeparator: { !$0.isLetter && $0 != "'" && $0 != "-" })
                    .map { $0.lowercased() }
                XCTAssertTrue(words.contains(member.form.lowercased()),
                              "« \(member.form) » n'apparaît pas dans son exemple « \(member.example) »")
            }

            // Toutes les graphies d'une famille doivent sonner pareil.
            guard let reference = set.forms.first else { continue }
            for other in set.forms.dropFirst() {
                XCTAssertTrue(FrenchPhonology.areHomophones(reference, other),
                              "famille \(set.id) : « \(reference) » et « \(other) » ne sonnent pas pareil")
            }
        }
    }

    func testHomophoneLookup() {
        XCTAssertNotNil(OrthoSeeds.homophoneSet(containing: "à"))
        XCTAssertNotNil(OrthoSeeds.homophoneSet(containing: "c'est"))
        XCTAssertTrue(OrthoSeeds.areKnownHomophones("a", "à"))
        XCTAssertTrue(OrthoSeeds.areKnownHomophones("ces", "sait"))
        XCTAssertFalse(OrthoSeeds.areKnownHomophones("a", "a"))
        XCTAssertFalse(OrthoSeeds.areKnownHomophones("chat", "chien"))
    }

    // =========================================================================
    // MARK: - Règles
    // =========================================================================

    func testRulesAreComplete() {
        let rules = OrthoRules.all
        XCTAssertGreaterThanOrEqual(rules.count, 40)

        var seen = Set<String>()
        for rule in rules {
            XCTAssertTrue(seen.insert(rule.id).inserted, "règle en double : \(rule.id)")
            XCTAssertFalse(rule.title.isEmpty)
            XCTAssertGreaterThan(rule.statement.count, 30,
                                 "règle \(rule.id) : énoncé trop court pour enseigner quoi que ce soit")
            XCTAssertFalse(rule.examples.isEmpty, "règle \(rule.id) : aucun exemple")
        }
    }

    func testEveryModuleHasRulesAndDrills() {
        for module in OrthoModule.allCases {
            XCTAssertFalse(OrthoRules.rules(for: module).isEmpty,
                           "module \(module.rawValue) sans règle")
            XCTAssertFalse(OrthoDrills.handwritten(for: module).isEmpty,
                           "module \(module.rawValue) sans exercice — l'écran serait vide")
        }
    }

    func testEveryRuleIdCitedByADrillExists() {
        let known = Set(OrthoRules.all.map(\.id))
        for drill in OrthoDrills.all {
            XCTAssertTrue(known.contains(drill.ruleId),
                          "exercice rattaché à une règle inconnue : \(drill.ruleId)")
        }
    }

    // =========================================================================
    // MARK: - Exercices
    // =========================================================================

    func testDrillsAreSolvable() {
        for drill in OrthoDrills.all {
            let label = "[\(drill.module.rawValue)] « \(drill.sentence) »"

            XCTAssertFalse(drill.answer.isEmpty, "\(label) : sans réponse")
            XCTAssertFalse(drill.explanation.isEmpty, "\(label) : sans explication")
            XCTAssertFalse(drill.distractors.contains(drill.answer),
                           "\(label) : la bonne réponse figure parmi les leurres")
            XCTAssertEqual(Set(drill.distractors).count, drill.distractors.count,
                           "\(label) : leurres en double")

            switch drill.kind {
            case .choice, .fill, .accent:
                XCTAssertTrue(drill.sentence.contains("___"),
                              "\(label) : phrase à trou sans marqueur")
            case .correction:
                XCTAssertFalse(drill.sentence.contains("___"),
                               "\(label) : un exercice de correction n'a pas de trou")
            }

            if drill.kind == .choice {
                XCTAssertGreaterThanOrEqual(drill.distractors.count, 1,
                                            "\(label) : QCM sans leurre")
            }
        }
    }

    func testShuffledOptionsAreStable() {
        // SwiftUI redessine plusieurs fois par seconde : un ordre aléatoire à
        // chaque rendu ferait sauter les boutons sous les doigts.
        guard let drill = OrthoDrills.all.first(where: { !$0.distractors.isEmpty }) else {
            return XCTFail("aucun exercice à choix multiple")
        }
        let first = drill.shuffledOptions
        for _ in 0..<20 {
            XCTAssertEqual(drill.shuffledOptions, first)
        }
        XCTAssertTrue(first.contains(drill.answer))
    }

    func testGeneratedHomophoneDrillsAreCorrectByConstruction() {
        let drills = OrthoDrills.homophoneDrills
        XCTAssertGreaterThanOrEqual(drills.count, 40)
        for drill in drills {
            XCTAssertTrue(drill.sentence.contains("___"))
            XCTAssertFalse(drill.distractors.contains(drill.answer))
            // La phrase résolue doit redonner l'exemple d'origine, mot pour mot.
            XCTAssertFalse(drill.solvedSentence.contains("___"))
        }
    }

    // =========================================================================
    // MARK: - Dictées
    // =========================================================================

    func testDictationsAreWellFormed() {
        let all = DictationBank.all
        XCTAssertGreaterThanOrEqual(all.count, 40)

        var seen = Set<String>()
        let knownRules = Set(OrthoRules.all.map(\.id))

        for item in all {
            XCTAssertTrue(seen.insert(item.text).inserted, "dictée en double : « \(item.text) »")
            XCTAssertFalse(item.translation.isEmpty, "« \(item.text) » sans traduction")
            XCTAssertGreaterThanOrEqual(item.wordCount, 4, "« \(item.text) » trop courte")
            XCTAssertLessThanOrEqual(item.wordCount, 20, "« \(item.text) » trop longue à retenir")

            let last = item.text.trimmingCharacters(in: .whitespaces).last
            XCTAssertTrue(".!?…\"".contains(last ?? " "),
                          "« \(item.text) » sans ponctuation finale — la dictée porte aussi sur elle")

            for ruleId in item.targetRules {
                XCTAssertTrue(knownRules.contains(ruleId),
                              "« \(item.text) » vise une règle inconnue : \(ruleId)")
            }
        }
    }

    func testDictationsExistForEveryLevel() {
        for level in ProficiencyLevel.allCases where level != .c2 {
            XCTAssertFalse(DictationBank.dictations(for: level).isEmpty,
                           "aucune dictée au niveau \(level.rawValue)")
        }
    }

    func testDailyPickIsStableAndInRange() {
        // La dictée du jour doit être la même toute la journée.
        let first = DictationBank.pick(level: .b1, seed: 42)
        for _ in 0..<10 {
            XCTAssertEqual(DictationBank.pick(level: .b1, seed: 42).text, first.text)
        }
        // Et rester dans le niveau demandé (ou en dessous).
        for seed in UInt64(0)..<50 {
            let item = DictationBank.pick(level: .a2, seed: seed)
            XCTAssertLessThanOrEqual(item.level, .a2)
        }
    }

    // =========================================================================
    // MARK: - Vocabulaire et leçons
    // =========================================================================

    func testEveryTopicHasContent() {
        for topic in LessonTopic.curriculum {
            let lesson = ContentSeeds.lesson(topic: topic)
            XCTAssertEqual(lesson.topicSlug, topic.slug,
                           "la leçon rendue ne correspond pas au thème demandé")
            XCTAssertGreaterThanOrEqual(lesson.cards.count, 8,
                                        "thème \(topic.slug) : trop peu de vocabulaire")
            XCTAssertGreaterThanOrEqual(lesson.phrases.count, 3)
            XCTAssertNotNil(lesson.orthoSpotlight,
                            "thème \(topic.slug) : sans encadré d'orthographe, ce n'est plus Limbator")
        }
    }

    func testVocabularyCardsAreConsistent() {
        for topic in LessonTopic.curriculum {
            for card in ContentSeeds.lesson(topic: topic).cards {
                XCTAssertFalse(card.french.isEmpty)
                XCTAssertFalse(card.translation.isEmpty, "« \(card.french) » sans traduction")
                XCTAssertFalse(card.exampleSentence.isEmpty, "« \(card.french) » sans exemple")
                // L'exemple doit contenir le mot : sinon la carte enseigne un
                // mot et en illustre un autre.
                let normalizedExample = FrenchPhonology.stripAccents(card.exampleSentence.lowercased())
                let normalizedWord = FrenchPhonology.stripAccents(card.french.lowercased())
                XCTAssertTrue(normalizedExample.contains(normalizedWord),
                              "« \(card.french) » n'apparaît pas dans son exemple « \(card.exampleSentence) »")
                XCTAssertTrue(["m", "f", ""].contains(card.gender),
                              "« \(card.french) » : genre invalide « \(card.gender) »")
            }
        }
    }

    func testTopicLookupIsSafe() {
        XCTAssertEqual(LessonTopic.topic(slug: "greetings").slug, "greetings")
        // Un slug inconnu ne doit jamais faire tomber l'app.
        XCTAssertEqual(LessonTopic.topic(slug: "n'existe-pas").slug, "greetings")
        XCTAssertFalse(LessonTopic.upTo(.a1).isEmpty)
    }

    // =========================================================================
    // MARK: - Récits
    // =========================================================================

    func testStoriesHaveScenes() {
        for story in Story.builtIn {
            XCTAssertFalse(story.chapters.isEmpty, "récit \(story.slug) sans chapitre")
            for chapter in story.chapters {
                let scenes = StorySeeds.scenes(story: story, chapter: chapter)
                XCTAssertGreaterThanOrEqual(scenes.count, 2,
                                            "\(story.slug) ch.\(chapter.index) : trop peu de scènes")
                for scene in scenes {
                    XCTAssertFalse(scene.paragraphFrench.isEmpty)
                    XCTAssertFalse(scene.paragraphNative.isEmpty)
                    XCTAssertFalse(scene.highlightedVocab.isEmpty)
                    // Chaque mot mis en avant doit figurer dans le paragraphe :
                    // sinon le glossaire enseigne un mot que la scène ne dit pas.
                    let paragraph = FrenchPhonology.stripAccents(scene.paragraphFrench.lowercased())
                    for word in scene.highlightedVocab {
                        let needle = FrenchPhonology.stripAccents(word.french.lowercased())
                        XCTAssertTrue(paragraph.contains(needle),
                                      "\(story.slug) : « \(word.french) » absent de sa scène")
                    }
                    if let highlight = scene.orthoHighlight {
                        let needle = FrenchPhonology.stripAccents(highlight.word.lowercased())
                        XCTAssertTrue(paragraph.contains(needle),
                                      "\(story.slug) : l'arrêt sur mot « \(highlight.word) » "
                                      + "porte sur un mot absent du paragraphe")
                    }
                }
            }
        }
    }

    func testStoryLookupIsSafe() {
        XCTAssertEqual(Story.story(slug: "brancusi").slug, "brancusi")
        XCTAssertFalse(Story.story(slug: "inconnu").slug.isEmpty)
        XCTAssertEqual(Story.first.chapter(99).index, 1, "un chapitre inexistant renvoie le premier")
    }

    // =========================================================================
    // MARK: - Pièges roumains
    // =========================================================================

    func testRomanianTrapsAreDistinct() {
        for trap in RomanianInterference.allTraps {
            XCTAssertFalse(trap.calques.isEmpty, "« \(trap.french) » sans graphie fautive")
            for calque in trap.calques {
                XCTAssertNotEqual(calque.lowercased(), trap.french.lowercased(),
                                  "« \(trap.french) » : la graphie fautive est la bonne")
            }
            XCTAssertFalse(trap.note.isEmpty)
        }
        XCTAssertGreaterThanOrEqual(RomanianInterference.allTraps.count, 50)
    }

    func testCircumflexBridgeIsRecognised() {
        // Le pont le plus utile entre les deux langues.
        let trap = RomanianInterference.trap(expected: "fenêtre", written: "fenetre")
        XCTAssertNotNil(trap)
        XCTAssertEqual(trap?.romanian, "fereastră")
    }

    // =========================================================================
    // MARK: - Jeux
    // =========================================================================

    func testGameRoundsArePlayable() {
        for kind in GameKind.allCases where kind != .dictation {
            let rounds = GameSeeds.rounds(kind: kind, level: .b2, count: 8, seed: 7)
            XCTAssertFalse(rounds.isEmpty, "jeu \(kind.rawValue) sans manche jouable")
            for round in rounds {
                XCTAssertFalse(round.frenchTarget.isEmpty)
                XCTAssertTrue(round.options.indices.contains(round.correctIndex),
                              "jeu \(kind.rawValue) : index de bonne réponse hors bornes")
                if kind != .speaking && kind != .wordPuzzle {
                    XCTAssertGreaterThanOrEqual(round.options.count, 2)
                    XCTAssertEqual(Set(round.options).count, round.options.count,
                                   "jeu \(kind.rawValue) : deux propositions identiques")
                }
            }
        }
    }

    func testListeningRoundsNeverOfferHomophones() {
        // Deux homophones en propositions rendraient la manche impossible à
        // gagner à l'oreille : ce n'est pas un exercice, c'est un piège.
        let rounds = GameSeeds.rounds(kind: .listening, level: .c1, count: 12, seed: 3)
        for round in rounds {
            for option in round.options where option != round.correctAnswer {
                XCTAssertFalse(FrenchPhonology.areHomophones(option, round.frenchTarget),
                               "« \(option) » sonne comme « \(round.frenchTarget) »")
            }
        }
    }

    func testRoundIndexIsClampedNotCrashing() {
        // Un index hors bornes doit être ramené, jamais provoquer un arrêt.
        let round = GameRound(kind: "test", prompt: "p", frenchTarget: "t",
                              options: ["a", "b"], correctIndex: 99)
        XCTAssertEqual(round.correctIndex, 1)
        let empty = GameRound(kind: "test", prompt: "p", frenchTarget: "t",
                              options: [], correctIndex: 5)
        XCTAssertEqual(empty.correctIndex, 0)
        XCTAssertEqual(empty.correctAnswer, "")
        XCTAssertFalse(empty.isPlayable)
    }

    func testAccentVariantsDifferFromTheTruth() {
        for card in GameSeeds.accentedPool.prefix(30) {
            for variant in GameSeeds.accentVariants(of: card.french) {
                XCTAssertNotEqual(variant, card.french,
                                  "un leurre identique à la bonne réponse : « \(card.french) »")
            }
        }
    }
}
