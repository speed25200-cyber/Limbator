import Foundation

/// Le correcteur. Il ne dit pas « faux » : il dit **pourquoi**.
///
/// Comparer deux chaînes est trivial. Le travail utile commence après :
/// classer l'écart (accent oublié ? homophone confondu ? accord manqué ?
/// graphie calquée sur le roumain ?), le situer dans la phrase, et le
/// rattacher à la règle qui l'explique. C'est ce diagnostic — pas la note —
/// qui fait progresser en orthographe.
///
/// Sans état, sans dépendance : entièrement testable.
enum OrthographyEngine {

    // =========================================================================
    // MARK: - Normalisation
    // =========================================================================

    /// Uniformise ce qui ne doit jamais compter comme une faute : apostrophe
    /// typographique contre apostrophe droite, espaces insécables, espaces
    /// multiples, guillemets. Les accents et la casse, eux, sont conservés :
    /// ce sont justement les objets de l'exercice.
    static func normalizeTypography(_ s: String) -> String {
        var t = s
        t = t.replacingOccurrences(of: "\u{2019}", with: "'")   // ’ -> '
        t = t.replacingOccurrences(of: "\u{02BC}", with: "'")
        t = t.replacingOccurrences(of: "\u{00A0}", with: " ")   // espace insécable
        t = t.replacingOccurrences(of: "\u{202F}", with: " ")   // espace fine insécable
        t = t.replacingOccurrences(of: "\u{2013}", with: "-")   // tiret demi-cadratin
        t = t.replacingOccurrences(of: "\u{2014}", with: "-")
        t = t.replacingOccurrences(of: "«", with: "\"")
        t = t.replacingOccurrences(of: "»", with: "\"")
        t = t.replacingOccurrences(of: "\u{201C}", with: "\"")
        t = t.replacingOccurrences(of: "\u{201D}", with: "\"")
        t = t.replacingOccurrences(of: "\u{2026}", with: "...")
        t = t.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Réduction maximale : sans accents, sans casse, sans ponctuation.
    /// Sert uniquement à décider si deux mots sont « le même mot mal accentué ».
    static func skeleton(_ s: String) -> String {
        FrenchPhonology.stripAccents(s.lowercased())
            .filter { $0.isLetter || $0 == "-" || $0 == "'" }
    }

    // =========================================================================
    // MARK: - Découpage
    // =========================================================================

    /// Un jeton : soit un mot, soit un signe de ponctuation. Les séparer permet
    /// de traiter une virgule oubliée comme une broutille et un mot oublié
    /// comme une vraie faute.
    struct Token: Hashable {
        let text: String
        let isPunctuation: Bool
    }

    static func tokenize(_ s: String) -> [Token] {
        var tokens: [Token] = []
        var current = ""
        // L'apostrophe et le trait d'union appartiennent au mot : « l'ami »,
        // « peut-être » sont des unités orthographiques, pas deux mots.
        func flush() {
            if !current.isEmpty { tokens.append(Token(text: current, isPunctuation: false)) }
            current = ""
        }
        for ch in normalizeTypography(s) {
            if ch.isLetter || ch.isNumber || ch == "'" || ch == "-" {
                current.append(ch)
            } else if ch == " " {
                flush()
            } else {
                flush()
                tokens.append(Token(text: String(ch), isPunctuation: true))
            }
        }
        flush()
        return tokens
    }

    // =========================================================================
    // MARK: - Alignement
    // =========================================================================

    enum Op: Hashable {
        case match(expected: Token, written: Token)
        case substitute(expected: Token, written: Token)
        case delete(expected: Token)      // l'apprenant a oublié ce jeton
        case insert(written: Token)       // l'apprenant a ajouté ce jeton
    }

    /// Alignement de Needleman-Wunsch sur les jetons. Le coût de substitution
    /// est **modulé par la ressemblance** : « élève » contre « eleve » coûte
    /// moins qu'un mot totalement différent, donc l'algorithme préfère les
    /// apparier plutôt que d'inventer une suppression suivie d'une insertion.
    static func align(expected: [Token], written: [Token]) -> [Op] {
        let n = expected.count, m = written.count
        if n == 0 { return written.map { .insert(written: $0) } }
        if m == 0 { return expected.map { .delete(expected: $0) } }

        let gap = 1.0
        var cost = Array(repeating: Array(repeating: 0.0, count: m + 1), count: n + 1)
        for i in 0...n { cost[i][0] = Double(i) * gap }
        for j in 0...m { cost[0][j] = Double(j) * gap }

        for i in 1...n {
            for j in 1...m {
                let sub = cost[i - 1][j - 1] + substitutionCost(expected[i - 1], written[j - 1])
                let del = cost[i - 1][j] + gap
                let ins = cost[i][j - 1] + gap
                cost[i][j] = min(sub, min(del, ins))
            }
        }

        // Remontée. À égalité on privilégie la substitution : deux mots alignés
        // se laissent expliquer, une suppression + insertion ne dit rien.
        var ops: [Op] = []
        var i = n, j = m
        while i > 0 || j > 0 {
            if i > 0, j > 0 {
                let sub = cost[i - 1][j - 1] + substitutionCost(expected[i - 1], written[j - 1])
                if abs(cost[i][j] - sub) < 1e-9 {
                    let e = expected[i - 1], w = written[j - 1]
                    ops.append(e.text == w.text ? .match(expected: e, written: w)
                                                : .substitute(expected: e, written: w))
                    i -= 1; j -= 1; continue
                }
            }
            if i > 0, abs(cost[i][j] - (cost[i - 1][j] + gap)) < 1e-9 {
                ops.append(.delete(expected: expected[i - 1])); i -= 1; continue
            }
            if j > 0 {
                ops.append(.insert(written: written[j - 1])); j -= 1; continue
            }
            break
        }
        return ops.reversed()
    }

    /// 0 = identiques, 1 = sans rapport. Les quasi-identiques restent bien en
    /// dessous du coût d'une paire suppression/insertion (2 × gap).
    private static func substitutionCost(_ a: Token, _ b: Token) -> Double {
        if a.text == b.text { return 0 }
        if a.isPunctuation != b.isPunctuation { return 1.2 }
        if a.text.lowercased() == b.text.lowercased() { return 0.1 }
        if skeleton(a.text) == skeleton(b.text) { return 0.2 }
        if FrenchPhonology.areHomophones(a.text, b.text) { return 0.35 }
        let d = Double(levenshtein(Array(a.text.lowercased()), Array(b.text.lowercased())))
        let len = Double(max(a.text.count, b.text.count, 1))
        // Plafonné à 0,95 pour rester sous 2 × gap : deux mots même très
        // différents restent alignés s'ils occupent la même place.
        return min(0.95, 0.3 + 0.65 * (d / len))
    }

    static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        var current = Array(repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let sub = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)
                current[j] = min(sub, min(previous[j] + 1, current[j - 1] + 1))
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }

    // =========================================================================
    // MARK: - Classification
    // =========================================================================

    /// Le diagnostic d'un mot mal écrit. C'est ici que se joue la valeur
    /// pédagogique de l'app : l'ordre des tests va du plus explicatif au plus
    /// générique, pour ne jamais répondre « faute de frappe » quand on peut
    /// répondre « accord du participe passé ».
    static func classify(expected: String, written: String) -> OrthoErrorKind {
        let e = normalizeTypography(expected)
        let w = normalizeTypography(written)
        if e == w { return .typo }   // ne devrait pas arriver : appelé sur un écart

        let eLower = e.lowercased(), wLower = w.lowercased()

        // 1. Seule la casse diffère.
        if eLower == wLower { return .capitalization }

        // 2. Deux graphies d'une même famille d'homophones : c'est le cas le
        //    plus fréquent ET le plus instructif. Il passe AVANT le test des
        //    accents, sinon « a » écrit pour « à » serait rangé parmi les
        //    accents oubliés — alors que c'est une confusion de mots, qui
        //    appelle un test de substitution, pas un rappel sur l'accent grave.
        if OrthoSeeds.areKnownHomophones(e, w) { return .homophone }

        // 3. Un calque du roumain identifié nommément : la remarque la plus utile.
        if RomanianInterference.trap(expected: e, written: w) != nil {
            return .romanianInterference
        }

        // 4. Ligature.
        let deLigature: (String) -> String = {
            $0.replacingOccurrences(of: "œ", with: "oe")
              .replacingOccurrences(of: "æ", with: "ae")
        }
        if deLigature(eLower) == deLigature(wLower) { return .ligature }

        // 5. Apostrophe / élision.
        if eLower.replacingOccurrences(of: "'", with: "") ==
           wLower.replacingOccurrences(of: "'", with: "") {
            let eHas = eLower.contains("'"), wHas = wLower.contains("'")
            if eHas && !wHas { return .elision }
            return .apostrophe
        }
        if eLower.contains("'") != wLower.contains("'"),
           skeleton(e).replacingOccurrences(of: "'", with: "") ==
           skeleton(w).replacingOccurrences(of: "'", with: "") {
            return .elision
        }

        // 6. Trait d'union.
        if eLower.replacingOccurrences(of: "-", with: "") ==
           wLower.replacingOccurrences(of: "-", with: "") {
            return .hyphen
        }

        // 7. Même squelette : la différence est purement diacritique.
        if skeleton(e) == skeleton(w) {
            return accentSubtype(expected: e, written: w)
        }

        // 8. Consonnes doubles : « apeler » contre « appeler ».
        if RomanianInterference.collapseDoubles(eLower) ==
           RomanianInterference.collapseDoubles(wLower) {
            return .doubleConsonant
        }
        if RomanianInterference.collapseDoubles(skeleton(e)) ==
           RomanianInterference.collapseDoubles(skeleton(w)) {
            // Doubles ET accents en cause : la consonne double est la faute de fond.
            return .doubleConsonant
        }

        // 9. Terminaison verbale homophone : le piège numéro un du français.
        if let ending = verbEndingConfusion(expected: eLower, written: wLower) {
            return ending
        }

        // 10. Marque d'accord ajoutée ou retirée en fin de mot (s, e, es, x).
        if let agreement = agreementDifference(expected: eLower, written: wLower) {
            return agreement
        }

        // 11. Lettre finale muette oubliée : « peti » pour « petit ». Ce test
        //     passe AVANT l'homophonie générale : « peti » et « petit » sonnent
        //     bien pareil, mais « peti » n'est pas un mot — dire « tu as oublié
        //     la lettre muette » vaut mieux que « tu as confondu deux mots ».
        //     Les vrais couples homophones (« son »/« sont ») sont déjà partis
        //     à l'étape 2.
        if eLower.hasPrefix(wLower), eLower.count > wLower.count, eLower.count - wLower.count <= 2 {
            let tail = String(eLower.dropFirst(wLower.count))
            if tail.allSatisfy({ "estdxzpgh".contains($0) }) { return .silentLetter }
        }
        if wLower.hasPrefix(eLower), wLower.count > eLower.count, wLower.count - eLower.count <= 2 {
            let tail = String(wLower.dropFirst(eLower.count))
            if tail.allSatisfy({ "estdxzpgh".contains($0) }) { return .silentLetter }
        }

        // 12. Homophones lexicaux non répertoriés : même son, autre graphie.
        if FrenchPhonology.areHomophones(e, w) { return .homophone }

        return .typo
    }

    /// Quel type d'accident diacritique ? On compare les profils d'accents.
    private static func accentSubtype(expected: String, written: String) -> OrthoErrorKind {
        let eLower = expected.lowercased(), wLower = written.lowercased()
        let eHasCedilla = eLower.contains("ç"), wHasCedilla = wLower.contains("ç")
        if eHasCedilla && !wHasCedilla { return .cedillaMissing }
        if wHasCedilla && !eHasCedilla { return .cedillaExtra }

        let trema: Set<Character> = ["ë", "ï", "ü", "ÿ"]
        let eTrema = eLower.contains { trema.contains($0) }
        let wTrema = wLower.contains { trema.contains($0) }
        if eTrema && !wTrema { return .tremaMissing }

        let eMarks = FrenchPhonology.diacriticProfile(eLower)
        let wMarks = FrenchPhonology.diacriticProfile(wLower)
        if wMarks.isEmpty && !eMarks.isEmpty { return .accentMissing }
        if eMarks.isEmpty && !wMarks.isEmpty { return .accentExtra }
        if wMarks.count < eMarks.count { return .accentMissing }
        if wMarks.count > eMarks.count { return .accentExtra }
        return .accentWrong
    }

    /// Les terminaisons qui se prononcent pareil et s'écrivent autrement.
    private static func verbEndingConfusion(expected: String, written: String) -> OrthoErrorKind? {
        // Le radical doit être commun : sinon ce sont deux mots différents.
        let common = commonPrefixLength(expected, written)
        guard common >= 2 else { return nil }
        let eEnd = String(Array(expected).dropFirst(common))
        let wEnd = String(Array(written).dropFirst(common))
        guard !eEnd.isEmpty || !wEnd.isEmpty else { return nil }

        for group in FrenchPhonology.verbEndingGroups {
            let set = Set(group)
            if set.contains(eEnd) && set.contains(wEnd) { return .verbEnding }
        }
        // Cas « -é » contre « -er » quand le radical inclut déjà une partie.
        let pairs: [(String, String)] = [
            ("é", "er"), ("er", "é"), ("é", "ez"), ("ez", "é"),
            ("ée", "er"), ("és", "er"), ("ées", "er"),
            ("ais", "ait"), ("ait", "ais"), ("ai", "ais"), ("ais", "ai"),
            ("aient", "ait"), ("ait", "aient"), ("ai", "é"), ("é", "ai")
        ]
        if pairs.contains(where: { $0.0 == eEnd && $0.1 == wEnd }) { return .verbEnding }
        return nil
    }

    /// Marque d'accord (pluriel / féminin) ajoutée ou omise en fin de mot.
    private static func agreementDifference(expected: String, written: String) -> OrthoErrorKind? {
        let marks = ["s", "e", "es", "x", "aux", "ux", "nes", "ne", "le", "les", "te", "tes"]
        if expected.hasPrefix(written) {
            let tail = String(expected.dropFirst(written.count))
            if marks.contains(tail) { return .agreement }
        }
        if written.hasPrefix(expected) {
            let tail = String(written.dropFirst(expected.count))
            if marks.contains(tail) { return .agreement }
        }
        // « -al » / « -aux » : le pluriel irrégulier le plus fréquent.
        if expected.hasSuffix("aux"), written.hasSuffix("als"),
           expected.dropLast(3) == written.dropLast(3) { return .agreement }
        if expected.hasSuffix("als"), written.hasSuffix("aux"),
           expected.dropLast(3) == written.dropLast(3) { return .agreement }
        return nil
    }

    private static func commonPrefixLength(_ a: String, _ b: String) -> Int {
        let ac = Array(a), bc = Array(b)
        var i = 0
        while i < ac.count && i < bc.count && ac[i] == bc[i] { i += 1 }
        return i
    }

    // =========================================================================
    // MARK: - Correction complète
    // =========================================================================

    /// Corrige une saisie contre la phrase attendue et rend un verdict complet :
    /// note, fautes classées et expliquées, et rendu coloré prêt à afficher.
    static func evaluate(expected: String, written: String) -> OrthoVerdict {
        let expectedClean = normalizeTypography(expected)
        let writtenClean  = normalizeTypography(written)

        let eTokens = tokenize(expectedClean)
        let wTokens = tokenize(writtenClean)
        let ops = align(expected: eTokens, written: wTokens)

        var mistakes: [OrthoMistake] = []
        var segments: [OrthoVerdict.DiffSegment] = []
        var wordIndex = 0

        for op in ops {
            switch op {
            case .match(let e, _):
                segments.append(.init(text: e.text, state: .correct))
                if !e.isPunctuation { wordIndex += 1 }

            case .substitute(let e, let w):
                let kind = e.isPunctuation || w.isPunctuation
                    ? OrthoErrorKind.punctuation
                    : classify(expected: e.text, written: w.text)
                mistakes.append(OrthoMistake(
                    kind: kind,
                    expected: e.text,
                    written: w.text,
                    wordIndex: wordIndex,
                    explanation: OrthoExplainer.explain(kind: kind, expected: e.text, written: w.text),
                    ruleId: OrthoExplainer.ruleId(kind: kind, expected: e.text, written: w.text)))
                segments.append(contentsOf: characterSegments(expected: e.text, written: w.text))
                if !e.isPunctuation { wordIndex += 1 }

            case .delete(let e):
                let kind = e.isPunctuation ? OrthoErrorKind.punctuation : .missingWord
                mistakes.append(OrthoMistake(
                    kind: kind, expected: e.text, written: "",
                    wordIndex: wordIndex,
                    explanation: OrthoExplainer.explain(kind: kind, expected: e.text, written: ""),
                    ruleId: nil))
                segments.append(.init(text: e.text, state: .missing))
                if !e.isPunctuation { wordIndex += 1 }

            case .insert(let w):
                let kind = w.isPunctuation ? OrthoErrorKind.punctuation : .extraWord
                mistakes.append(OrthoMistake(
                    kind: kind, expected: "", written: w.text,
                    wordIndex: -1,
                    explanation: OrthoExplainer.explain(kind: kind, expected: "", written: w.text),
                    ruleId: nil))
                segments.append(.init(text: w.text, state: .extra))
            }
        }

        let wordCount = max(3, eTokens.filter { !$0.isPunctuation }.count)
        let penalty = mistakes.reduce(0.0) { $0 + $1.kind.weight }
        let score = max(0.0, min(1.0, 1.0 - penalty / Double(wordCount)))

        return OrthoVerdict(expected: expectedClean, written: writtenClean,
                            score: score, mistakes: mistakes, segments: segments)
    }

    /// Découpe un mot substitué lettre par lettre : seules les lettres fautives
    /// s'affichent en rouge, le reste reste lisible. C'est ce détail qui rend la
    /// correction utilisable d'un coup d'œil.
    static func characterSegments(expected: String,
                                  written: String) -> [OrthoVerdict.DiffSegment] {
        let e = Array(expected), w = Array(written)
        if e.isEmpty { return [.init(text: written, state: .extra)] }
        if w.isEmpty { return [.init(text: expected, state: .missing)] }

        // Alignement caractère par caractère (Levenshtein avec remontée).
        let n = e.count, m = w.count
        var d = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { d[i][0] = i }
        for j in 0...m { d[0][j] = j }
        for i in 1...n {
            for j in 1...m {
                let sub = d[i - 1][j - 1] + (sameLetter(e[i - 1], w[j - 1]) ? 0 : 1)
                d[i][j] = min(sub, min(d[i - 1][j] + 1, d[i][j - 1] + 1))
            }
        }

        var pieces: [(Character, OrthoVerdict.DiffSegment.State)] = []
        var i = n, j = m
        while i > 0 || j > 0 {
            if i > 0, j > 0,
               d[i][j] == d[i - 1][j - 1] + (sameLetter(e[i - 1], w[j - 1]) ? 0 : 1) {
                pieces.append((e[i - 1], sameLetter(e[i - 1], w[j - 1]) ? .correct : .wrong))
                i -= 1; j -= 1
            } else if i > 0, d[i][j] == d[i - 1][j] + 1 {
                pieces.append((e[i - 1], .missing)); i -= 1
            } else if j > 0 {
                pieces.append((w[j - 1], .extra)); j -= 1
            } else { break }
        }
        pieces.reverse()

        // Regrouper les caractères consécutifs de même état.
        var out: [OrthoVerdict.DiffSegment] = []
        var buffer = ""
        var state: OrthoVerdict.DiffSegment.State? = nil
        for (ch, st) in pieces {
            if st == state { buffer.append(ch) }
            else {
                if let s = state, !buffer.isEmpty { out.append(.init(text: buffer, state: s)) }
                buffer = String(ch); state = st
            }
        }
        if let s = state, !buffer.isEmpty { out.append(.init(text: buffer, state: s)) }
        return out
    }

    private static func sameLetter(_ a: Character, _ b: Character) -> Bool { a == b }

    // =========================================================================
    // MARK: - Analyse d'un mot isolé
    // =========================================================================

    /// Vrai si la saisie est exactement la forme attendue (typographie mise à part).
    static func isExactlyCorrect(expected: String, written: String) -> Bool {
        normalizeTypography(expected) == normalizeTypography(written)
    }

    /// Tolérance « saisie mobile » : accepte la casse initiale et la ponctuation
    /// finale, mais **jamais** un accent manquant — ce serait vider l'exercice
    /// de son objet.
    static func isAcceptable(expected: String, written: String) -> Bool {
        let e = normalizeTypography(expected)
            .trimmingCharacters(in: CharacterSet(charactersIn: " .!?"))
        let w = normalizeTypography(written)
            .trimmingCharacters(in: CharacterSet(charactersIn: " .!?"))
        return e.lowercased() == w.lowercased()
    }

    /// Les lettres muettes finales d'un mot — pour les afficher en gris clair.
    static func silentTail(_ word: String) -> String {
        let clean = word.lowercased().filter { $0.isLetter }
        guard clean.count > 2 else { return "" }
        let spoken = FrenchPhonology.soundKey(clean)
        guard !spoken.isEmpty else { return "" }
        var tail = ""
        var candidate = clean
        // On retire les lettres finales tant que le son ne change pas.
        while candidate.count > 1 {
            let shorter = String(candidate.dropLast())
            guard FrenchPhonology.soundKey(shorter) == spoken else { break }
            tail = String(candidate.suffix(1)) + tail
            candidate = shorter
        }
        return tail
    }
}
