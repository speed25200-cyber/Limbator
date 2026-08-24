import XCTest
@testable import Limbator

/// Le moteur de correction est le cœur de Limbator : c'est lui qui transforme
/// une faute en leçon. Ces tests portent sur ce qu'il doit **dire**, pas
/// seulement sur ce qu'il doit détecter — car un diagnostic faux enseigne une
/// règle fausse.
final class OrthographyEngineTests: XCTestCase {

    // =========================================================================
    // MARK: - Phonétisation
    // =========================================================================

    func testHomophoneFamiliesCollide() {
        // Chaque famille doit se rencontrer phonétiquement, sans quoi la
        // correction ne pourrait jamais dire « même son, autre mot ».
        let families: [[String]] = [
            ["a", "à"],
            ["ou", "où"],
            ["et", "est"],
            ["son", "sont"],
            ["on", "ont"],
            ["ces", "ses", "c'est", "s'est", "sais", "sait"],
            ["la", "là", "l'a"],
            ["mais", "mes", "met", "mets", "mai"],
            ["peu", "peut", "peux"],
            ["quand", "quant", "qu'en"],
            ["près", "prêt"],
            ["leur", "leurs"],
            ["tout", "tous", "toux"],
            ["sans", "s'en", "cent", "sang"],
            ["temps", "tant", "t'en"],
            ["sur", "sûr"],
            ["du", "dû"],
            ["sa", "ça"],
            ["vert", "verre", "vers", "ver"],
            ["mer", "mère", "maire"],
            ["voix", "voie", "vois", "voit"],
            ["fin", "faim"],
            ["parlé", "parler", "parlez", "parlait", "parlais", "parlaient"]
        ]
        for family in families {
            guard let reference = family.first else { continue }
            for other in family.dropFirst() {
                XCTAssertTrue(
                    FrenchPhonology.areHomophones(reference, other),
                    "« \(reference) » (\(FrenchPhonology.soundKey(reference))) et "
                    + "« \(other) » (\(FrenchPhonology.soundKey(other))) devraient être homophones")
            }
        }
    }

    func testDistinctWordsStayDistinct() {
        // Le revers : si tout se ressemblait, l'app crierait à l'homophonie
        // devant la moindre faute de frappe.
        let pairs = [("pain", "peine"), ("dessus", "dessous"), ("poisson", "poison"),
                     ("vin", "vent"), ("chat", "chaud"), ("naïf", "nef"),
                     ("maïs", "mais"), ("le", "les"), ("parle", "parler"),
                     ("dessert", "désert")]
        for (a, b) in pairs {
            XCTAssertFalse(FrenchPhonology.areHomophones(a, b),
                           "« \(a) » et « \(b) » ne devraient PAS être homophones")
        }
    }

    func testThirdPersonPluralEndingIsSilent() {
        // « ils parlent » s'entend exactement comme « il parle ». C'est la
        // raison d'être de la seconde lecture rendue par `keys(for:)`.
        XCTAssertTrue(FrenchPhonology.areHomophones("parlent", "parle"))
        XCTAssertTrue(FrenchPhonology.areHomophones("mangent", "mange"))
        // Mais « souvent » reste nasal : ce n'est pas une terminaison verbale.
        XCTAssertEqual(FrenchPhonology.soundKey("souvent"), "suvA")
    }

    func testDiaeresisBreaksDigraphs() {
        // Le tréma existe précisément pour empêcher la lecture en digramme.
        XCTAssertNotEqual(FrenchPhonology.soundKey("naïf"), FrenchPhonology.soundKey("nef"))
        XCTAssertNotEqual(FrenchPhonology.soundKey("maïs"), FrenchPhonology.soundKey("mais"))
    }

    func testAspirateH() {
        XCTAssertTrue(FrenchPhonology.startsWithAspirateH("héros"))
        XCTAssertTrue(FrenchPhonology.startsWithAspirateH("haricot"))
        XCTAssertFalse(FrenchPhonology.startsWithAspirateH("homme"))
        XCTAssertFalse(FrenchPhonology.startsWithAspirateH("hôtel"))
        XCTAssertTrue(FrenchPhonology.requiresElision("ami"))
        XCTAssertTrue(FrenchPhonology.requiresElision("heure"))
        XCTAssertFalse(FrenchPhonology.requiresElision("héros"))
    }

    // =========================================================================
    // MARK: - Classification
    // =========================================================================

    func testHomophoneConfusionBeatsAccentDiagnosis() {
        // Écrire « a » pour « à » n'est PAS un accent oublié : c'est une
        // confusion entre deux mots, qui appelle un test de substitution.
        // Ranger cela parmi les accents serait donner le mauvais conseil.
        XCTAssertEqual(OrthographyEngine.classify(expected: "à", written: "a"), .homophone)
        XCTAssertEqual(OrthographyEngine.classify(expected: "où", written: "ou"), .homophone)
        XCTAssertEqual(OrthographyEngine.classify(expected: "sûr", written: "sur"), .homophone)
        XCTAssertEqual(OrthographyEngine.classify(expected: "là", written: "la"), .homophone)
    }

    func testAccentDiagnosis() {
        XCTAssertEqual(OrthographyEngine.classify(expected: "élève", written: "eleve"), .accentMissing)
        XCTAssertEqual(OrthographyEngine.classify(expected: "élève", written: "élêve"), .accentWrong)
        XCTAssertEqual(OrthographyEngine.classify(expected: "français", written: "francais"), .cedillaMissing)
        XCTAssertEqual(OrthographyEngine.classify(expected: "Noël", written: "Noel"), .tremaMissing)
    }

    func testVerbEndingDiagnosis() {
        XCTAssertEqual(OrthographyEngine.classify(expected: "mangé", written: "manger"), .verbEnding)
        XCTAssertEqual(OrthographyEngine.classify(expected: "parler", written: "parlé"), .verbEnding)
        XCTAssertEqual(OrthographyEngine.classify(expected: "chanté", written: "chantez"), .verbEnding)
    }

    func testAgreementDiagnosis() {
        XCTAssertEqual(OrthographyEngine.classify(expected: "cueillies", written: "cueilli"), .agreement)
        XCTAssertEqual(OrthographyEngine.classify(expected: "grandes", written: "grande"), .agreement)
        XCTAssertEqual(OrthographyEngine.classify(expected: "journaux", written: "journals"), .agreement)
    }

    func testRomanianInterferenceIsNamed() {
        // La remarque la plus utile pour un roumanophone : « tu as écrit le mot
        // à la roumaine », et non « faute de frappe ».
        let cases = [("attention", "atention"), ("adresse", "adrese"),
                     ("fenêtre", "fenetre"), ("hôpital", "hopital"),
                     ("professeur", "profesor"), ("théâtre", "teatre")]
        for (expected, written) in cases {
            XCTAssertEqual(OrthographyEngine.classify(expected: expected, written: written),
                           .romanianInterference,
                           "« \(written) » pour « \(expected) » devrait être signalé comme calque")
        }
    }

    func testSilentLetterBeatsGenericHomophony() {
        // « peti » sonne comme « petit », mais ce n'est pas un mot : dire
        // « lettre muette oubliée » vaut mieux que « confusion de mots ».
        XCTAssertEqual(OrthographyEngine.classify(expected: "petit", written: "peti"), .silentLetter)
        XCTAssertEqual(OrthographyEngine.classify(expected: "grand", written: "gran"), .silentLetter)
    }

    func testTypographyDiagnosis() {
        XCTAssertEqual(OrthographyEngine.classify(expected: "l'ami", written: "lami"), .elision)
        XCTAssertEqual(OrthographyEngine.classify(expected: "peut-être", written: "peutêtre"), .hyphen)
        XCTAssertEqual(OrthographyEngine.classify(expected: "œuf", written: "oeuf"), .ligature)
        XCTAssertEqual(OrthographyEngine.classify(expected: "Paris", written: "paris"), .capitalization)
    }

    // =========================================================================
    // MARK: - Correction complète
    // =========================================================================

    func testPerfectDictationScoresTwenty() {
        let text = "Les lettres que j'ai écrites sont restées sur la table."
        let verdict = OrthographyEngine.evaluate(expected: text, written: text)
        XCTAssertTrue(verdict.isPerfect)
        XCTAssertEqual(verdict.outOfTwenty, 20, accuracy: 0.01)
        XCTAssertTrue(verdict.mistakes.isEmpty)
    }

    func testTypographyDifferencesAreNotMistakes() {
        // Apostrophe typographique, espace insécable, guillemets français :
        // ce que le clavier de l'utilisateur produit ne doit jamais compter
        // comme une faute d'orthographe.
        let expected = "Il n\u{2019}a pas dit « non » aujourd\u{2019}hui."
        let written  = "Il n'a pas dit \"non\" aujourd'hui."
        let verdict = OrthographyEngine.evaluate(expected: expected, written: written)
        XCTAssertTrue(verdict.isPerfect, "fautes signalées : \(verdict.mistakes.map(\.kind))")
    }

    func testAgreementMistakeIsLocatedAndExplained() {
        let expected = "Les pommes que j'ai mangées étaient mûres."
        let written  = "Les pommes que j'ai mangé étaient mûres."
        let verdict = OrthographyEngine.evaluate(expected: expected, written: written)

        XCTAssertFalse(verdict.isPerfect)
        XCTAssertEqual(verdict.mistakes.count, 1)
        let mistake = verdict.mistakes.first
        XCTAssertEqual(mistake?.expected, "mangées")
        XCTAssertEqual(mistake?.written, "mangé")
        XCTAssertFalse(mistake?.explanation.isEmpty ?? true,
                       "une faute sans explication n'apprend rien")
    }

    func testMissingAndExtraWords() {
        let verdict = OrthographyEngine.evaluate(
            expected: "Le chat noir dort sur le mur.",
            written:  "Le chat dort vraiment sur le mur.")
        let kinds = Set(verdict.mistakes.map(\.kind))
        XCTAssertTrue(kinds.contains(.missingWord), "le mot « noir » manque")
        XCTAssertTrue(kinds.contains(.extraWord), "le mot « vraiment » est en trop")
    }

    func testScoreDegradesWithMistakeCount() {
        let expected = "Elle est partie tôt et elle a pris le train de huit heures."
        let one = OrthographyEngine.evaluate(expected: expected,
                                             written: "Elle est parti tôt et elle a pris le train de huit heures.")
        let many = OrthographyEngine.evaluate(expected: expected,
                                              written: "Elle est parti tot est elle à pri le train de huit heure.")
        XCTAssertGreaterThan(one.score, many.score)
        XCTAssertLessThan(one.score, 1.0)
        XCTAssertGreaterThanOrEqual(many.score, 0)
    }

    func testEmptyAnswerDoesNotCrash() {
        let verdict = OrthographyEngine.evaluate(expected: "Bonjour tout le monde.", written: "")
        XCTAssertEqual(verdict.score, 0, accuracy: 0.35)
        XCTAssertFalse(verdict.mistakes.isEmpty)
    }

    func testCharacterSegmentsCoverTheWholeWord() {
        // Le rendu coloré doit restituer chaque lettre attendue : une lettre
        // avalée par le diff disparaîtrait de la correction.
        let segments = OrthographyEngine.characterSegments(expected: "élève", written: "eleve")
        let reconstructed = segments
            .filter { $0.state != .extra }
            .map(\.text)
            .joined()
        XCTAssertEqual(reconstructed, "élève")
    }

    func testSilentTailDetection() {
        XCTAssertEqual(OrthographyEngine.silentTail("petit"), "t")
        XCTAssertEqual(OrthographyEngine.silentTail("temps"), "ps")
        XCTAssertTrue(OrthographyEngine.silentTail("avec").isEmpty)
    }

    func testAcceptableToleratesCaseButNeverAccents() {
        XCTAssertTrue(OrthographyEngine.isAcceptable(expected: "Bonjour", written: "bonjour"))
        XCTAssertTrue(OrthographyEngine.isAcceptable(expected: "Bonjour.", written: "bonjour"))
        // Le point qui compte : un accent manquant reste une faute, sinon
        // l'exercice n'a plus d'objet.
        XCTAssertFalse(OrthographyEngine.isAcceptable(expected: "élève", written: "eleve"))
        XCTAssertFalse(OrthographyEngine.isAcceptable(expected: "français", written: "francais"))
    }
    // =========================================================================
    // MARK: - Rangée d'accents
    // =========================================================================

    func testAccentIsInsertedAtTheCaretNotAtTheEnd() {
        // Le défaut que ce code remplace : « é » atterrissait toujours en fin
        // de texte, ce qui obligeait à réécrire le mot pour corriger un accent.
        let (text, caret) = "etait".inserting("é", at: NSRange(location: 0, length: 1))
        XCTAssertEqual(text, "était")
        XCTAssertEqual(caret, NSRange(location: 1, length: 0))
    }

    func testAccentReplacesTheSelection() {
        let (text, caret) = "cafe".inserting("é", at: NSRange(location: 3, length: 1))
        XCTAssertEqual(text, "café")
        XCTAssertEqual(caret, NSRange(location: 4, length: 0))
    }

    func testInsertionSurvivesAnOutOfBoundsCaret() {
        // Le curseur vient de UIKit et le texte de SwiftUI : rien ne garantit
        // qu'ils soient synchronisés à l'instant de l'insertion.
        let (text, caret) = "à".inserting("ç", at: NSRange(location: 99, length: 40))
        XCTAssertEqual(text, "àç")
        XCTAssertEqual(caret.location, 2)
        XCTAssertEqual(caret.length, 0)
    }

    func testInsertionCountsInUTF16LikeUIKit() {
        // « œ » tient sur une unité UTF-16, mais le raisonnement doit rester
        // celui de UIKit : les positions sont des unités UTF-16, pas des
        // caractères Swift.
        let start = "sur" as NSString
        let (text, caret) = "sur".inserting("œ", at: NSRange(location: start.length, length: 0))
        XCTAssertEqual(text, "surœ")
        XCTAssertEqual(caret.location, (text as NSString).length)
    }

}
