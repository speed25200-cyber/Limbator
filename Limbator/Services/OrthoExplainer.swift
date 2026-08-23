import Foundation

/// Met des mots sur une faute.
///
/// Un correcteur qui affiche « attendu : élève / écrit : eleve » n'apprend rien
/// à personne. Celui-ci nomme le mécanisme (« il manque l'accent aigu »),
/// donne le test qui permet de trancher la prochaine fois (« remplace par
/// avait »), et, quand la faute vient du roumain, le dit franchement.
///
/// Les messages sont écrits dans les trois langues d'interface de Limbator :
/// roumain (langue de l'apprenant visé), français et anglais.
enum OrthoExplainer {

    // =========================================================================
    // MARK: - Point d'entrée
    // =========================================================================

    static func explain(kind: OrthoErrorKind, expected: String, written: String) -> String {
        // Une faute nommément identifiée comme calque du roumain mérite son
        // explication propre, bien plus parlante qu'une catégorie générique.
        if kind == .romanianInterference,
           let trap = RomanianInterference.trap(expected: expected, written: written) {
            return romanianTrapMessage(trap)
        }

        switch kind {
        case .accentMissing:        return accentMissingMessage(expected: expected, written: written)
        case .accentWrong:          return accentWrongMessage(expected: expected, written: written)
        case .accentExtra:          return t(ro: "« \(written) » nu poartă accent. Forma corectă este « \(expected) ».",
                                             fr: "« \(written) » ne porte pas d'accent. La forme correcte est « \(expected) ».",
                                             en: "“\(written)” takes no accent. The correct form is “\(expected)”.")
        case .cedillaMissing:       return t(ro: "Lipsește sedila: « \(expected) ». Fără ea, c înainte de a, o, u se citește /k/.",
                                             fr: "La cédille manque : « \(expected) ». Sans elle, le c devant a, o, u se lit /k/.",
                                             en: "The cedilla is missing: “\(expected)”. Without it, c before a, o, u reads /k/.")
        case .cedillaExtra:         return t(ro: "Sedila nu se pune înainte de e, i, y. Scrie « \(expected) ».",
                                             fr: "La cédille ne s'emploie jamais devant e, i, y. Écris « \(expected) ».",
                                             en: "The cedilla is never used before e, i, y. Write “\(expected)”.")
        case .tremaMissing:         return t(ro: "Lipsește trema: « \(expected) ». Trema arată că vocalele se citesc separat.",
                                             fr: "Le tréma manque : « \(expected) ». Il indique que les voyelles se prononcent séparément.",
                                             en: "The diaeresis is missing: “\(expected)”. It marks that the vowels are read separately.")
        case .doubleConsonant:      return doubleConsonantMessage(expected: expected, written: written)
        case .silentLetter:         return silentLetterMessage(expected: expected, written: written)
        case .homophone:            return homophoneMessage(expected: expected, written: written)
        case .verbEnding:           return verbEndingMessage(expected: expected, written: written)
        case .agreement:            return agreementMessage(expected: expected, written: written)
        case .elision:              return t(ro: "Înainte de vocală sau h mut, articolul se elidează: « \(expected) ».",
                                             fr: "Devant une voyelle ou un h muet, l'article s'élide : « \(expected) ».",
                                             en: "Before a vowel or mute h, the article elides: “\(expected)”.")
        case .apostrophe:           return t(ro: "Apostroful nu e la locul lui. Forma corectă: « \(expected) ».",
                                             fr: "L'apostrophe n'est pas à sa place. La forme correcte : « \(expected) ».",
                                             en: "The apostrophe is misplaced. Correct form: “\(expected)”.")
        case .hyphen:               return t(ro: "Cratima contează: se scrie « \(expected) ».",
                                             fr: "Le trait d'union compte : on écrit « \(expected) ».",
                                             en: "The hyphen matters: it is written “\(expected)”.")
        case .ligature:             return t(ro: "Franceza folosește ligatura: « \(expected) », nu « \(written) ».",
                                             fr: "Le français emploie la ligature : « \(expected) », non « \(written) ».",
                                             en: "French uses the ligature: “\(expected)”, not “\(written)”.")
        case .capitalization:       return t(ro: "Doar majuscula diferă: « \(expected) ».",
                                             fr: "Seule la majuscule diffère : « \(expected) ».",
                                             en: "Only the capitalisation differs: “\(expected)”.")
        case .punctuation:          return punctuationMessage(expected: expected, written: written)
        case .spacing:              return t(ro: "În franceză se pune un spațiu fin înainte de ; : ! ?",
                                             fr: "En français, on met une espace fine avant ; : ! ?",
                                             en: "French puts a thin space before ; : ! ?")
        case .romanianInterference: return t(ro: "Ai scris cuvântul după tiparul românesc. În franceză: « \(expected) ».",
                                             fr: "Le mot est écrit sur le modèle roumain. En français : « \(expected) ».",
                                             en: "The word follows the Romanian pattern. In French: “\(expected)”.")
        case .wordOrder:            return t(ro: "Ordinea cuvintelor nu e cea din text.",
                                             fr: "L'ordre des mots ne correspond pas au texte.",
                                             en: "The word order does not match the text.")
        case .missingWord:          return t(ro: "Lipsește un cuvânt: « \(expected) ».",
                                             fr: "Un mot manque : « \(expected) ».",
                                             en: "A word is missing: “\(expected)”.")
        case .extraWord:            return t(ro: "« \(written) » este în plus.",
                                             fr: "« \(written) » est en trop.",
                                             en: "“\(written)” is extra.")
        case .typo:                 return t(ro: "Se scrie « \(expected) ».",
                                             fr: "On écrit « \(expected) ».",
                                             en: "It is written “\(expected)”.")
        }
    }

    /// La règle à réviser, quand la faute en désigne une sans ambiguïté.
    static func ruleId(kind: OrthoErrorKind, expected: String, written: String) -> String? {
        switch kind {
        case .homophone:
            let set = OrthoSeeds.homophoneSet(containing: expected)
            return set.map { "homophones." + $0.id }
        case .accentMissing, .accentWrong, .accentExtra:
            return "accents.aigu-grave"
        case .cedillaMissing, .cedillaExtra:
            return "accents.cedille"
        case .tremaMissing:
            return "accents.trema"
        case .verbEnding:
            return "verbEndings.er-e-ez"
        case .agreement:
            return "agreements.participe-avoir"
        case .doubleConsonant:
            return "doubleLetters.principe"
        case .silentLetter:
            return "silentLetters.finales"
        case .romanianInterference:
            if let trap = RomanianInterference.trap(expected: expected, written: written) {
                return RomanianInterference.circumflexBridges.contains(trap)
                    ? "roTraps.circonflexe-s"
                    : "roTraps.consonnes-doubles"
            }
            return "roTraps.consonnes-doubles"
        case .elision:
            return "silentLetters.h-muet"
        default:
            return nil
        }
    }

    // =========================================================================
    // MARK: - Messages détaillés
    // =========================================================================

    private static func romanianTrapMessage(_ trap: RomanianInterference.Trap) -> String {
        let note = trap.localizedNote
        return t(ro: "Capcană româno-franceză: « \(trap.romanian) » → « \(trap.french) ». \(note)",
                 fr: "Piège roumain/français : « \(trap.romanian) » → « \(trap.french) ». \(note)",
                 en: "Romanian/French trap: “\(trap.romanian)” → “\(trap.french)”. \(note)")
    }

    private static func accentMissingMessage(expected: String, written: String) -> String {
        let marks = FrenchPhonology.diacriticProfile(expected)
        let names = marks.map { FrenchPhonology.accentName($0.mark) }
        let listed = Set(names).sorted().joined(separator: ", ")
        // Le circonflexe raconte une histoire : c'est un S disparu. On la raconte.
        if expected.lowercased().contains(where: { "âêîôû".contains($0) }),
           let bridge = RomanianInterference.circumflexBridges
            .first(where: { $0.french.lowercased() == expected.lowercased() }) {
            return romanianTrapMessage(bridge)
        }
        return t(ro: "Lipsește accentul: « \(expected) » (\(listed)). În franceză accentul face parte din cuvânt, nu e un ornament.",
                 fr: "L'accent manque : « \(expected) » (\(listed)). En français l'accent fait partie du mot, ce n'est pas un ornement.",
                 en: "The accent is missing: “\(expected)” (\(listed)). In French the accent is part of the word, not decoration.")
    }

    private static func accentWrongMessage(expected: String, written: String) -> String {
        let eMarks = FrenchPhonology.diacriticProfile(expected).map { $0.mark }
        let wMarks = FrenchPhonology.diacriticProfile(written).map { $0.mark }
        let wrote = wMarks.first.map { String($0) } ?? "?"
        let want  = eMarks.first.map { String($0) } ?? "?"
        return t(ro: "Accent greșit: ai scris « \(wrote) », trebuie « \(want) » → « \(expected) ». Ascuțitul (é) închide sunetul, gravul (è) îl deschide.",
                 fr: "Mauvais accent : tu as écrit « \(wrote) », il faut « \(want) » → « \(expected) ». L'aigu (é) ferme le son, le grave (è) l'ouvre.",
                 en: "Wrong accent: you wrote “\(wrote)”, it should be “\(want)” → “\(expected)”. The acute (é) closes the sound, the grave (è) opens it.")
    }

    private static func doubleConsonantMessage(expected: String, written: String) -> String {
        if let trap = RomanianInterference.trap(forFrench: expected) {
            return romanianTrapMessage(trap)
        }
        let doubled = doubledLetter(in: expected)
        if let d = doubled, !written.lowercased().contains("\(d)\(d)") {
            return t(ro: "Consoana se dublează: « \(expected) » — doi de \(d).",
                     fr: "La consonne double : « \(expected) » — deux \(d).",
                     en: "The consonant is doubled: “\(expected)” — two \(d).")
        }
        return t(ro: "O consoană e dublată de prisos. Se scrie « \(expected) ».",
                 fr: "Une consonne est doublée à tort. On écrit « \(expected) ».",
                 en: "A consonant is wrongly doubled. It is written “\(expected)”.")
    }

    private static func silentLetterMessage(expected: String, written: String) -> String {
        let tail = OrthographyEngine.silentTail(expected)
        guard !tail.isEmpty else {
            return t(ro: "Se scrie « \(expected) »: ultima literă nu se aude, dar se scrie.",
                     fr: "On écrit « \(expected) » : la dernière lettre ne s'entend pas, mais elle s'écrit.",
                     en: "It is written “\(expected)”: the final letter is silent but written.")
        }
        let related = feminineHint(for: expected)
        let hint = related.map {
            t(ro: " Proba: femininul « \($0) » face litera să se audă.",
              fr: " Preuve : le féminin « \($0) » fait entendre la lettre.",
              en: " Proof: the feminine “\($0)” makes the letter audible.")
        } ?? ""
        return t(ro: "« \(expected) » se termină cu litera mută « \(tail) ».\(hint)",
                 fr: "« \(expected) » se termine par la lettre muette « \(tail) ».\(hint)",
                 en: "“\(expected)” ends in the silent letter “\(tail)”.\(hint)")
    }

    private static func homophoneMessage(expected: String, written: String) -> String {
        guard let set = OrthoSeeds.homophoneSet(containing: expected),
              let right = set.member(expected.lowercased()) else {
            return t(ro: "« \(written) » și « \(expected) » se pronunță la fel, dar nu sunt același cuvânt. Aici trebuie « \(expected) ».",
                     fr: "« \(written) » et « \(expected) » se prononcent pareil mais ne sont pas le même mot. Ici il faut « \(expected) ».",
                     en: "“\(written)” and “\(expected)” sound alike but are different words. Here you need “\(expected)”.")
        }
        let nature = right.localizedNature
        let test = right.localizedTest
        return t(ro: "« \(expected) » este \(nature). Testul: \(test)",
                 fr: "« \(expected) » est \(nature). Le test : \(test)",
                 en: "“\(expected)” is \(nature). The test: \(test)")
    }

    private static func verbEndingMessage(expected: String, written: String) -> String {
        let e = expected.lowercased()
        // Le test universel : remplacer par « vendre », verbe du 3e groupe dont
        // l'infinitif et le participe ne se prononcent pas pareil.
        if e.hasSuffix("er") {
            return t(ro: "Aici e infinitivul: « \(expected) ». Proba cu «vendre»: dacă poți spune «vendre», scrii -er.",
                     fr: "C'est l'infinitif : « \(expected) ». Test avec « vendre » : si « vendre » passe, on écrit -er.",
                     en: "This is the infinitive: “\(expected)”. The “vendre” test: if “vendre” fits, write -er.")
        }
        if e.hasSuffix("é") || e.hasSuffix("ée") || e.hasSuffix("és") || e.hasSuffix("ées") {
            return t(ro: "Aici e participiul trecut: « \(expected) ». Proba cu «vendu»: dacă poți spune «vendu», scrii -é.",
                     fr: "C'est le participe passé : « \(expected) ». Test avec « vendu » : si « vendu » passe, on écrit -é.",
                     en: "This is the past participle: “\(expected)”. The “vendu” test: if “vendu” fits, write -é.")
        }
        if e.hasSuffix("ez") {
            return t(ro: "Terminația -ez cere subiectul «vous»: « \(expected) ».",
                     fr: "La terminaison -ez appelle le sujet « vous » : « \(expected) ».",
                     en: "The -ez ending goes with the subject “vous”: “\(expected)”.")
        }
        if e.hasSuffix("ais") || e.hasSuffix("ait") || e.hasSuffix("aient") {
            return t(ro: "Imperfectul se acordă cu subiectul: « \(expected) ». -ais (je/tu), -ait (il/elle), -aient (ils/elles).",
                     fr: "L'imparfait s'accorde au sujet : « \(expected) ». -ais (je/tu), -ait (il/elle), -aient (ils/elles).",
                     en: "The imperfect agrees with the subject: “\(expected)”. -ais (je/tu), -ait (il/elle), -aient (ils/elles).")
        }
        return t(ro: "Terminația verbului nu e cea potrivită: « \(expected) ».",
                 fr: "La terminaison du verbe n'est pas la bonne : « \(expected) ».",
                 en: "The verb ending is not the right one: “\(expected)”.")
    }

    private static func agreementMessage(expected: String, written: String) -> String {
        let e = expected.lowercased(), w = written.lowercased()
        if e.count > w.count {
            let mark = String(e.dropFirst(w.count))
            return t(ro: "Lipsește marca de acord « \(mark) »: « \(expected) ».",
                     fr: "La marque d'accord « \(mark) » manque : « \(expected) ».",
                     en: "The agreement mark “\(mark)” is missing: “\(expected)”.")
        }
        return t(ro: "Aici nu se face acordul: « \(expected) », nu « \(written) ».",
                 fr: "Ici il n'y a pas d'accord : « \(expected) », pas « \(written) ».",
                 en: "No agreement here: “\(expected)”, not “\(written)”.")
    }

    private static func punctuationMessage(expected: String, written: String) -> String {
        if written.isEmpty {
            return t(ro: "Lipsește semnul « \(expected) ».",
                     fr: "Le signe « \(expected) » manque.",
                     en: "The mark “\(expected)” is missing.")
        }
        if expected.isEmpty {
            return t(ro: "Semnul « \(written) » este în plus.",
                     fr: "Le signe « \(written) » est en trop.",
                     en: "The mark “\(written)” is extra.")
        }
        return t(ro: "Semn de punctuație greșit: « \(expected) », nu « \(written) ».",
                 fr: "Mauvais signe de ponctuation : « \(expected) », pas « \(written) ».",
                 en: "Wrong punctuation mark: “\(expected)”, not “\(written)”.")
    }

    // =========================================================================
    // MARK: - Outils
    // =========================================================================

    /// La lettre effectivement doublée dans le mot (la première rencontrée).
    private static func doubledLetter(in word: String) -> Character? {
        let chars = Array(word.lowercased())
        guard chars.count > 1 else { return nil }
        for i in 0..<(chars.count - 1) where chars[i] == chars[i + 1]
            && !FrenchPhonology.vowelLetters.contains(chars[i]) {
            return chars[i]
        }
        return nil
    }

    /// Le féminin d'un adjectif courant : c'est lui qui « prouve » la lettre
    /// muette finale. « petit » ne s'entend pas, « petite » si.
    private static let feminines: [String: String] = [
        "petit": "petite", "grand": "grande", "grande": "grande", "long": "longue",
        "gros": "grosse", "haut": "haute", "bas": "basse", "froid": "froide",
        "chaud": "chaude", "vert": "verte", "gris": "grise", "blanc": "blanche",
        "français": "française", "content": "contente", "lent": "lente",
        "fort": "forte", "court": "courte", "prêt": "prête", "vivant": "vivante",
        "précis": "précise", "assis": "assise", "mauvais": "mauvaise",
        "heureux": "heureuse", "doux": "douce", "roux": "rousse", "faux": "fausse",
        "premier": "première", "dernier": "dernière", "léger": "légère",
        "sang": "sanguin", "tabac": "tabagie", "temps": "temporel",
        "dent": "dentaire", "art": "artiste", "port": "portuaire",
        "nid": "nidification", "tapis": "tapisserie", "corps": "corporel"
    ]

    private static func feminineHint(for word: String) -> String? {
        feminines[word.lowercased()]
    }

    /// Sélection de la langue d'interface. Le roumain est la langue de
    /// référence de Limbator ; le français sert de repli pour les langues
    /// romanes proches, l'anglais pour tout le reste.
    private static func t(ro: String, fr: String, en: String) -> String {
        switch L.lang {
        case "ro": return ro
        case "fr": return fr
        case "en": return en
        case "it", "es", "pt": return fr
        default:   return en
        }
    }
}
