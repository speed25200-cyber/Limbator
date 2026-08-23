import Foundation

/// Phonologie du français, écrite à la main.
///
/// Objectif : décider si deux graphies **sonnent pareil**. C'est la question
/// centrale de l'orthographe française — « a » et « à », « ces » et « ses »,
/// « parlé » et « parler » ne se distinguent que par l'écrit. Sans cette
/// réponse, une correction ne peut pas dire à l'apprenant s'il a fait une
/// faute de son (il a mal entendu) ou une faute de règle (il a mal choisi).
///
/// Ce n'est pas une transcription API complète : c'est une **clé de son**,
/// volontairement grossière, conçue pour que les homophones se rencontrent.
/// Deux mots qui donnent la même clé se prononcent (à peu près) pareil.
///
/// Alphabet interne (un caractère = un phonème) :
///   voyelles orales   a e i o u(y) U(ou) E(eu/œ)
///   voyelles nasales  A(ɑ̃) O(ɔ̃) I(ɛ̃)
///   semi-voyelles     j w H(ɥ)
///   consonnes         p b t d k g f v s z S(ʃ) Z(ʒ) m n N(ɲ) l R(ʁ)
enum FrenchPhonology {

    // =========================================================================
    // MARK: - Jeux de caractères
    // =========================================================================

    static let vowelLetters: Set<Character> = [
        "a", "e", "i", "o", "u", "y",
        "á", "à", "â", "ä", "é", "è", "ê", "ë",
        "í", "î", "ï", "ó", "ô", "ö", "ú", "ù", "û", "ü", "ÿ"
    ]

    static let accentedVowels: Set<Character> = [
        "á", "à", "â", "ä", "é", "è", "ê", "ë",
        "í", "î", "ï", "ó", "ô", "ö", "ú", "ù", "û", "ü", "ÿ"
    ]

    /// Les mots français commençant par un **h aspiré** : pas d'élision
    /// (« le héros », jamais « l'héros »), pas de liaison.
    /// Liste des cas réellement fréquents ; ailleurs le h est muet.
    static let aspirateH: Set<String> = [
        "hache", "hachis", "haie", "haine", "hall", "halle", "halte", "hamac",
        "hamburger", "hameau", "hamster", "hanche", "handicap", "hangar",
        "hanter", "happer", "harceler", "hardi", "hareng", "hargne", "haricot",
        "harpe", "hasard", "hâte", "hausse", "haut", "hauteur", "havre",
        "hennir", "hérisson", "hernie", "héros", "hêtre", "heurter", "hibou",
        "hiérarchie", "hip", "hisser", "hobby", "hocher", "hockey", "hollande",
        "homard", "hongrois", "honte", "hoquet", "horde", "hors", "hotte",
        "houle", "housse", "hublot", "huche", "huer", "huit", "hurler", "hutte"
    ]

    /// `-ill-` prononcé /il/ et non /j/ (l'exception qui piège tout le monde).
    static let illAsL: Set<String> = [
        "ville", "villes", "village", "villages", "villageois", "villa", "villas",
        "mille", "milles", "million", "millions", "milliard", "milliards",
        "millier", "milliers", "milligramme", "millimètre",
        "tranquille", "tranquilles", "tranquillement", "tranquillité",
        "distiller", "osciller", "bacille", "pupille", "codicille", "imbécile"
    ]

    /// `ch` prononcé /k/ (mots d'origine grecque, pour l'essentiel).
    static let chAsK: [String] = [
        "chœur", "choeur", "chorale", "choral", "chore", "chorégraph",
        "chrom", "chron", "chlor", "christ", "chaos", "chaotique",
        "cholest", "chiromanc", "chrysanth", "écho", "orchestr", "orchid",
        "techn", "psych", "archéo", "archa", "archétype", "archange",
        "trachée", "eucharist", "varech", "krach", "lichen"
    ]

    /// Consonne finale exceptionnellement **prononcée** alors que la règle
    /// générale la rendrait muette (et inversement pour `-l` et `-r`).
    static let finalRPronounced: Set<String> = [
        "hier", "hiver", "mer", "cher", "chère", "fer", "ver", "amer", "fier",
        "cancer", "enfer", "super", "hamster", "revolver", "leader", "cuiller",
        "mouchoir", "soir", "noir", "pour", "sur", "car", "par", "or", "mur"
    ]

    static let finalLSilent: Set<String> = [
        "gentil", "outil", "fusil", "sourcil", "persil", "chenil", "nombril",
        "cul", "soûl", "saoul"
    ]

    static let finalFSilent: Set<String> = ["clef", "cerf", "nerf", "chef-d'œuvre"]

    /// Repli des diacritiques qui ne changent pas le son : « à » se lit comme
    /// « a », « ô » comme « o ». On les replie AVANT la lecture pour que les
    /// digrammes se reconnaissent : sans cela « où » ne serait pas vu comme
    /// « ou », ni « goût » comme « gout ».
    ///
    /// Ne sont PAS repliés : é, è, ê (le « es » final se prononce derrière un
    /// accent : « après », « très ») ni les trémas ë, ï, ü, ÿ — dont le rôle
    /// est justement de **casser** un digramme : « naïf » n'est pas « naif ».
    static let foldable: [Character: Character] = [
        "à": "a", "á": "a", "â": "a", "ä": "a",
        "í": "i", "î": "i",
        "ó": "o", "ô": "o", "ö": "o",
        "ú": "u", "ù": "u", "û": "u"
    ]

    /// Consonnes finales muettes. Un mot qui ne se termine plus que par elles
    /// s'arrête là : « temps » se lit /tɑ̃/, pas /tɑ̃p/.
    static let silentTailLetters: Set<Character> = ["s", "t", "d", "z", "x", "p", "g"]

    /// Les mots dont la lecture ne suit aucune règle. Toute langue en a ; le
    /// français les a placés, comme par malice, parmi ses mots les plus
    /// fréquents. Les lister vaut mieux que de tordre les règles pour eux.
    static let irregularReadings: [String: String] = [
        "est": "e", "aient": "e", "aie": "e", "aies": "e",
        "eu": "u", "eue": "u", "eus": "u", "eut": "u",
        "sept": "set", "huit": "Hit", "fils": "fis", "femme": "fam",
        "monsieur": "mesjE", "messieurs": "mesjE",
        "second": "segO", "seconde": "segOd",
        "automne": "oton", "oignon": "oNO", "pays": "pei",
        "aujourdhui": "oZuRdHi", "aout": "u", "plus": "plu",
        "oeufs": "E", "boeufs": "bE", "ouest": "west"
    ]

    /// Terminaisons de l'imparfait et du conditionnel : « -aient » se lit
    /// exactement comme « -ai ». On réécrit la finale plutôt que d'ajouter un
    /// cas particulier dans la boucle.
    static let suffixRewrites: [(String, String)] = [
        ("aient", "ai"), ("oient", "oi"), ("uient", "ui")
    ]

    /// Terminaisons verbales homophones de l'infinitif en `-er` : la source
    /// numéro un des fautes d'orthographe françaises.
    static let verbEndingGroups: [[String]] = [
        ["er", "é", "ez", "ée", "és", "ées", "ai", "aient", "ait", "ais", "aie", "aies", "aient"],
        ["ir", "i", "ie", "is", "it", "ies", "its"],
        ["u", "ue", "us", "ues", "ut"]
    ]

    // =========================================================================
    // MARK: - Élision / liaison
    // =========================================================================

    /// Le mot commence-t-il par un h aspiré (donc : pas d'élision) ?
    static func startsWithAspirateH(_ word: String) -> Bool {
        let w = word.lowercased().trimmingCharacters(in: .whitespaces)
        guard w.hasPrefix("h") else { return false }
        if aspirateH.contains(w) { return true }
        // Un mot dérivé hérite du h de sa base : « hautement » suit « haut ».
        return aspirateH.contains { w.hasPrefix($0) && $0.count >= 4 }
    }

    /// Le mot exige-t-il l'élision de l'article (« l'ami », « l'heure ») ?
    static func requiresElision(_ word: String) -> Bool {
        guard let first = word.lowercased().first else { return false }
        if first == "h" { return !startsWithAspirateH(word) }
        return vowelLetters.contains(first)
    }

    // =========================================================================
    // MARK: - Accents
    // =========================================================================

    /// Retire tous les diacritiques : « élève » -> « eleve », « ça » -> « ca ».
    static func stripAccents(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive], locale: Locale(identifier: "fr_FR"))
    }

    /// Le mot porte-t-il au moins un diacritique ?
    static func hasDiacritics(_ s: String) -> Bool {
        s.lowercased().contains { accentedVowels.contains($0) || $0 == "ç" }
    }

    /// Les diacritiques du mot, dans l'ordre, sous forme de paires
    /// (position dans la version sans accent, caractère accentué).
    static func diacriticProfile(_ s: String) -> [(index: Int, mark: Character)] {
        var out: [(Int, Character)] = []
        for (i, ch) in s.lowercased().enumerated() {
            if accentedVowels.contains(ch) || ch == "ç" { out.append((i, ch)) }
        }
        return out
    }

    /// Nom lisible d'un diacritique, pour les explications (source roumaine).
    static func accentName(_ ch: Character) -> String {
        switch ch {
        case "é": return "accent ascuțit (é)"
        case "è": return "accent grav (è)"
        case "ê", "â", "î", "ô", "û": return "accent circumflex"
        case "ë", "ï", "ü", "ÿ": return "tremă"
        case "à", "ù": return "accent grav"
        case "ç": return "sedilă (ç)"
        default: return "accent"
        }
    }

    // =========================================================================
    // MARK: - Clé de son
    // =========================================================================

    /// Clé phonétique principale d'un mot.
    static func soundKey(_ word: String) -> String {
        keys(for: word).first ?? ""
    }

    /// Toutes les lectures plausibles d'un mot.
    ///
    /// Le français réserve un cas qu'aucune règle ne tranche sans connaître la
    /// nature du mot : la finale `-ent`. Elle est nasale dans « souvent » et
    /// muette dans « ils parlent ». Plutôt que de deviner, on renvoie les deux
    /// lectures : deux mots sont jugés homophones s'ils partagent **une** clé.
    static func keys(for word: String) -> [String] {
        let cleaned = preprocess(word)
        guard !cleaned.isEmpty else { return [""] }

        // Un mot composé se lit morceau par morceau.
        if cleaned.contains("-") {
            let parts = cleaned.split(separator: "-").map(String.init)
            let joined = parts.map { transcribe(Array($0), silentEnt: false) }.joined()
            return [joined]
        }

        let chars = Array(cleaned)
        let primary = transcribe(chars, silentEnt: false)
        if cleaned.hasSuffix("ent") && cleaned.count > 4 {
            let alt = transcribe(chars, silentEnt: true)
            return alt == primary ? [primary] : [primary, alt]
        }
        return [primary]
    }

    /// Deux graphies se prononcent-elles pareil ?
    static func areHomophones(_ a: String, _ b: String) -> Bool {
        let ka = Set(keys(for: a)), kb = Set(keys(for: b))
        guard !ka.isEmpty, !kb.isEmpty else { return false }
        // Une clé vide ne prouve rien : deux mots vides ne sont pas homophones.
        if ka == [""] || kb == [""] { return a == b }
        return !ka.isDisjoint(with: kb)
    }

    // =========================================================================
    // MARK: - Transcription (moteur)
    // =========================================================================

    private static func preprocess(_ word: String) -> String {
        var s = word.lowercased()
        s = s.replacingOccurrences(of: "\u{2019}", with: "'")   // apostrophe typographique
        s = s.replacingOccurrences(of: "œ", with: "oe")
        s = s.replacingOccurrences(of: "æ", with: "ae")
        // L'élision soude les deux mots à l'oral : « l'ami » se lit « lami ».
        s = s.replacingOccurrences(of: "'", with: "")
        s = String(s.map { foldable[$0] ?? $0 })
        s = s.filter { $0.isLetter || $0 == "-" }
        for (suffix, replacement) in suffixRewrites where s.hasSuffix(suffix) && s.count > suffix.count {
            s = String(s.dropLast(suffix.count)) + replacement
            break
        }
        return s
    }

    /// Le cœur : parcours de gauche à droite, règle la plus longue d'abord.
    private static func transcribe(_ chars: [Character], silentEnt: Bool) -> String {
        let n = chars.count
        guard n > 0 else { return "" }
        let word = String(chars)
        if !silentEnt, let known = irregularReadings[word] { return known }
        var out = ""
        var i = 0

        /// Le caractère en position `k`, ou nil hors bornes.
        func at(_ k: Int) -> Character? { (k >= 0 && k < n) ? chars[k] : nil }
        func isVowel(_ k: Int) -> Bool { at(k).map { vowelLetters.contains($0) } ?? false }
        func matches(_ s: String, at k: Int) -> Bool {
            let t = Array(s)
            guard k + t.count <= n else { return false }
            for (o, c) in t.enumerated() where chars[k + o] != c { return false }
            return true
        }
        /// Position de fin de mot atteinte après avoir consommé `len` caractères ?
        func endsAt(_ k: Int) -> Bool { k >= n }

        while i < n {
            let c = chars[i]
            let last = i == n - 1

            // ---- Finale « -ent » muette (3e personne du pluriel) -------------
            if silentEnt, i == n - 3, matches("ent", at: i) { break }

            // ---- Nasales ----------------------------------------------------
            // Une voyelle + n/m se nasalise, sauf si une voyelle ou la même
            // nasale suit : « année » n'est pas nasal, « an » l'est.
            if let nasal = nasalAt(i, chars: chars, n: n) {
                out += nasal.sound
                i += nasal.length
                continue
            }

            // ---- Digrammes et trigrammes vocaliques -------------------------
            if matches("eau", at: i) { out += "o"; i += 3; continue }
            if matches("aux", at: i), endsAt(i + 3) { out += "o"; i += 3; continue }
            if matches("eaux", at: i) { out += "o"; i += 4; continue }
            if matches("au", at: i)  { out += "o"; i += 2; continue }
            if matches("oeu", at: i) { out += "E"; i += 3; continue }
            if matches("eu", at: i)  { out += "E"; i += 2; continue }
            if matches("oy", at: i), isVowel(i + 2) { out += "waj"; i += 2; continue }
            if matches("oi", at: i)  { out += "wa"; i += 2; continue }
            if matches("ou", at: i) {
                // « ou » + voyelle donne la semi-voyelle /w/ : « oui », « jouer ».
                if isVowel(i + 2) { out += "w" } else { out += "U" }
                i += 2; continue
            }
            if matches("aî", at: i) || matches("ai", at: i) || matches("ei", at: i) {
                out += "e"; i += 2; continue
            }
            if matches("ay", at: i) {
                if isVowel(i + 2) { out += "ej"; i += 2; continue }
                out += "e"; i += 2; continue
            }

            // ---- Digrammes consonantiques ----------------------------------
            if matches("ch", at: i) {
                out += chIsK(word: word, at: i) ? "k" : "S"
                i += 2; continue
            }
            if matches("ph", at: i) { out += "f"; i += 2; continue }
            if matches("gn", at: i) { out += "N"; i += 2; continue }
            if matches("th", at: i) { out += "t"; i += 2; continue }
            if matches("qu", at: i) { out += "k"; i += 2; continue }
            if matches("gu", at: i), let nx = at(i + 2), "eiéèêy".contains(nx) {
                out += "g"; i += 2; continue
            }
            if matches("ill", at: i) {
                if illAsL.contains(word) { out += "il" } else { out += "j" }
                i += 3; continue
            }
            if matches("sc", at: i), let nx = at(i + 2), "eiyéèê".contains(nx) {
                out += "s"; i += 2; continue
            }
            if matches("tion", at: i) { out += "sjO"; i += 4; continue }
            if matches("ss", at: i) { out += "s"; i += 2; continue }

            // ---- Finales verbales / grammaticales ---------------------------
            if i == n - 2 {
                if matches("er", at: i) {
                    // « manger » /e/ mais « hiver » /R/ : liste d'exceptions.
                    out += finalRPronounced.contains(word) ? "eR" : "e"
                    i += 2; continue
                }
                if matches("ez", at: i) { out += "e"; i += 2; continue }
                if matches("et", at: i) { out += "e"; i += 2; continue }
                if matches("es", at: i) {
                    // « -es » ne se prononce que dans les monosyllabes
                    // grammaticaux — ceux dont le radical n'a pas de voyelle :
                    // « les », « des », « mes ». Ailleurs c'est une marque
                    // de pluriel muette : « portes », « aides ».
                    let stemHasVowel = chars[0..<i].contains { vowelLetters.contains($0) }
                    out += stemHasVowel ? "" : "e"
                    i += 2; continue
                }
            }

            // ---- Queue de consonnes muettes ---------------------------------
            // Tout ce qui reste n'est plus qu'un groupe de finales muettes :
            // « temps » -> /tɑ̃/, « est » -> /ɛ/, « leurs » -> /lœʁ/.
            // La présence d'un « e » interdit la coupe : dans « adresse » le
            // « ss » se prononce, seul le « e » final se tait.
            if i > 0, !out.isEmpty,
               chars[i..<n].allSatisfy({ silentTailLetters.contains($0) }) {
                break
            }

            // ---- Consonne double : un seul son ------------------------------
            if let nx = at(i + 1), nx == c, !vowelLetters.contains(c) {
                // « nn », « mm », « tt »… se prononcent simples.
                out += consonantSound(c, chars: chars, i: i, n: n)
                i += 2; continue
            }

            // ---- Lettres finales muettes ------------------------------------
            if last, isSilentFinal(c, word: word, chars: chars, n: n) { break }

            // ---- Lettres simples --------------------------------------------
            if vowelLetters.contains(c) {
                out += vowelSound(c, chars: chars, i: i, n: n, out: out)
            } else {
                out += consonantSound(c, chars: chars, i: i, n: n)
            }
            i += 1
        }

        return out
    }

    // MARK: Nasales

    private struct Nasal { let sound: String; let length: Int }

    private static func nasalAt(_ i: Int, chars: [Character], n: Int) -> Nasal? {
        func at(_ k: Int) -> Character? { (k >= 0 && k < n) ? chars[k] : nil }
        func has(_ s: String, _ k: Int) -> Bool {
            let t = Array(s)
            guard k + t.count <= n else { return false }
            for (o, c) in t.enumerated() where chars[k + o] != c { return false }
            return true
        }
        /// Le groupe se nasalise-t-il ? Non si une voyelle ou la même nasale suit.
        func nasalises(after len: Int) -> Bool {
            guard let next = at(i + len) else { return true }   // fin de mot : nasal
            if vowelLetters.contains(next) { return false }
            if next == "n" || next == "m" { return false }      // « année », « immense »
            return true
        }

        // Trigrammes d'abord (les plus spécifiques).
        for (pat, snd) in [("oin", "wI"), ("ain", "I"), ("aim", "I"),
                           ("ein", "I"), ("eim", "I"), ("ien", "jI"),
                           ("yen", "jI"), ("éen", "eI")] {
            if has(pat, i), nasalises(after: 3) { return Nasal(sound: snd, length: 3) }
        }
        for (pat, snd) in [("an", "A"), ("am", "A"), ("en", "A"), ("em", "A"),
                           ("on", "O"), ("om", "O"), ("in", "I"), ("im", "I"),
                           ("un", "I"), ("um", "I"), ("yn", "I"), ("ym", "I")] {
            if has(pat, i), nasalises(after: 2) { return Nasal(sound: snd, length: 2) }
        }
        return nil
    }

    // MARK: Sons élémentaires

    private static func vowelSound(_ c: Character, chars: [Character],
                                   i: Int, n: Int, out: String) -> String {
        switch c {
        case "a", "à", "â", "á", "ä": return "a"
        case "e":
            // « e » final déjà traité ; ailleurs on fusionne /ə/, /e/ et /ɛ/ :
            // la distinction n'oppose aucune paire orthographique utile ici.
            return "e"
        case "é", "è", "ê", "ë": return "e"
        case "ï": return "i"
        case "ü": return "u"
        case "ÿ": return "i"
        case "i", "î", "í":
            // « i » + voyelle donne la semi-voyelle /j/ : « pied », « lion ».
            if i + 1 < n, vowelLetters.contains(chars[i + 1]) { return "j" }
            return "i"
        case "o", "ô", "ó", "ö": return "o"
        case "u", "û", "ù", "ú":
            if i + 1 < n, vowelLetters.contains(chars[i + 1]) { return "H" }
            return "u"
        case "y":
            if i + 1 < n, vowelLetters.contains(chars[i + 1]) { return "j" }
            return "i"
        default: return String(c)
        }
    }

    private static func consonantSound(_ c: Character, chars: [Character],
                                       i: Int, n: Int) -> String {
        func next() -> Character? { i + 1 < n ? chars[i + 1] : nil }
        func prev() -> Character? { i - 1 >= 0 ? chars[i - 1] : nil }

        switch c {
        case "c":
            if let nx = next(), "eiyéèêë".contains(nx) { return "s" }
            return "k"
        case "ç": return "s"
        case "g":
            if let nx = next(), "eiyéèê".contains(nx) { return "Z" }
            return "g"
        case "s":
            // « s » entre deux voyelles se sonorise : « rose » /z/, « poisson » /s/.
            if let p = prev(), let nx = next(),
               vowelLetters.contains(p), vowelLetters.contains(nx) { return "z" }
            return "s"
        case "x":
            if i == 0 { return "gz" }
            return "ks"
        case "h": return ""
        case "q": return "k"
        case "j": return "Z"
        case "r": return "R"
        case "w": return "v"
        case "y": return "j"
        default: return String(c)
        }
    }

    // MARK: Finales muettes

    private static func isSilentFinal(_ c: Character, word: String,
                                      chars: [Character], n: Int) -> Bool {
        switch c {
        case "e": return true                       // « table », « rue »
        case "s", "t", "d", "z", "x", "p": return true
        case "g": return true                       // « long », « sang »
        case "l": return finalLSilent.contains(word)
        case "f": return finalFSilent.contains(word)
        case "r": return false                      // « -er » traité en amont
        case "c":
            // « blanc », « franc » se taisent ; « sac », « avec » se prononcent.
            return n >= 2 && chars[n - 2] == "n"
        case "m", "n": return false                 // nasales traitées en amont
        default: return false
        }
    }

    // MARK: ch = /k/ ?

    private static func chIsK(word: String, at i: Int) -> Bool {
        // Les mots d'origine grecque gardent /k/. On teste sur le mot entier :
        // la position du « ch » n'est pas discriminante (« écho », « technique »).
        chAsK.contains { word.contains($0) }
    }

    // =========================================================================
    // MARK: - Syllabation (approchée)
    // =========================================================================

    /// Découpe approximative en syllabes, pour l'affichage et l'épellation.
    /// Règle appliquée : une consonne entre deux voyelles part avec la seconde ;
    /// deux consonnes se séparent, sauf groupe indissociable (br, cl, tr…).
    static func syllabify(_ word: String) -> [String] {
        let inseparable: Set<String> = [
            "bl", "br", "cl", "cr", "dr", "fl", "fr", "gl", "gr", "pl", "pr",
            "tr", "vr", "ch", "ph", "th", "gn"
        ]
        let chars = Array(word)
        guard chars.count > 3 else { return [word] }

        var syllables: [String] = []
        var current = ""
        var i = 0
        while i < chars.count {
            current.append(chars[i])
            let isV = vowelLetters.contains(Character(chars[i].lowercased()))
            if isV {
                // Regarder ce qui suit pour décider où couper.
                var j = i + 1
                var consonants = ""
                while j < chars.count,
                      !vowelLetters.contains(Character(chars[j].lowercased())) {
                    consonants.append(chars[j]); j += 1
                }
                if j >= chars.count {
                    current += consonants
                    i = j
                    break
                }
                if consonants.count == 1 {
                    // La consonne part avec la syllabe suivante.
                } else if consonants.count >= 2 {
                    let pair = String(consonants.prefix(2)).lowercased()
                    if inseparable.contains(pair) {
                        // Le groupe reste soudé et part avec la suite.
                    } else {
                        current.append(consonants.first ?? " ")
                        i += 1
                    }
                }
                syllables.append(current)
                current = ""
            }
            i += 1
        }
        if !current.isEmpty {
            if syllables.isEmpty { syllables.append(current) }
            else { syllables[syllables.count - 1] += current }
        }
        return syllables.filter { !$0.isEmpty }
    }
}
