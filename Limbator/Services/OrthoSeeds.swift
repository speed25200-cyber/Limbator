import Foundation

/// Les familles d'homophones françaises, avec le **test** qui permet de trancher.
///
/// Un homophone ne se devine pas : il se teste. « a » ou « à » ? Remplace par
/// « avait » : si la phrase tient, c'est le verbe, donc « a ». C'est ce geste
/// mental — et non la mémorisation — que Limbator installe.
///
/// Contenu écrit en roumain (langue de l'apprenant visé) ; `ContentL10n` le
/// traduit vers le français ou l'anglais si l'utilisateur change de langue.
enum OrthoSeeds {

    // =========================================================================
    // MARK: - Familles d'homophones
    // =========================================================================

    static let homophoneSets: [HomophoneSet] = [
        HomophoneSet(id: "a-à", sound: "/a/", level: .a1, members: [
            .init(form: "a",  nature: "verbul «avoir», persoana a III-a singular",
                  test: "Înlocuiește cu «avait»: dacă merge, scrii «a».",
                  example: "Il a un chien.", gloss: "El are un câine."),
            .init(form: "à",  nature: "prepoziție (la, spre, în)",
                  test: "Cu «avait» fraza nu mai are sens: atunci scrii «à».",
                  example: "Il va à Paris.", gloss: "El merge la Paris.")
        ]),

        HomophoneSet(id: "ou-où", sound: "/u/", level: .a1, members: [
            .init(form: "ou", nature: "conjuncție (sau)",
                  test: "Înlocuiește cu «ou bien»: dacă merge, fără accent.",
                  example: "Café ou thé ?", gloss: "Cafea sau ceai?"),
            .init(form: "où", nature: "adverb de loc sau de timp (unde)",
                  test: "Arată un loc sau un moment — «ou bien» nu merge.",
                  example: "Où vas-tu ?", gloss: "Unde te duci?")
        ]),

        HomophoneSet(id: "et-est", sound: "/e/", level: .a1, members: [
            .init(form: "et",  nature: "conjuncție (și)",
                  test: "Înlocuiește cu «et puis».",
                  example: "Paul et Marie sont là.", gloss: "Paul și Marie sunt aici."),
            .init(form: "est", nature: "verbul «être», persoana a III-a singular",
                  test: "Înlocuiește cu «était».",
                  example: "Le café est chaud.", gloss: "Cafeaua este fierbinte.")
        ]),

        HomophoneSet(id: "son-sont", sound: "/sɔ̃/", level: .a1, members: [
            .init(form: "son",  nature: "adjectiv posesiv (al său)",
                  test: "La plural devine «ses»: «son livre» → «ses livres».",
                  example: "Il cherche son stylo.", gloss: "Își caută pixul."),
            .init(form: "sont", nature: "verbul «être», persoana a III-a plural",
                  test: "Înlocuiește cu «étaient».",
                  example: "Les enfants sont partis.", gloss: "Copiii au plecat.")
        ]),

        HomophoneSet(id: "on-ont", sound: "/ɔ̃/", level: .a1, members: [
            .init(form: "on",  nature: "pronume subiect (se, noi, cineva)",
                  test: "Înlocuiește cu «il».",
                  example: "On part demain.", gloss: "Plecăm mâine."),
            .init(form: "ont", nature: "verbul «avoir», persoana a III-a plural",
                  test: "Înlocuiește cu «avaient».",
                  example: "Ils ont faim.", gloss: "Le este foame.")
        ]),

        HomophoneSet(id: "ce-se", sound: "/sə/", level: .a2, members: [
            .init(form: "ce", nature: "determinant sau pronume demonstrativ",
                  test: "Stă lângă un substantiv («ce matin») sau înainte de «qui/que».",
                  example: "Ce matin, il pleut.", gloss: "În dimineața asta plouă."),
            .init(form: "se", nature: "pronume reflexiv, mereu lângă un verb",
                  test: "La persoana I devine «me»: «il se lave» → «je me lave».",
                  example: "Il se lève tôt.", gloss: "El se trezește devreme.")
        ]),

        HomophoneSet(id: "ces-ses", sound: "/sɛ/", level: .a2, members: [
            .init(form: "ces",   nature: "determinant demonstrativ plural (aceste)",
                  test: "Poți adăuga «-là»: «ces livres-là».",
                  example: "Ces livres sont à moi.", gloss: "Aceste cărți sunt ale mele."),
            .init(form: "ses",   nature: "determinant posesiv plural (ale sale)",
                  test: "Înlocuiește cu «les siens» / «les siennes».",
                  example: "Il range ses affaires.", gloss: "Își strânge lucrurile."),
            .init(form: "c'est", nature: "«cela est» — prezentare",
                  test: "Înlocuiește cu «cela est».",
                  example: "C'est une bonne idée.", gloss: "Este o idee bună."),
            .init(form: "s'est", nature: "pronume reflexiv + «être», urmat de participiu",
                  test: "Vine mereu înaintea unui participiu trecut.",
                  example: "Il s'est levé tôt.", gloss: "S-a trezit devreme."),
            .init(form: "sais",  nature: "verbul «savoir», je / tu",
                  test: "Înlocuiește cu «connais».",
                  example: "Je sais nager.", gloss: "Știu să înot."),
            .init(form: "sait",  nature: "verbul «savoir», il / elle / on",
                  test: "Înlocuiește cu «connaît».",
                  example: "Elle sait la vérité.", gloss: "Ea știe adevărul.")
        ]),

        HomophoneSet(id: "la-là", sound: "/la/", level: .a1, members: [
            .init(form: "la",  nature: "articol hotărât sau pronume complement",
                  test: "Înlocuiește cu «une» (articol) sau cu «le» (pronume).",
                  example: "La porte est ouverte.", gloss: "Ușa este deschisă."),
            .init(form: "là",  nature: "adverb de loc (acolo)",
                  test: "Înlocuiește cu «ici».",
                  example: "Reste là, s'il te plaît.", gloss: "Rămâi acolo, te rog."),
            .init(form: "l'a", nature: "pronume + verbul «avoir»",
                  test: "Înlocuiește cu «l'avait».",
                  example: "Il l'a vue hier.", gloss: "A văzut-o ieri.")
        ]),

        HomophoneSet(id: "mais-mes", sound: "/mɛ/", level: .a2, members: [
            .init(form: "mais", nature: "conjuncție (dar)",
                  test: "Înlocuiește cu «pourtant» sau «cependant».",
                  example: "Il pleut, mais il sort.", gloss: "Plouă, dar el iese."),
            .init(form: "mes",  nature: "determinant posesiv plural (ai mei)",
                  test: "La singular devine «mon» sau «ma».",
                  example: "Mes amis arrivent.", gloss: "Prietenii mei sosesc."),
            .init(form: "met",  nature: "verbul «mettre», il / elle",
                  test: "Înlocuiește cu «place».",
                  example: "Il met son manteau.", gloss: "Își pune paltonul."),
            .init(form: "mets", nature: "verbul «mettre», je / tu",
                  test: "Înlocuiește cu «places».",
                  example: "Tu mets la table.", gloss: "Pui masa."),
            .init(form: "mai",  nature: "numele lunii mai",
                  test: "Este o lună a anului.",
                  example: "Nous sommes en mai.", gloss: "Suntem în mai.")
        ]),

        HomophoneSet(id: "peu-peut", sound: "/pø/", level: .a2, members: [
            .init(form: "peu",  nature: "adverb de cantitate (puțin)",
                  test: "Înlocuiește cu «pas beaucoup».",
                  example: "Il mange peu.", gloss: "El mănâncă puțin."),
            .init(form: "peut", nature: "verbul «pouvoir», il / elle / on",
                  test: "Înlocuiește cu «pouvait».",
                  example: "Il peut venir.", gloss: "El poate veni."),
            .init(form: "peux", nature: "verbul «pouvoir», je / tu",
                  test: "Înlocuiește cu «pouvais».",
                  example: "Je peux t'aider.", gloss: "Te pot ajuta.")
        ]),

        HomophoneSet(id: "quand-quant", sound: "/kɑ̃/", level: .b1, members: [
            .init(form: "quand",  nature: "conjuncție de timp (când)",
                  test: "Înlocuiește cu «lorsque».",
                  example: "Quand il pleut, je lis.", gloss: "Când plouă, citesc."),
            .init(form: "quant",  nature: "apare doar în «quant à» (cât despre)",
                  test: "Este urmat mereu de «à», «au» sau «aux».",
                  example: "Quant à moi, je reste.", gloss: "Cât despre mine, rămân."),
            .init(form: "qu'en",  nature: "«que» + «en»",
                  test: "Poți desface în «que … en».",
                  example: "Qu'en penses-tu ?", gloss: "Ce crezi despre asta?")
        ]),

        HomophoneSet(id: "pres-pret", sound: "/pʁɛ/", level: .b1, members: [
            .init(form: "près", nature: "adverb sau prepoziție (aproape)",
                  test: "Înlocuiește cu «proche». Este invariabil.",
                  example: "La gare est près d'ici.", gloss: "Gara este aproape de aici."),
            .init(form: "prêt", nature: "adjectiv (gata, pregătit)",
                  test: "Se acordă: prête, prêts, prêtes.",
                  example: "Je suis prêt à partir.", gloss: "Sunt gata de plecare.")
        ]),

        HomophoneSet(id: "leur-leurs", sound: "/lœʁ/", level: .b1, members: [
            .init(form: "leur",  nature: "pronume complement, invariabil, înainte de verb",
                  test: "Înlocuiește cu «lui»: dacă merge, nu pui «s».",
                  example: "Je leur parle souvent.", gloss: "Le vorbesc des."),
            .init(form: "leurs", nature: "determinant posesiv plural",
                  test: "Se acordă cu substantivul care urmează.",
                  example: "Ils ont pris leurs valises.", gloss: "Și-au luat valizele.")
        ]),

        HomophoneSet(id: "tout-tous", sound: "/tu/", level: .b1, members: [
            .init(form: "tout", nature: "adjectiv sau adverb, masculin singular",
                  test: "Ca adverb («tout à fait») este invariabil.",
                  example: "Tout le monde est là.", gloss: "Toată lumea este aici."),
            .init(form: "tous", nature: "masculin plural",
                  test: "Ca determinant se citește /tu/, ca pronume /tus/.",
                  example: "Tous les jours, il marche.", gloss: "În fiecare zi, el merge."),
            .init(form: "toux", nature: "substantiv feminin (tuse)",
                  test: "Este un substantiv: «une toux».",
                  example: "Elle a une toux sèche.", gloss: "Are o tuse seacă.")
        ]),

        HomophoneSet(id: "sans-sang", sound: "/sɑ̃/", level: .b1, members: [
            .init(form: "sans", nature: "prepoziție (fără)",
                  test: "Este contrariul lui «avec».",
                  example: "Un café sans sucre.", gloss: "O cafea fără zahăr."),
            .init(form: "s'en", nature: "«se» + «en», lângă un verb",
                  test: "Urmează mereu un verb: «il s'en va».",
                  example: "Il s'en va sans bruit.", gloss: "Pleacă fără zgomot."),
            .init(form: "cent", nature: "numeralul 100",
                  test: "Poate fi înlocuit cu o cifră.",
                  example: "Cent euros, s'il vous plaît.", gloss: "O sută de euro, vă rog."),
            .init(form: "sang", nature: "substantiv masculin (sânge)",
                  test: "Se leagă de «sanguin», care păstrează g-ul.",
                  example: "Une goutte de sang.", gloss: "O picătură de sânge.")
        ]),

        HomophoneSet(id: "temps-tant", sound: "/tɑ̃/", level: .b1, members: [
            .init(form: "temps", nature: "substantiv (timp, vreme)",
                  test: "Are «s» și la singular — vezi «temporel».",
                  example: "Le temps passe vite.", gloss: "Timpul trece repede."),
            .init(form: "tant",  nature: "adverb de cantitate (atât)",
                  test: "Înlocuiește cu «tellement».",
                  example: "Il travaille tant !", gloss: "Muncește atât de mult!"),
            .init(form: "t'en",  nature: "«te» + «en»",
                  test: "Poți desface în «te … en».",
                  example: "Je t'en prie.", gloss: "Cu plăcere.")
        ]),

        HomophoneSet(id: "sur-sûr", sound: "/syʁ/", level: .b1, members: [
            .init(form: "sur", nature: "prepoziție (pe, deasupra)",
                  test: "Arată poziția: «sur la table».",
                  example: "Le livre est sur la table.", gloss: "Cartea este pe masă."),
            .init(form: "sûr", nature: "adjectiv (sigur)",
                  test: "Înlocuiește cu «certain». Se acordă: sûre, sûrs.",
                  example: "Je suis sûr de moi.", gloss: "Sunt sigur pe mine.")
        ]),

        HomophoneSet(id: "du-dû", sound: "/dy/", level: .b2, members: [
            .init(form: "du", nature: "articol partitiv sau contractat («de le»)",
                  test: "Poate fi desfăcut în «de le» sau înseamnă «niște».",
                  example: "Il boit du café.", gloss: "Bea cafea."),
            .init(form: "dû", nature: "participiul trecut al lui «devoir»",
                  test: "Circumflexul dispare la feminin: «due», «dus», «dues».",
                  example: "Il a dû partir.", gloss: "A trebuit să plece.")
        ]),

        HomophoneSet(id: "sa-ça", sound: "/sa/", level: .a2, members: [
            .init(form: "sa", nature: "determinant posesiv feminin",
                  test: "Înlocuiește cu «ma».",
                  example: "Sa maison est grande.", gloss: "Casa lui este mare."),
            .init(form: "ça", nature: "pronume demonstrativ (asta)",
                  test: "Înlocuiește cu «cela».",
                  example: "Ça me plaît beaucoup.", gloss: "Îmi place mult.")
        ]),

        HomophoneSet(id: "vert-verre", sound: "/vɛʁ/", level: .b1, members: [
            .init(form: "vert",  nature: "adjectiv de culoare (verde)",
                  test: "Se acordă: verte, verts, vertes.",
                  example: "Un pull vert.", gloss: "Un pulover verde."),
            .init(form: "verre", nature: "substantiv masculin (pahar, sticlă)",
                  test: "Se leagă de «verrerie».",
                  example: "Un verre d'eau.", gloss: "Un pahar cu apă."),
            .init(form: "vers",  nature: "prepoziție (spre) sau vers de poezie",
                  test: "Arată direcția: «vers la gare».",
                  example: "Il marche vers la gare.", gloss: "Merge spre gară."),
            .init(form: "ver",   nature: "substantiv masculin (vierme)",
                  test: "Este un animal: «un ver de terre».",
                  example: "Un ver de terre.", gloss: "Un râmă.")
        ]),

        HomophoneSet(id: "mer-mère", sound: "/mɛʁ/", level: .a2, members: [
            .init(form: "mer",   nature: "substantiv feminin (mare)",
                  test: "Se leagă de «maritime».",
                  example: "La mer est calme.", gloss: "Marea este liniștită."),
            .init(form: "mère",  nature: "substantiv feminin (mamă)",
                  test: "Se leagă de «maternel».",
                  example: "Sa mère est médecin.", gloss: "Mama lui este medic."),
            .init(form: "maire", nature: "substantiv (primar)",
                  test: "Se leagă de «mairie».",
                  example: "Le maire du village.", gloss: "Primarul satului.")
        ]),

        HomophoneSet(id: "voix-voie", sound: "/vwa/", level: .b1, members: [
            .init(form: "voix",  nature: "substantiv feminin (voce)",
                  test: "Are «x» la singular și la plural.",
                  example: "Elle a une belle voix.", gloss: "Are o voce frumoasă."),
            .init(form: "voie",  nature: "substantiv feminin (cale, linie)",
                  test: "Se leagă de «voyage».",
                  example: "La voie est libre.", gloss: "Calea este liberă."),
            .init(form: "vois",  nature: "verbul «voir», je / tu",
                  test: "Înlocuiește cu «regarde».",
                  example: "Je vois la tour.", gloss: "Văd turnul."),
            .init(form: "voit",  nature: "verbul «voir», il / elle",
                  test: "Înlocuiește cu «regarde».",
                  example: "Il voit son ami.", gloss: "Își vede prietenul.")
        ]),

        HomophoneSet(id: "ni-ny", sound: "/ni/", level: .b2, members: [
            .init(form: "ni",  nature: "conjuncție negativă (nici)",
                  test: "Merge în pereche: «ni … ni …».",
                  example: "Ni toi ni moi.", gloss: "Nici tu, nici eu."),
            .init(form: "n'y", nature: "«ne» + «y»",
                  test: "Poți desface în «ne … y».",
                  example: "Je n'y vais pas.", gloss: "Nu mă duc acolo.")
        ]),

        HomophoneSet(id: "fin-faim", sound: "/fɛ̃/", level: .a2, members: [
            .init(form: "fin",  nature: "substantiv feminin (sfârșit) sau adjectiv (fin)",
                  test: "Contrariul lui «début».",
                  example: "La fin du film.", gloss: "Sfârșitul filmului."),
            .init(form: "faim", nature: "substantiv feminin (foame)",
                  test: "Merge cu «avoir»: «avoir faim».",
                  example: "J'ai faim.", gloss: "Mi-e foame.")
        ])
    ]

    // =========================================================================
    // MARK: - Index
    // =========================================================================

    /// Index graphie -> famille. Construit une fois, consulté à chaque correction.
    private static let setByForm: [String: HomophoneSet] = {
        var map: [String: HomophoneSet] = [:]
        for set in homophoneSets {
            for member in set.members { map[member.form.lowercased()] = set }
        }
        return map
    }()

    /// La famille d'homophones à laquelle appartient une graphie, s'il y en a une.
    static func homophoneSet(containing form: String) -> HomophoneSet? {
        setByForm[form.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)]
    }

    /// Les deux graphies appartiennent-elles à la **même** famille d'homophones ?
    /// C'est le test qui distingue « tu as confondu deux mots » d'une simple
    /// faute d'accent.
    static func areKnownHomophones(_ a: String, _ b: String) -> Bool {
        let x = a.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let y = b.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard x != y, let set = setByForm[x] else { return false }
        return set.forms.map { $0.lowercased() }.contains(y)
    }

    static func homophoneSets(upTo level: ProficiencyLevel) -> [HomophoneSet] {
        let list = homophoneSets.filter { $0.level <= level }
        return list.isEmpty ? homophoneSets : list
    }

    static func homophoneSet(id: String) -> HomophoneSet? {
        homophoneSets.first { $0.id == id }
    }
}
