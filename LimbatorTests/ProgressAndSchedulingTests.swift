import XCTest
@testable import Limbator

/// Progression, répétition espacée et robustesse des services.
@MainActor
final class ProgressAndSchedulingTests: XCTestCase {

    // =========================================================================
    // MARK: - Répétition espacée
    // =========================================================================

    func testSuccessfulRepetitionsSpaceOut() {
        let scheduler = SpacedRepetition(preview: [:])
        let key = "rule:test.espacement"

        let first = scheduler.record(key: key, score: 1.0)
        XCTAssertEqual(first.interval, 1)
        let second = scheduler.record(key: key, score: 1.0)
        XCTAssertEqual(second.interval, 6)
        let third = scheduler.record(key: key, score: 1.0)
        XCTAssertGreaterThan(third.interval, second.interval)
    }

    func testFailureResetsIntervalButKeepsEasiness() {
        let scheduler = SpacedRepetition(preview: [:])
        let key = "rule:test.echec"
        scheduler.record(key: key, score: 1.0)
        scheduler.record(key: key, score: 1.0)
        let beforeEasiness = scheduler.mastery(key: key)?.easiness ?? 0

        let failed = scheduler.record(key: key, score: 0.2)
        XCTAssertEqual(failed.interval, 1, "un échec ramène l'item au lendemain")
        XCTAssertEqual(failed.repetitions, 0)
        XCTAssertEqual(failed.lapses, 1)
        // Un mauvais jour ne doit pas effacer des semaines d'apprentissage.
        XCTAssertGreaterThan(failed.easiness, 1.2)
        XCTAssertLessThan(failed.easiness, beforeEasiness)
    }

    func testEasinessStaysWithinBounds() {
        let scheduler = SpacedRepetition(preview: [:])
        for _ in 0..<40 { scheduler.record(key: "rule:a", score: 0.0) }
        for _ in 0..<40 { scheduler.record(key: "rule:b", score: 1.0) }
        XCTAssertGreaterThanOrEqual(scheduler.mastery(key: "rule:a")?.easiness ?? 0, 1.3)
        XCTAssertLessThanOrEqual(scheduler.mastery(key: "rule:b")?.easiness ?? 9, 2.8)
    }

    func testIntervalIsCappedAtOneYear() {
        let scheduler = SpacedRepetition(preview: [:])
        for _ in 0..<30 { scheduler.record(key: "rule:long", score: 1.0) }
        XCTAssertLessThanOrEqual(scheduler.mastery(key: "rule:long")?.interval ?? 0, 365)
    }

    func testModuleMasteryStartsAtZero() {
        let scheduler = SpacedRepetition(preview: [:])
        // Un module jamais travaillé n'affiche pas fièrement 100 %.
        for module in OrthoModule.allCases {
            XCTAssertEqual(scheduler.mastery(of: module), 0, accuracy: 0.001)
        }
    }

    func testModuleMasteryRisesWithPractice() {
        let scheduler = SpacedRepetition(preview: [:])
        let rules = OrthoRules.rules(for: .accents)
        for rule in rules {
            for _ in 0..<5 { scheduler.record(ruleId: rule.id, score: 1.0) }
        }
        XCTAssertGreaterThan(scheduler.mastery(of: .accents), 0.2)
    }

    func testDueItemsAreOrderedByUrgency() {
        let scheduler = SpacedRepetition(preview: [:])
        scheduler.record(key: "rule:x", score: 0.1)   // dû demain
        scheduler.record(key: "rule:y", score: 1.0)
        scheduler.record(key: "rule:y", score: 1.0)   // dû dans six jours
        let due = scheduler.dueKeys(at: Date().addingTimeInterval(60 * 60 * 24 * 3))
        XCTAssertEqual(due.first, "rule:x")
        XCTAssertFalse(due.contains("rule:y"))
    }

    // =========================================================================
    // MARK: - Progression
    // =========================================================================

    func testDictationUpdatesRunningAverage() {
        let tracker = ProgressTracker(preview: .empty)
        let perfect = OrthographyEngine.evaluate(expected: "Bonjour à tous.",
                                                 written: "Bonjour à tous.")
        tracker.recordDictation(perfect)
        XCTAssertEqual(tracker.profile.dictationsDone, 1)
        XCTAssertEqual(tracker.profile.dictationAverage, 20, accuracy: 0.01)

        let flawed = OrthographyEngine.evaluate(expected: "Bonjour à tous.",
                                                written: "Bonjour a tous.")
        tracker.recordDictation(flawed)
        XCTAssertEqual(tracker.profile.dictationsDone, 2)
        XCTAssertLessThan(tracker.profile.dictationAverage, 20)
        XCTAssertGreaterThan(tracker.profile.dictationAverage, 10)
    }

    func testMistakeProfileAccumulates() {
        let tracker = ProgressTracker(preview: .empty)
        let verdict = OrthographyEngine.evaluate(
            expected: "Les fleurs que j'ai cueillies étaient belles.",
            written:  "Les fleurs que j'ai cueilli etaient belles.")
        tracker.recordDictation(verdict)
        XCTAssertFalse(tracker.profile.mistakeCounts.isEmpty)
        XCTAssertFalse(tracker.profile.topWeaknesses.isEmpty)
    }

    func testPerfectDictationUnlocksBadge() {
        let tracker = ProgressTracker(preview: .empty)
        let perfect = OrthographyEngine.evaluate(expected: "Il fait beau.", written: "Il fait beau.")
        tracker.recordDictation(perfect)
        XCTAssertTrue(tracker.profile.badgesEarned.contains("dictee_20"))
        XCTAssertTrue(tracker.profile.badgesEarned.contains("first_dictee"))
    }

    func testRepeatingALessonEarnsLess() {
        let tracker = ProgressTracker(preview: .empty)
        tracker.completeLesson("greetings", xp: 50)
        let afterFirst = tracker.profile.xp
        tracker.completeLesson("greetings", xp: 50)
        let gained = tracker.profile.xp - afterFirst
        XCTAssertLessThan(gained, 50, "refaire une leçon déjà acquise ne doit pas rapporter autant")
        XCTAssertGreaterThan(gained, 0)
    }

    func testStreakCountsOncePerDay() {
        let tracker = ProgressTracker(preview: .empty)
        tracker.bumpStreak()
        tracker.bumpStreak()
        tracker.bumpStreak()
        XCTAssertEqual(tracker.profile.streakDays, 1, "trois actions le même jour font un jour")
    }

    func testProfileDecodesOlderPayloads() throws {
        // Un profil enregistré par une version antérieure doit rester lisible :
        // perdre la progression d'un utilisateur à la mise à jour est
        // impardonnable.
        let legacy = """
        {"name":"Ioana","nativeLanguageId":"ro","level":"B1","dailyGoalMinutes":15,
         "xp":420,"streakDays":4,"lastActiveDay":null,"completedLessons":["greetings"],
         "unlockedStories":[],"badgesEarned":["first_word"]}
        """
        let profile = try JSONDecoder().decode(UserProfile.self, from: Data(legacy.utf8))
        XCTAssertEqual(profile.name, "Ioana")
        XCTAssertEqual(profile.xp, 420)
        XCTAssertEqual(profile.level, .b1)
        // Les champs récents prennent une valeur neutre plutôt que d'échouer.
        XCTAssertEqual(profile.dictationsDone, 0)
        XCTAssertEqual(profile.bestStreak, 0)
        XCTAssertTrue(profile.mistakeCounts.isEmpty)
    }

    func testUnknownLanguageFallsBackToRomanian() {
        var profile = UserProfile.empty
        profile.nativeLanguageId = "xx"
        XCTAssertEqual(profile.nativeLanguage.id, "ro")
    }

    // =========================================================================
    // MARK: - Robustesse du générateur
    // =========================================================================

    func testJSONExtractionSurvivesChattyModels() {
        // Un modèle bavard enrobe sa réponse de commentaires : on ne garde que
        // l'objet équilibré.
        let cases = [
            ("Voici le résultat : {\"a\":1} — voilà.", "{\"a\":1}"),
            ("```json\n{\"a\":{\"b\":2}}\n```", "{\"a\":{\"b\":2}}"),
            ("[{\"x\":1},{\"y\":2}] fin", "[{\"x\":1},{\"y\":2}]"),
            // Une accolade DANS une chaîne ne doit pas fausser le comptage.
            ("{\"text\":\"une } accolade\"}", "{\"text\":\"une } accolade\"}")
        ]
        for (raw, expected) in cases {
            XCTAssertEqual(GemmaService.extractJSON(from: raw), expected)
        }
    }

    func testDictationValidationRejectsOffTopicSentences() {
        let generator = ContentGenerator.shared
        guard let accentRule = OrthoRules.rule(id: "accents.cedille"),
              let agreementRule = OrthoRules.rule(id: "agreements.participe-avoir") else {
            return XCTFail("règles de référence introuvables")
        }

        // Trop courte.
        XCTAssertFalse(generator.isUsableDictation("Bonjour.", translation: "Bună.",
                                                   rule: accentRule))
        // Sans traduction.
        XCTAssertFalse(generator.isUsableDictation("Le garçon reçoit une leçon de français.",
                                                   translation: "", rule: accentRule))
        // Sans ponctuation finale.
        XCTAssertFalse(generator.isUsableDictation("Le garçon reçoit une leçon de français",
                                                   translation: "Băiatul primește o lecție",
                                                   rule: accentRule))
        // Ne met pas la règle à l'épreuve : aucun accord d'auxiliaire.
        XCTAssertFalse(generator.isUsableDictation("Bonjour tout le monde ici.",
                                                   translation: "Bună ziua tuturor.",
                                                   rule: agreementRule))
        // Correcte et pertinente.
        XCTAssertTrue(generator.isUsableDictation("Le garçon reçoit une leçon de français.",
                                                  translation: "Băiatul primește o lecție de franceză.",
                                                  rule: accentRule))
    }

    func testGeneratorFallsBackWithoutModel() {
        // Sans Gemma, l'app doit rester entièrement utilisable.
        let rounds = ContentGenerator.shared.gameRounds(kind: .match, level: .a2, count: 6)
        XCTAssertEqual(rounds.count, 6)
        XCTAssertTrue(rounds.allSatisfy(\.isPlayable))
    }

    func testGeneratedSentenceValidationIsStrict() {
        let generator = ContentGenerator.shared

        // La forme visée doit être là, une seule fois, comme MOT ENTIER.
        XCTAssertTrue(generator.carries("Il a un chien noir chez lui.",
                                        target: "a", forbidding: ["à"]))
        // « a » figure aussi dans « chat », mais pas comme mot : la recherche
        // par sous-chaîne se tromperait, pas la nôtre.
        XCTAssertTrue(generator.carries("Le chat a mangé toute la pâtée.",
                                        target: "a", forbidding: ["à"]))
        // Une forme concurrente rendrait l'exercice ambigu : deux bonnes
        // réponses possibles selon l'emplacement du trou.
        XCTAssertFalse(generator.carries("Il a donné le livre à Marie.",
                                         target: "a", forbidding: ["à"]))
        // Deux occurrences : on ne saurait pas quelle occurrence creuser.
        XCTAssertFalse(generator.carries("Il a un chien et elle a un chat.",
                                         target: "a", forbidding: ["à"]))
        // Absente.
        XCTAssertFalse(generator.carries("Elle part demain matin très tôt.",
                                         target: "a", forbidding: ["à"]))
        // Trop courte, sans ponctuation finale, ou porteuse de restes de JSON.
        XCTAssertFalse(generator.carries("Il a faim.", target: "a", forbidding: ["à"]))
        XCTAssertFalse(generator.carries("Il a un chien noir chez lui",
                                         target: "a", forbidding: ["à"]))
        XCTAssertFalse(generator.carries("Il a un chien noir chez lui.\"}",
                                         target: "a", forbidding: ["à"]))
    }

    func testGapCarvesTheWholeWordOnly() {
        // Creuser « a » dans « Il a un chat » ne doit pas toucher le « a » de
        // « chat » : le trou serait au mauvais endroit et la phrase illisible.
        XCTAssertEqual(OrthoDrills.gap("a", in: "Il a un chat."), "Il ___ un chat.")
        XCTAssertEqual(OrthoDrills.gap("à", in: "Il va à Paris."), "Il va ___ Paris.")
        // La ponctuation attachée au mot est conservée.
        XCTAssertEqual(OrthoDrills.gap("là", in: "Reste là, s'il te plaît."),
                       "Reste ___, s'il te plaît.")
        // Mot absent : rien à creuser.
        XCTAssertNil(OrthoDrills.gap("où", in: "Il part demain."))
    }

    // =========================================================================
    // MARK: - Épellation
    // =========================================================================

    func testSpellerNamesAccents() {
        let spelled = FrenchSpeller.spell("élève")
        XCTAssertTrue(spelled.contains("accent aigu"))
        XCTAssertTrue(spelled.contains("accent grave"))
        XCTAssertTrue(FrenchSpeller.spell("français").contains("cédille"))
        XCTAssertTrue(FrenchSpeller.spell("Noël").contains("tréma"))
    }

    func testSpellerAnnouncesDoubledConsonants() {
        // « deux p » est ainsi qu'on retient une consonne double — et c'est
        // justement la faute la plus fréquente d'un roumanophone.
        XCTAssertTrue(FrenchSpeller.spell("appeler").contains("deux pé"))
        XCTAssertTrue(FrenchSpeller.spell("adresse").contains("deux esse"))
    }

    func testSpellerHandlesEmptyAndPunctuation() {
        XCTAssertEqual(FrenchSpeller.spell(""), "")
        XCTAssertTrue(FrenchSpeller.spell("l'ami").contains("apostrophe"))
        XCTAssertTrue(FrenchSpeller.spell("peut-être").contains("trait d'union"))
    }

    // =========================================================================
    // MARK: - Localisation
    // =========================================================================

    func testEveryInterfaceStringResolvesInEveryLanguage() {
        let previous = L.lang
        defer { L.lang = previous }
        for language in ["ro", "fr", "en"] {
            L.lang = language
            for key in L.allKeys {
                XCTAssertNotEqual(L.t(key), key,
                                  "clé non traduite en \(language) : \(key)")
            }
        }
    }

    func testUnknownLanguageFallsBackWithoutCrashing() {
        let previous = L.lang
        defer { L.lang = previous }
        L.lang = "xx"
        XCTAssertFalse(L.t("tab.home").isEmpty)
        XCTAssertEqual(L.t("cle.inexistante"), "cle.inexistante",
                       "une clé oubliée s'affiche telle quelle, donc se voit")
    }

    func testContentTranslationFallsBackToSource() {
        let previous = L.lang
        defer { L.lang = previous }
        L.lang = "fr"
        // Une chaîne absente de la table revient inchangée : rien ne disparaît
        // de l'écran.
        XCTAssertEqual(ContentL10n.s("chaîne jamais traduite"), "chaîne jamais traduite")
        XCTAssertEqual(ContentL10n.s("Accente"), "Accents")
        L.lang = "ro"
        XCTAssertEqual(ContentL10n.s("Accente"), "Accente")
    }
}
