import Foundation

/// La banque de dictées.
///
/// Une dictée réussie ne prouve rien si la phrase ne contient aucun piège.
/// Chaque phrase d'ici en contient au moins un, choisi : un accord qui ne
/// s'entend pas, un homophone qu'il faut trancher, une consonne double que le
/// roumain a simplifiée. Le champ `targetRules` dit lequel — c'est lui qui
/// permet, après la correction, de renvoyer l'apprenant vers la bonne règle.
///
/// Les phrases sont écrites en français correct et vérifiées une à une :
/// une dictée fautive enseigne la faute.
enum DictationBank {

    // =========================================================================
    // MARK: - A1 — premières phrases
    // =========================================================================

    static let a1: [DictationItem] = [
        .init(text: "Bonjour, je m'appelle Ioana.",
              translation: "Bună ziua, mă numesc Ioana.",
              level: .a1, targetRules: ["doubleLetters.appeler-jeter", "silentLetters.h-muet"],
              hint: "Atenție la consoana dublă din verbul «appeler».", theme: "greetings"),
        .init(text: "Il fait très beau aujourd'hui.",
              translation: "Este foarte frumos astăzi.",
              level: .a1, targetRules: ["silentLetters.finales"],
              hint: nil, theme: "weather"),
        .init(text: "J'habite à Paris depuis deux ans.",
              translation: "Locuiesc la Paris de doi ani.",
              level: .a1, targetRules: ["homophones.a-à", "silentLetters.h-muet"],
              hint: "«à» sau «a» ? Încearcă substituția cu «avait».", theme: "city"),
        .init(text: "Le café est chaud et le pain est frais.",
              translation: "Cafeaua este fierbinte, iar pâinea este proaspătă.",
              level: .a1, targetRules: ["homophones.et-est"],
              hint: "Două cuvinte mici se aud la fel aici.", theme: "food"),
        .init(text: "Ma sœur a un petit chien noir.",
              translation: "Sora mea are un cățel mic și negru.",
              level: .a1, targetRules: ["homophones.a-à", "accents.trema", "silentLetters.finales"],
              hint: "«sœur» se scrie cu ligatura œ.", theme: "family"),
        .init(text: "Nous allons au marché le samedi matin.",
              translation: "Mergem la piață sâmbătă dimineața.",
              level: .a1, targetRules: ["accents.aigu-grave"],
              hint: nil, theme: "shopping"),
        .init(text: "Où est la gare, s'il vous plaît ?",
              translation: "Unde este gara, vă rog?",
              level: .a1, targetRules: ["homophones.ou-où", "homophones.et-est"],
              hint: "«Où» cu accent arată locul.", theme: "city"),
        .init(text: "Elle a trois frères et une sœur.",
              translation: "Ea are trei frați și o soră.",
              level: .a1, targetRules: ["homophones.a-à", "accents.aigu-grave"],
              hint: nil, theme: "family"),
        .init(text: "Je voudrais un verre d'eau, merci.",
              translation: "Aș dori un pahar cu apă, mulțumesc.",
              level: .a1, targetRules: ["homophones.vert-verre"],
              hint: "«verre» de băut, nu «vert» de culoare.", theme: "food"),
        .init(text: "Le garçon reçoit une leçon de français.",
              translation: "Băiatul primește o lecție de franceză.",
              level: .a1, targetRules: ["accents.cedille"],
              hint: "Trei sedile în aceeași frază.", theme: "school"),
        .init(text: "Il y a une belle fenêtre dans ma chambre.",
              translation: "Este o fereastră frumoasă în camera mea.",
              level: .a1, targetRules: ["roTraps.circonflexe-s", "accents.e-sans-accent"],
              hint: "«fereastră» în franceză păstrează un acoperiș.", theme: "home"),
        .init(text: "Nous sommes en retard pour le train.",
              translation: "Suntem în întârziere pentru tren.",
              level: .a1, targetRules: ["doubleLetters.principe"],
              hint: nil, theme: "travel")
    ]

    // =========================================================================
    // MARK: - A2 — la phrase s'allonge
    // =========================================================================

    static let a2: [DictationItem] = [
        .init(text: "Mes amis sont arrivés hier soir à la gare du Nord.",
              translation: "Prietenii mei au sosit aseară la Gara de Nord.",
              level: .a2, targetRules: ["homophones.son-sont", "agreements.participe-etre", "homophones.a-à"],
              hint: "Auxiliarul «être» cere acordul cu subiectul.", theme: "travel"),
        .init(text: "On ne sait jamais ce qui peut arriver.",
              translation: "Nu se știe niciodată ce se poate întâmpla.",
              level: .a2, targetRules: ["homophones.on-ont", "homophones.ces-ses", "homophones.peu-peut"],
              hint: "Trei mici capcane într-o singură frază.", theme: "general"),
        .init(text: "Ces livres sont à moi, ses cahiers sont à elle.",
              translation: "Aceste cărți sunt ale mele, caietele ei sunt ale ei.",
              level: .a2, targetRules: ["homophones.ces-ses", "homophones.son-sont", "homophones.a-à"],
              hint: "«ces» arată, «ses» posedă.", theme: "school"),
        .init(text: "Il se lève tôt et prend son café sans sucre.",
              translation: "Se trezește devreme și își bea cafeaua fără zahăr.",
              level: .a2, targetRules: ["homophones.ce-se", "homophones.sans-sang", "accents.circonflexe"],
              hint: "«se» stă lângă verb, «sans» înseamnă fără.", theme: "daily"),
        .init(text: "Nous avons visité le musée du Louvre samedi dernier.",
              translation: "Am vizitat muzeul Luvru sâmbăta trecută.",
              level: .a2, targetRules: ["verbEndings.er-e-ez", "agreements.participe-avoir"],
              hint: "Complementul stă după verb: se face acordul?", theme: "culture"),
        .init(text: "Elle a acheté des fleurs pour sa mère.",
              translation: "A cumpărat flori pentru mama ei.",
              level: .a2, targetRules: ["verbEndings.er-e-ez", "homophones.mer-mère", "homophones.sa-ça"],
              hint: "«mère» cu accent grav, nu «mer».", theme: "family"),
        .init(text: "Les enfants jouent dans la cour de l'école.",
              translation: "Copiii se joacă în curtea școlii.",
              level: .a2, targetRules: ["verbEndings.ent-muet", "roTraps.lettres-savantes"],
              hint: "Terminația de plural nu se aude.", theme: "school"),
        .init(text: "Je ne peux pas venir, mais mes frères viendront.",
              translation: "Eu nu pot veni, dar frații mei vor veni.",
              level: .a2, targetRules: ["homophones.peu-peut", "homophones.mais-mes"],
              hint: "«peux» cu x pentru «je», «mais» pentru «dar».", theme: "general"),
        .init(text: "Le professeur écrit son adresse au tableau.",
              translation: "Profesorul își scrie adresa pe tablă.",
              level: .a2, targetRules: ["roTraps.consonnes-doubles", "homophones.son-sont"],
              hint: "Două cuvinte cu consoane duble pe care româna le simplifică.", theme: "school"),
        .init(text: "Il y a beaucoup de bruit dans cette rue étroite.",
              translation: "Este mult zgomot pe strada asta îngustă.",
              level: .a2, targetRules: ["silentLetters.finales", "accents.e-sans-accent"],
              hint: "«bruit» ascunde o literă mută la final.", theme: "city"),
        .init(text: "Nous partons pour la forêt à sept heures.",
              translation: "Plecăm spre pădure la ora șapte.",
              level: .a2, targetRules: ["roTraps.circonflexe-s", "homophones.a-à"],
              hint: "«pădure» în franceză a pierdut un s.", theme: "nature"),
        .init(text: "Tous les jours, elle prend le métro à huit heures.",
              translation: "În fiecare zi ia metroul la ora opt.",
              level: .a2, targetRules: ["homophones.tout-tous", "homophones.a-à", "accents.aigu-grave"],
              hint: "«tous» sau «tout» ? Uită-te la substantiv.", theme: "daily"),
        .init(text: "Ce théâtre est le plus ancien de la ville.",
              translation: "Acest teatru este cel mai vechi din oraș.",
              level: .a2, targetRules: ["roTraps.lettres-savantes", "homophones.ce-se", "homophones.et-est"],
              hint: "«teatru» are trei semne în franceză.", theme: "culture"),
        .init(text: "Elle sait que son frère a faim.",
              translation: "Ea știe că fratele ei este flămând.",
              level: .a2, targetRules: ["homophones.ces-ses", "homophones.son-sont", "homophones.fin-faim"],
              hint: "«faim» se scrie cu ai, nu cu i.", theme: "food")
    ]

    // =========================================================================
    // MARK: - B1 — les accords entrent en scène
    // =========================================================================

    static let b1: [DictationItem] = [
        .init(text: "Les lettres que j'ai écrites sont restées sur la table.",
              translation: "Scrisorile pe care le-am scris au rămas pe masă.",
              level: .b1, targetRules: ["agreements.participe-avoir", "agreements.participe-etre"],
              hint: "«que» reia un feminin plural plasat înaintea verbului.", theme: "writing"),
        .init(text: "Elle s'est levée tôt et s'est lavé les mains.",
              translation: "S-a trezit devreme și s-a spălat pe mâini.",
              level: .b1, targetRules: ["agreements.pronominaux", "homophones.ces-ses"],
              hint: "Două verbe pronominale, două acorduri diferite.", theme: "daily"),
        .init(text: "Quand il pleut, les rues de Paris deviennent silencieuses.",
              translation: "Când plouă, străzile Parisului devin tăcute.",
              level: .b1, targetRules: ["homophones.quand-quant", "verbEndings.ent-muet", "agreements.adjectif"],
              hint: "«Quand» de timp, nu «quant à».", theme: "city"),
        .init(text: "Les journaux annoncent quatre-vingts nouveaux festivals.",
              translation: "Ziarele anunță optzeci de festivaluri noi.",
              level: .b1, targetRules: ["plurals.al-aux", "plurals.nombres", "plurals.eau-eu-x"],
              hint: "Trei pluraluri neregulate într-o singură frază.", theme: "culture"),
        .init(text: "Il leur a dit qu'ils avaient oublié leurs valises.",
              translation: "Le-a spus că își uitaseră valizele.",
              level: .b1, targetRules: ["homophones.leur-leurs", "verbEndings.imparfait"],
              hint: "«leur» pronume nu ia s; «leurs» determinant se acordă.", theme: "travel"),
        .init(text: "Nous étions sûrs qu'elle viendrait avant la fin.",
              translation: "Eram siguri că va veni înainte de sfârșit.",
              level: .b1, targetRules: ["homophones.sur-sûr", "verbEndings.futur-conditionnel", "homophones.fin-faim"],
              hint: "«sûrs» cu circumflex: adjectivul, nu prepoziția.", theme: "general"),
        .init(text: "Les vitraux de la cathédrale brillaient au soleil couchant.",
              translation: "Vitraliile catedralei străluceau în soarele de seară.",
              level: .b1, targetRules: ["plurals.ail-aux", "verbEndings.imparfait"],
              hint: "«vitrail» face parte din cele șapte excepții.", theme: "culture"),
        .init(text: "Il a dû partir sans prévenir personne.",
              translation: "A trebuit să plece fără să anunțe pe nimeni.",
              level: .b1, targetRules: ["homophones.du-dû", "homophones.sans-sang"],
              hint: "«dû» participiul lui «devoir» poartă circumflex.", theme: "general"),
        .init(text: "Ces bijoux appartenaient à sa grand-mère.",
              translation: "Aceste bijuterii îi aparțineau bunicii sale.",
              level: .b1, targetRules: ["plurals.ou-oux", "homophones.ces-ses", "homophones.sa-ça"],
              hint: "«bijou» este unul dintre cele șapte cuvinte cu x.", theme: "family"),
        .init(text: "Le temps passe si vite quand on travaille tant.",
              translation: "Timpul trece atât de repede când muncești atât.",
              level: .b1, targetRules: ["homophones.temps-tant", "homophones.on-ont", "homophones.quand-quant"],
              hint: "«temps» și «tant» se aud identic.", theme: "general"),
        .init(text: "Nous avons recommandé cet hôtel à tous nos amis.",
              translation: "Am recomandat acest hotel tuturor prietenilor noștri.",
              level: .b1, targetRules: ["roTraps.consonnes-doubles", "homophones.tout-tous", "silentLetters.h-muet"],
              hint: "«a recomanda» dublează un m în franceză.", theme: "travel"),
        .init(text: "Elles se sont parlé pendant plus d'une heure.",
              translation: "Și-au vorbit mai mult de o oră.",
              level: .b1, targetRules: ["agreements.pronominaux"],
              hint: "«parler à» — complement indirect, deci fără acord.", theme: "general"),
        .init(text: "La voix du maire tremblait devant la foule.",
              translation: "Vocea primarului tremura în fața mulțimii.",
              level: .b1, targetRules: ["homophones.voix-voie", "homophones.mer-mère", "verbEndings.imparfait"],
              hint: "«voix» cu x, «maire» de la «mairie».", theme: "city"),
        .init(text: "Il faut appeler le médecin, elle a mal aux genoux.",
              translation: "Trebuie chemat medicul, o dor genunchii.",
              level: .b1, targetRules: ["doubleLetters.appeler-jeter", "plurals.ou-oux", "homophones.a-à"],
              hint: "«genou» primește un x la plural.", theme: "health"),
        .init(text: "Quant à moi, je préfère rester près de la mer.",
              translation: "Cât despre mine, prefer să rămân aproape de mare.",
              level: .b1, targetRules: ["homophones.quand-quant", "homophones.pres-pret", "homophones.mer-mère"],
              hint: "«quant à» se scrie cu t și cere «à».", theme: "travel")
    ]

    // =========================================================================
    // MARK: - B2 — nuances et pièges combinés
    // =========================================================================

    static let b2: [DictationItem] = [
        .init(text: "Les décisions qu'ils ont prises ce matin-là ont surpris tout le monde.",
              translation: "Deciziile pe care le-au luat în acea dimineață au surprins pe toată lumea.",
              level: .b2, targetRules: ["agreements.participe-avoir", "homophones.ces-ses", "homophones.tout-tous"],
              hint: "«qu'» reia «les décisions», feminin plural, plasat înainte.", theme: "work"),
        .init(text: "Si j'avais su, je ne serais jamais venu si tôt.",
              translation: "Dacă aș fi știut, nu aș fi venit niciodată atât de devreme.",
              level: .b2, targetRules: ["verbEndings.futur-conditionnel", "accents.circonflexe"],
              hint: "«serais» condițional: treci la «il» pentru a verifica.", theme: "general"),
        .init(text: "Ce qu'elle a écrit dans son cahier m'a beaucoup ému.",
              translation: "Ceea ce a scris în caietul ei m-a emoționat mult.",
              level: .b2, targetRules: ["homophones.ce-se", "agreements.participe-avoir", "homophones.son-sont"],
              hint: "«ce que» nu este un complement direct obișnuit: participiul rămâne invariabil.", theme: "writing"),
        .init(text: "Les journalistes se sont demandé quelles seraient les conséquences.",
              translation: "Jurnaliștii s-au întrebat care ar fi consecințele.",
              level: .b2, targetRules: ["agreements.pronominaux", "verbEndings.futur-conditionnel", "accents.aigu-grave"],
              hint: "«se demander» — pronumele este indirect, deci fără acord.", theme: "work"),
        .init(text: "Il s'est fait mal en descendant l'escalier de Montmartre.",
              translation: "S-a lovit coborând scara din Montmartre.",
              level: .b2, targetRules: ["agreements.pronominaux", "homophones.ces-ses"],
              hint: "«fait» urmat de infinitiv rămâne invariabil.", theme: "city"),
        .init(text: "Nous nous sommes rendu compte que le développement prendrait des années.",
              translation: "Ne-am dat seama că dezvoltarea ar dura ani de zile.",
              level: .b2, targetRules: ["agreements.pronominaux", "roTraps.consonnes-doubles"],
              hint: "La «se rendre compte», complementul este «compte»: niciun acord.", theme: "work"),
        .init(text: "Quoi qu'il arrive, elles resteront fidèles à leurs principes.",
              translation: "Orice s-ar întâmpla, ele vor rămâne fidele principiilor lor.",
              level: .b2, targetRules: ["homophones.leur-leurs", "agreements.adjectif", "verbEndings.futur-conditionnel"],
              hint: "«leurs principes» : determinant, deci acord.", theme: "general"),
        .init(text: "L'architecte a présenté un projet technique très détaillé.",
              translation: "Arhitectul a prezentat un proiect tehnic foarte detaliat.",
              level: .b2, targetRules: ["roTraps.lettres-savantes", "verbEndings.er-e-ez"],
              hint: "Două cuvinte cu ch citit /k/.", theme: "work"),
        .init(text: "Les eaux de la Loire avaient monté pendant toute la nuit.",
              translation: "Apele Loarei crescuseră toată noaptea.",
              level: .b2, targetRules: ["plurals.eau-eu-x", "homophones.tout-tous", "verbEndings.imparfait"],
              hint: "«eau» face pluralul cu x.", theme: "nature"),
        .init(text: "Ni lui ni elle n'y avaient jamais pensé auparavant.",
              translation: "Nici el, nici ea nu se gândiseră vreodată la asta.",
              level: .b2, targetRules: ["homophones.ni-ny"],
              hint: "«n'y» este «ne» + «y», nu conjuncția «ni».", theme: "general")
    ]

    // =========================================================================
    // MARK: - C1 — dictée d'examen
    // =========================================================================

    static let c1: [DictationItem] = [
        .init(text: "Les lettres qu'il avait reçues de Roumanie, il les avait relues cent fois.",
              translation: "Scrisorile pe care le primise din România le recitise de o sută de ori.",
              level: .c1, targetRules: ["agreements.participe-avoir", "plurals.nombres"],
              hint: "Două acorduri de participiu cu complement antepus.", theme: "brancusi"),
        .init(text: "Quant aux sculptures qu'elle s'était fait envoyer, elles arrivèrent trop tard.",
              translation: "Cât despre sculpturile pe care și le trimisese, au sosit prea târziu.",
              level: .c1, targetRules: ["homophones.quand-quant", "agreements.pronominaux"],
              hint: "«fait» urmat de infinitiv rămâne invariabil, orice ar fi.", theme: "brancusi"),
        .init(text: "Ces vitraux-là, on les eût dits peints par un maître flamand.",
              translation: "Acele vitralii, ai fi zis că sunt pictate de un maestru flamand.",
              level: .c1, targetRules: ["plurals.ail-aux", "agreements.participe-avoir", "accents.circonflexe"],
              hint: "«eût dits» — mai mult ca perfectul conjunctivului, cu valoare de condițional.", theme: "culture"),
        .init(text: "Bien qu'elles se soient succédé sans interruption, les saisons lui parurent longues.",
              translation: "Deși s-au succedat fără întrerupere, anotimpurile i s-au părut lungi.",
              level: .c1, targetRules: ["agreements.pronominaux", "agreements.adjectif"],
              hint: "La «se succéder» pronumele este indirect: niciun acord.", theme: "nature"),
        .init(text: "Il avait dû renoncer aux quatre-vingts hectares que son père lui avait légués.",
              translation: "Trebuise să renunțe la cele optzeci de hectare pe care i le lăsase tatăl său.",
              level: .c1, targetRules: ["homophones.du-dû", "plurals.nombres", "agreements.participe-avoir"],
              hint: "Trei capcane: «dû», «quatre-vingts», «légués».", theme: "work"),
        .init(text: "Les chevaux que nous avions vus paître revinrent au galop vers la ferme.",
              translation: "Caii pe care îi văzuserăm pășunând s-au întors în galop spre fermă.",
              level: .c1, targetRules: ["plurals.al-aux", "agreements.participe-avoir"],
              hint: "«vus» se acordă: caii sunt cei care pășunau.", theme: "nature")
    ]

    // =========================================================================
    // MARK: - Index
    // =========================================================================

    static let all: [DictationItem] = a1 + a2 + b1 + b2 + c1

    static func dictations(for level: ProficiencyLevel) -> [DictationItem] {
        switch level {
        case .a1: return a1
        case .a2: return a2
        case .b1: return b1
        case .b2: return b2
        case .c1, .c2: return c1
        }
    }

    /// Les dictées accessibles à un niveau : celles du niveau et celles d'en
    /// dessous. On ne verrouille jamais un apprenant dans un seul palier.
    static func dictations(upTo level: ProficiencyLevel) -> [DictationItem] {
        let list = all.filter { $0.level <= level }
        return list.isEmpty ? a1 : list
    }

    /// Les dictées qui font travailler une règle précise — le chemin de retour
    /// après une faute.
    static func dictations(targeting ruleId: String) -> [DictationItem] {
        all.filter { $0.targetRules.contains(ruleId) }
    }

    /// Une dictée choisie de façon déterministe à partir d'une graine (le jour
    /// de l'année, par exemple) : la « dictée du jour » est la même pour toute
    /// la journée, et change le lendemain.
    static func pick(level: ProficiencyLevel, seed: UInt64) -> DictationItem {
        let pool = dictations(upTo: level)
        guard !pool.isEmpty else {
            return DictationItem(text: "Bonjour.", translation: "Bună ziua.", level: .a1)
        }
        let index = Int(seed % UInt64(pool.count))
        return pool[index]
    }
}
