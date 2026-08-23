import Foundation

/// Épelle un mot français à voix haute.
///
/// Indispensable dans une app d'orthographe : quand un apprenant se trompe sur
/// « élève », entendre le mot ne l'aide plus — il faut lui **dire les lettres**,
/// accents compris, comme le ferait un professeur au tableau. « e accent aigu,
/// l, e accent grave, v, e ».
///
/// Produit une chaîne destinée à la synthèse vocale, avec des virgules pour
/// marquer les pauses entre lettres.
enum FrenchSpeller {

    /// Nom français de chaque lettre, tel qu'on le prononce en épelant.
    private static let letterNames: [Character: String] = [
        "a": "a",    "b": "bé",   "c": "cé",   "d": "dé",   "e": "e",
        "f": "effe", "g": "gé",   "h": "hache", "i": "i",   "j": "ji",
        "k": "ka",   "l": "elle", "m": "emme", "n": "enne", "o": "o",
        "p": "pé",   "q": "ku",   "r": "erre", "s": "esse", "t": "té",
        "u": "u",    "v": "vé",   "w": "double vé", "x": "ixe",
        "y": "i grec", "z": "zède"
    ]

    /// Lettres accentuées : la lettre, puis le nom de son signe.
    private static let accentedNames: [Character: String] = [
        "é": "e accent aigu",
        "è": "e accent grave",
        "ê": "e accent circonflexe",
        "ë": "e tréma",
        "à": "a accent grave",
        "â": "a accent circonflexe",
        "î": "i accent circonflexe",
        "ï": "i tréma",
        "ô": "o accent circonflexe",
        "ù": "u accent grave",
        "û": "u accent circonflexe",
        "ü": "u tréma",
        "ÿ": "i grec tréma",
        "ç": "cé cédille",
        "œ": "e dans l'o",
        "æ": "e dans l'a"
    ]

    private static let punctuationNames: [Character: String] = [
        "'": "apostrophe",
        "-": "trait d'union",
        " ": "espace",
        ",": "virgule",
        ".": "point",
        ";": "point-virgule",
        ":": "deux-points",
        "!": "point d'exclamation",
        "?": "point d'interrogation"
    ]

    /// Épelle un mot. Les consonnes doubles sont annoncées comme telles —
    /// « deux p » — parce que c'est ainsi qu'on les retient, et parce que la
    /// consonne double est la faute la plus fréquente d'un locuteur roumain.
    static func spell(_ word: String) -> String {
        let normalized = word.replacingOccurrences(of: "\u{2019}", with: "'")
        let characters = Array(normalized)
        var parts: [String] = []
        var index = 0

        while index < characters.count {
            let ch = characters[index]
            let lower = Character(ch.lowercased())

            // Majuscule annoncée : dans une dictée, elle fait partie de la réponse.
            let isCapital = ch.isUppercase

            // Consonne doublée : on l'annonce en une fois.
            if index + 1 < characters.count,
               Character(characters[index + 1].lowercased()) == lower,
               let name = letterNames[lower],
               !"aeiouy".contains(lower) {
                parts.append("deux \(name)")
                index += 2
                continue
            }

            if let accented = accentedNames[lower] {
                parts.append(isCapital ? "majuscule \(accented)" : accented)
            } else if let name = letterNames[lower] {
                parts.append(isCapital ? "\(name) majuscule" : name)
            } else if let punctuation = punctuationNames[ch] {
                parts.append(punctuation)
            } else if ch.isNumber {
                parts.append(String(ch))
            }
            index += 1
        }

        // Les virgules créent les pauses entre lettres ; le point final marque
        // la fin, sans quoi la synthèse enchaîne sur une intonation suspendue.
        return parts.isEmpty ? "" : parts.joined(separator: ", ") + "."
    }

    /// Épelle une phrase entière, mot par mot, en annonçant les espaces.
    static func spellSentence(_ sentence: String) -> String {
        let words = sentence.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return "" }
        return words.map { spell($0) }.joined(separator: " espace, ")
    }

    /// Découpe un mot en syllabes pour une lecture scandée : « fe - nê - tre ».
    /// Chaque syllabe est séparée par une virgule, ce que la synthèse rend par
    /// une courte pause.
    static func syllabified(_ word: String) -> String {
        let syllables = FrenchPhonology.syllabify(word)
        return syllables.isEmpty ? word : syllables.joined(separator: ", ")
    }
}
