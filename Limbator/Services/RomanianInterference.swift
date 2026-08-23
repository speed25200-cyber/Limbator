import Foundation

/// Les fautes qu'un roumanophone fait **parce qu'il parle roumain**.
///
/// Le roumain et le français sont deux langues romanes : neuf mots savants sur
/// dix se ressemblent. C'est un avantage énorme — et un piège permanent, parce
/// que la ressemblance s'arrête à l'orthographe. « atenție » donne
/// « attention » avec deux t, « adresă » donne « adresse » avec deux s,
/// « profesor » donne « professeur » avec deux s et -eur.
///
/// Cette table permet à la correction de dire, au lieu de « faute de frappe » :
/// « tu as écrit le mot à la roumaine ». C'est la remarque qui fait progresser.
enum RomanianInterference {

    /// Un piège : la forme française correcte, la graphie « à la roumaine »
    /// qu'on écrit spontanément, le mot roumain d'origine, et l'explication.
    struct Trap: Hashable, Identifiable {
        var id: String { french }
        /// La forme française juste.
        let french: String
        /// Les graphies fautives observées (calques du roumain).
        let calques: [String]
        /// Le mot roumain qui induit en erreur.
        let romanian: String
        /// Ce qui change, expliqué en roumain.
        let note: String

        var localizedNote: String { ContentL10n.s(note) }
    }

    // =========================================================================
    // MARK: - Consonnes doubles que le roumain ignore
    // =========================================================================

    static let doubleConsonantTraps: [Trap] = [
        .init(french: "attention",     calques: ["atention", "atenttion"],   romanian: "atenție",     note: "Franceza dublează t: at-tention."),
        .init(french: "adresse",       calques: ["adrese", "adress", "adrèsse"], romanian: "adresă",  note: "Doi de s: adre-sse. Cu un singur s s-ar citi /z/."),
        .init(french: "appartement",   calques: ["apartement", "appartament"], romanian: "apartament", note: "Doi de p, iar finalul e -ement, nu -ament."),
        .init(french: "professeur",    calques: ["profeseur", "professor", "profesor"], romanian: "profesor", note: "Doi de s și terminația -eur, nu -or."),
        .init(french: "communication", calques: ["comunication", "communicasion"], romanian: "comunicare", note: "Doi de m: com-munication."),
        .init(french: "recommander",   calques: ["recomander", "récommander"], romanian: "a recomanda", note: "Doi de m: recom-mander."),
        .init(french: "affaire",       calques: ["afaire", "afferre"],        romanian: "afacere",     note: "Doi de f: af-faire."),
        .init(french: "développement", calques: ["devellopement", "developement", "dévelopement"], romanian: "dezvoltare", note: "Un singur l, doi de p, și é la început."),
        .init(french: "littérature",   calques: ["literature", "litterature"], romanian: "literatură", note: "Doi de t și é: lit-térature."),
        .init(french: "personnel",     calques: ["personel", "personnell"],   romanian: "personal",    note: "Doi de n: person-nel."),
        .init(french: "traditionnel",  calques: ["traditionel"],              romanian: "tradițional", note: "Doi de n: tradition-nel."),
        .init(french: "rationnel",     calques: ["rationel"],                 romanian: "rațional",    note: "Doi de n: ration-nel."),
        .init(french: "immédiat",      calques: ["imédiat", "imediat"],       romanian: "imediat",     note: "Doi de m: im-médiat."),
        .init(french: "intelligent",   calques: ["inteligent"],               romanian: "inteligent",  note: "Doi de l: intel-ligent."),
        .init(french: "illustrer",     calques: ["ilustrer"],                 romanian: "a ilustra",   note: "Doi de l: il-lustrer."),
        .init(french: "apparent",      calques: ["aparent"],                  romanian: "aparent",     note: "Doi de p: ap-parent."),
        .init(french: "agressif",      calques: ["agresif"],                  romanian: "agresiv",     note: "Doi de s și final -if, nu -iv."),
        .init(french: "collègue",      calques: ["colègue", "collegue"],      romanian: "coleg",       note: "Doi de l și accent grav pe è."),
        .init(french: "million",       calques: ["milion"],                   romanian: "milion",      note: "Doi de l: mil-lion."),
        .init(french: "abonnement",    calques: ["abonement"],                romanian: "abonament",   note: "Doi de n, și -ement la final."),
        .init(french: "occasion",      calques: ["ocasion", "ocassion"],      romanian: "ocazie",      note: "Doi de c: oc-casion."),
        .init(french: "occuper",       calques: ["ocuper"],                   romanian: "a ocupa",     note: "Doi de c: oc-cuper."),
        .init(french: "accorder",      calques: ["acorder"],                  romanian: "a acorda",    note: "Doi de c: ac-corder."),
        .init(french: "supporter",     calques: ["suporter"],                 romanian: "a suporta",   note: "Doi de p: sup-porter."),
        .init(french: "appeler",       calques: ["apeler", "appelder"],       romanian: "a apela",     note: "Doi de p la infinitiv, dar «j'appelle» are și doi de l."),
        .init(french: "appliquer",     calques: ["apliquer"],                 romanian: "a aplica",    note: "Doi de p: ap-pliquer."),
        .init(french: "abandonner",    calques: ["abandoner"],                romanian: "a abandona",  note: "Doi de n la infinitiv: abandon-ner."),
        .init(french: "nécessaire",    calques: ["necesaire", "nécesaire"],   romanian: "necesar",     note: "é la început, doi de s: né-ces-saire."),
        .init(french: "intéressant",   calques: ["interesant", "intéresant"], romanian: "interesant",  note: "é și doi de s: in-té-res-sant."),
        .init(french: "apparaître",    calques: ["aparaitre", "apparaitre"],  romanian: "a apărea",    note: "Doi de p și circumflex pe î."),
        .init(french: "difficile",     calques: ["dificile"],                 romanian: "dificil",     note: "Doi de f: dif-ficile.")
    ]

    // =========================================================================
    // MARK: - Le circonflexe qui remplace un S resté en roumain
    // =========================================================================

    /// La plus belle passerelle entre les deux langues : là où le roumain a
    /// gardé le S du latin, le français l'a perdu et l'a remplacé par un
    /// accent circonflexe. « fereastră » -> « fenêtre », « spital » -> « hôpital ».
    /// Une fois ce pont vu, l'apprenant roumain ne l'oublie plus.
    static let circumflexBridges: [Trap] = [
        .init(french: "fenêtre",  calques: ["fenetre", "fenestre"],   romanian: "fereastră", note: "S-ul din «fereastră» a devenit accentul circumflex: fenêtre."),
        .init(french: "hôpital",  calques: ["hopital", "hospital"],   romanian: "spital",    note: "S-ul din «spital» a devenit ô: hôpital."),
        .init(french: "île",      calques: ["ile", "isle"],           romanian: "insulă",    note: "S-ul din «insulă» a devenit î: île."),
        .init(french: "côte",     calques: ["cote", "coste"],         romanian: "coastă",    note: "S-ul din «coastă» a devenit ô: côte."),
        .init(french: "pâte",     calques: ["pate", "paste"],         romanian: "pastă",     note: "S-ul din «pastă» a devenit â: pâte."),
        .init(french: "bête",     calques: ["bete", "beste"],         romanian: "bestie",    note: "S-ul din «bestie» a devenit ê: bête."),
        .init(french: "château",  calques: ["chateau", "chasteau"],   romanian: "castel",    note: "S-ul latinesc (castellum/chastel) a devenit â: château."),
        .init(french: "forêt",    calques: ["foret", "forest"],       romanian: "pădure",    note: "Ca în engleză «forest»: S-ul a devenit ê."),
        .init(french: "goût",     calques: ["gout", "goust"],         romanian: "gust",      note: "S-ul din «gust» a devenit û: goût."),
        .init(french: "coûter",   calques: ["couter", "couster"],     romanian: "a costa",   note: "S-ul din «a costa» a devenit û: coûter."),
        .init(french: "croûte",   calques: ["croute"],                romanian: "crustă",    note: "S-ul din «crustă» a devenit û: croûte."),
        .init(french: "maître",   calques: ["maitre", "maistre"],     romanian: "maestru",   note: "Circumflex pe î: maître (lat. magister)."),
        .init(french: "fantôme",  calques: ["fantome"],               romanian: "fantomă",   note: "Circumflex pe ô: fantôme."),
        .init(french: "arrêt",    calques: ["aret", "arret"],         romanian: "oprire",    note: "Doi de r și circumflex pe ê: arrêt."),
        .init(french: "août",     calques: ["aout", "august"],        romanian: "august",    note: "S-ul din «august» a devenit û: août."),
        .init(french: "tête",     calques: ["tete", "teste"],         romanian: "test/testa", note: "Circumflex pe ê: tête (lat. testa).")
    ]

    // =========================================================================
    // MARK: - Lettres savantes que le roumain a simplifiées
    // =========================================================================

    static let learnedSpellingTraps: [Trap] = [
        .init(french: "pharmacie",   calques: ["farmacie"],      romanian: "farmacie",   note: "Franceza scrie ph acolo unde româna scrie f."),
        .init(french: "physique",    calques: ["fizique", "phisique"], romanian: "fizică", note: "ph + y: phy-sique."),
        .init(french: "théâtre",     calques: ["teatre", "theatre"], romanian: "teatru", note: "th, é și â: thé-â-tre. Trei semne într-un cuvânt scurt."),
        .init(french: "rythme",      calques: ["ritme", "rythm"], romanian: "ritm",      note: "y + th: ry-thme."),
        .init(french: "système",     calques: ["systeme", "sisteme"], romanian: "sistem", note: "y la început și è în mijloc: sys-tème."),
        .init(french: "symbole",     calques: ["simbole"],       romanian: "simbol",     note: "y, nu i: sym-bole."),
        .init(french: "analyser",    calques: ["analiser"],      romanian: "a analiza",  note: "y, nu i: ana-ly-ser."),
        .init(french: "psychologie", calques: ["psihologie", "psycologie"], romanian: "psihologie", note: "psy + ch: româna scrie «psih», franceza «psych»."),
        .init(french: "technique",   calques: ["tehnique", "technic"], romanian: "tehnic", note: "ch acolo unde româna scrie h: tech-nique."),
        .init(french: "architecte",  calques: ["arhitecte"],     romanian: "arhitect",   note: "ch acolo unde româna scrie h: ar-chi-tecte."),
        .init(french: "orchestre",   calques: ["orhestre"],      romanian: "orchestră",  note: "ch citit /k/: or-chestre."),
        .init(french: "caractère",   calques: ["caractere", "caracter"], romanian: "caracter", note: "Accent grav pe è și -ère la final."),
        .init(french: "école",       calques: ["ecole", "școală"], romanian: "școală",   note: "É la început — vine din «schola», unde s-ul a dispărut."),
        .init(french: "étudiant",    calques: ["etudiant", "student"], romanian: "student", note: "É la început, iar «student» se spune «étudiant»."),
        .init(french: "état",        calques: ["etat", "stat"],  romanian: "stat",       note: "S-ul din «stat» a devenit é: état."),
        .init(french: "spécial",     calques: ["special"],       romanian: "special",    note: "Accent ascuțit pe é: spé-cial."),
        .init(french: "exemple",     calques: ["examplu", "exemplu"], romanian: "exemplu", note: "Se termină în -e, nu în -u: exemple."),
        .init(french: "auteur",      calques: ["autor"],         romanian: "autor",      note: "Terminația -eur, nu -or: au-teur."),
        .init(french: "acteur",      calques: ["actor"],         romanian: "actor",      note: "Terminația -eur, nu -or: ac-teur."),
        .init(french: "moteur",      calques: ["motor"],         romanian: "motor",      note: "Terminația -eur, nu -or: mo-teur."),
        .init(french: "docteur",     calques: ["doctor"],        romanian: "doctor",     note: "Terminația -eur, nu -or: doc-teur.")
    ]

    // =========================================================================
    // MARK: - Genres qui changent entre les deux langues
    // =========================================================================

    /// Le genre décide de l'accord — donc de l'orthographe. Ces mots ne portent
    /// pas le même genre en roumain et en français : chaque écart est une faute
    /// d'accord annoncée.
    struct GenderShift: Hashable, Identifiable {
        var id: String { french }
        let french: String
        /// "m" ou "f" en français.
        let frenchGender: String
        let romanian: String
        /// "m", "f" ou "n" (neutru) en roumain.
        let romanianGender: String
        /// Exemple d'accord correct en français.
        let example: String
    }

    static let genderShifts: [GenderShift] = [
        .init(french: "livre",   frenchGender: "m", romanian: "carte",   romanianGender: "f", example: "un livre ouvert"),
        .init(french: "problème", frenchGender: "m", romanian: "problemă", romanianGender: "f", example: "un problème difficile"),
        .init(french: "dent",    frenchGender: "f", romanian: "dinte",   romanianGender: "m", example: "une dent blanche"),
        .init(french: "sel",     frenchGender: "m", romanian: "sare",    romanianGender: "f", example: "le sel fin"),
        .init(french: "lait",    frenchGender: "m", romanian: "lapte",   romanianGender: "n", example: "le lait chaud"),
        .init(french: "sang",    frenchGender: "m", romanian: "sânge",   romanianGender: "n", example: "le sang rouge"),
        .init(french: "air",     frenchGender: "m", romanian: "aer",     romanianGender: "n", example: "l'air frais"),
        .init(french: "minute",  frenchGender: "f", romanian: "minut",   romanianGender: "n", example: "une minute entière"),
        .init(french: "seconde", frenchGender: "f", romanian: "secundă", romanianGender: "f", example: "une seconde de plus"),
        .init(french: "voyage",  frenchGender: "m", romanian: "călătorie", romanianGender: "f", example: "un beau voyage"),
        .init(french: "silence", frenchGender: "m", romanian: "liniște", romanianGender: "f", example: "un silence complet"),
        .init(french: "arbre",   frenchGender: "m", romanian: "copac",   romanianGender: "m", example: "un arbre haut"),
        .init(french: "fleur",   frenchGender: "f", romanian: "floare",  romanianGender: "f", example: "une fleur ouverte"),
        .init(french: "mer",     frenchGender: "f", romanian: "mare",    romanianGender: "f", example: "la mer calme"),
        .init(french: "montagne", frenchGender: "f", romanian: "munte",  romanianGender: "m", example: "une montagne haute"),
        .init(french: "pain",    frenchGender: "m", romanian: "pâine",   romanianGender: "f", example: "du pain frais"),
        .init(french: "eau",     frenchGender: "f", romanian: "apă",     romanianGender: "f", example: "de l'eau fraîche"),
        .init(french: "travail", frenchGender: "m", romanian: "muncă",   romanianGender: "f", example: "un travail sérieux")
    ]

    // =========================================================================
    // MARK: - Index
    // =========================================================================

    static var allTraps: [Trap] {
        doubleConsonantTraps + circumflexBridges + learnedSpellingTraps
    }

    /// Index calque -> piège. Construit une seule fois.
    private static let byCalque: [String: Trap] = {
        var map: [String: Trap] = [:]
        for trap in allTraps {
            for c in trap.calques { map[normalize(c)] = trap }
        }
        return map
    }()

    /// Index forme française -> piège.
    private static let byFrench: [String: Trap] = {
        var map: [String: Trap] = [:]
        for trap in allTraps { map[normalize(trap.french)] = trap }
        return map
    }()

    private static func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// La graphie fautive est-elle un calque connu du roumain, pour ce mot
    /// français attendu ? On exige que le piège corresponde **au mot attendu**,
    /// sinon on attribuerait à l'influence du roumain une faute quelconque.
    static func trap(expected: String, written: String) -> Trap? {
        let e = normalize(expected), w = normalize(written)
        guard e != w else { return nil }
        if let t = byCalque[w], normalize(t.french) == e { return t }
        // Certains calques ne sont pas listés mot pour mot : on accepte aussi
        // le cas « le mot attendu est un piège connu et l'apprenant a écrit une
        // forme sans les doubles consonnes / sans les accents ».
        if let t = byFrench[e] {
            let simplified = FrenchPhonology.stripAccents(collapseDoubles(e))
            if FrenchPhonology.stripAccents(collapseDoubles(w)) == simplified { return t }
        }
        return nil
    }

    /// Le piège attaché à un mot français, s'il existe (pour l'afficher en amont).
    static func trap(forFrench word: String) -> Trap? {
        byFrench[normalize(word)]
    }

    static func genderShift(forFrench word: String) -> GenderShift? {
        let w = normalize(word)
        return genderShifts.first { normalize($0.french) == w }
    }

    /// « appelle » -> « apele » : réduit toute consonne doublée.
    static func collapseDoubles(_ s: String) -> String {
        var out = ""
        var previous: Character? = nil
        for ch in s {
            if let p = previous, p == ch, !FrenchPhonology.vowelLetters.contains(ch) {
                continue
            }
            out.append(ch)
            previous = ch
        }
        return out
    }
}
