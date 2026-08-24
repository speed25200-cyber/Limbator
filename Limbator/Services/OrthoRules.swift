import Foundation

/// Le corpus de règles. Écrit à la main, vérifié, et volontairement court :
/// une règle qu'on ne peut pas réciter en deux phrases n'est pas une règle,
/// c'est un chapitre — et personne ne retient un chapitre.
///
/// Chaque règle porte ses exceptions, parce qu'en français les exceptions sont
/// la moitié du travail, et un moyen mnémotechnique quand il en existe un bon.
enum OrthoRules {

    // =========================================================================
    // MARK: - Accents
    // =========================================================================

    static let accents: [OrthoRule] = [
        OrthoRule(
            id: "accents.aigu-grave",
            module: .accents,
            title: "é sau è ?",
            statement: "Pui è (accent grav) când silaba următoare conține un e mut; altfel pui é (accent ascuțit). Compară: «j'espère» dar «espérer», «il achète» dar «acheter».",
            examples: [
                .init(correct: "espérer",  wrong: "espèrer",  gloss: "a spera — silaba următoare are «er», nu e mut"),
                .init(correct: "j'espère", wrong: "j'espére", gloss: "sper — silaba următoare are e mut"),
                .init(correct: "règle",    wrong: "régle",    gloss: "regulă"),
                .init(correct: "régler",   wrong: "règler",   gloss: "a regla")
            ],
            exceptions: ["événement (și «évènement» după 1990)", "je céderai / je cèderai"],
            mnemonic: "Dacă auzi un «e» slab după, scrii è. Dacă nu, scrii é.",
            level: .a2),

        OrthoRule(
            id: "accents.e-sans-accent",
            module: .accents,
            title: "Când e-ul NU poartă accent",
            statement: "Un e nu primește niciodată accent dacă este urmat de o consoană dublă sau de o consoană care închide silaba. Se scrie «belle», «terre», «cette», «mer», «vert» — niciodată «bèlle».",
            examples: [
                .init(correct: "belle",   wrong: "bèlle",   gloss: "frumoasă — «ll» dublu, deci fără accent"),
                .init(correct: "terre",   wrong: "tèrre",   gloss: "pământ"),
                .init(correct: "cette",   wrong: "cètte",   gloss: "această"),
                .init(correct: "essence", wrong: "éssence", gloss: "benzină — «ss» dublu")
            ],
            exceptions: [],
            mnemonic: "Consoană dublă = accentul dispare. Sunetul rămâne deschis oricum.",
            level: .a2),

        OrthoRule(
            id: "accents.cedille",
            module: .accents,
            title: "Sedila (ç)",
            statement: "Sedila se pune sub c doar înainte de a, o, u, ca să păstreze sunetul /s/. Înainte de e, i, y, c-ul se citește deja /s/ — sedila ar fi de prisos.",
            examples: [
                .init(correct: "français", wrong: "francais", gloss: "francez — ç înainte de a"),
                .init(correct: "garçon",   wrong: "garcon",   gloss: "băiat — ç înainte de o"),
                .init(correct: "reçu",     wrong: "recu",     gloss: "primit — ç înainte de u"),
                .init(correct: "ceci",     wrong: "çeci",     gloss: "acesta — fără sedilă înainte de e, i")
            ],
            exceptions: [],
            mnemonic: "A, O, U cer sedila. E, I, Y o refuză.",
            level: .a1),

        OrthoRule(
            id: "accents.trema",
            module: .accents,
            title: "Trema (ë, ï, ü)",
            statement: "Trema se pune pe a doua vocală și arată că cele două vocale se citesc separat. Fără ea, «naif» s-ar citi /nɛf/ în loc de /na-if/.",
            examples: [
                .init(correct: "naïf",  wrong: "naif",  gloss: "naiv — na-if, în două silabe"),
                .init(correct: "Noël",  wrong: "Noel",  gloss: "Crăciun — No-el"),
                .init(correct: "maïs",  wrong: "mais",  gloss: "porumb — ma-is, altfel devine «mais» (dar)"),
                .init(correct: "canoë", wrong: "canoe", gloss: "canoe")
            ],
            exceptions: ["aiguë / aigüe (ambele acceptate după 1990)"],
            mnemonic: "Trema desparte. Fără ea, vocalele se lipesc.",
            level: .a2),

        OrthoRule(
            id: "accents.circonflexe",
            module: .accents,
            title: "Accentul circumflex",
            statement: "Circumflexul marchează cel mai des un s dispărut din latină: «forest» → «forêt», «hospital» → «hôpital». După reforma din 1990 el este facultativ pe i și u, în afară de «dû», «mûr», «sûr», «jeûne» și formele lui «croître».",
            examples: [
                .init(correct: "forêt",   wrong: "foret",   gloss: "pădure — s-ul latin a devenit ê"),
                .init(correct: "hôpital", wrong: "hopital", gloss: "spital — compară cu românescul «spital»"),
                .init(correct: "sûr",     wrong: "sur",     gloss: "sigur — circumflexul e obligatoriu, îl deosebește de «sur» (pe)"),
                .init(correct: "île",     wrong: "ile",     gloss: "insulă")
            ],
            exceptions: ["dû", "mûr", "sûr", "jeûne", "croît"],
            mnemonic: "Circumflexul este piatra funerară a unui s.",
            level: .a2),

        OrthoRule(
            id: "accents.majuscules",
            module: .accents,
            title: "Accentele pe majuscule",
            statement: "În franceza îngrijită, majusculele își păstrează accentele: «État», «À bientôt», «Élève». Absența lor este tolerată în tipar rapid, dar considerată o neglijență.",
            examples: [
                .init(correct: "État",      wrong: "Etat",      gloss: "stat"),
                .init(correct: "À demain",  wrong: "A demain",  gloss: "pe mâine"),
                .init(correct: "Élysée",    wrong: "Elysee",    gloss: "Élysée")
            ],
            exceptions: [],
            mnemonic: "Majuscula nu scutește de accent.",
            level: .b1)
    ]

    // =========================================================================
    // MARK: - Terminaisons verbales
    // =========================================================================

    static let verbEndings: [OrthoRule] = [
        OrthoRule(
            id: "verbEndings.er-e-ez",
            module: .verbEndings,
            title: "-er, -é sau -ez ?",
            statement: "Toate trei se aud la fel. Testul: înlocuiește verbul cu «vendre». Dacă merge «vendre», scrii -er. Dacă merge «vendu», scrii -é. Dacă subiectul este «vous», scrii -ez.",
            examples: [
                .init(correct: "Il va manger",   wrong: "Il va mangé",   gloss: "«Il va vendre» merge → infinitiv, deci -er"),
                .init(correct: "Il a mangé",     wrong: "Il a manger",   gloss: "«Il a vendu» merge → participiu, deci -é"),
                .init(correct: "Vous mangez",    wrong: "Vous mangé",    gloss: "subiectul «vous» → -ez"),
                .init(correct: "pour travailler", wrong: "pour travaillé", gloss: "după o prepoziție vine infinitivul")
            ],
            exceptions: [],
            mnemonic: "«Vendre» sau «vendu» ? Verbul de control al întregii limbi franceze.",
            level: .a2),

        OrthoRule(
            id: "verbEndings.ent-muet",
            module: .verbEndings,
            title: "-ent care nu se aude",
            statement: "La persoana a III-a plural, terminația -ent nu se pronunță niciodată: «ils parlent» se aude exact ca «il parle». Se scrie totuși, mereu.",
            examples: [
                .init(correct: "ils parlent",  wrong: "ils parle",  gloss: "ei vorbesc"),
                .init(correct: "elles jouent", wrong: "elles joue", gloss: "ele se joacă"),
                .init(correct: "ils mangent",  wrong: "ils mange",  gloss: "ei mănâncă")
            ],
            exceptions: ["ils sont", "ils ont", "ils font", "ils vont", "ils disent"],
            mnemonic: "Nu-l auzi niciodată, îl scrii de fiecare dată.",
            level: .a2),

        OrthoRule(
            id: "verbEndings.imparfait",
            module: .verbEndings,
            title: "-ais, -ait, -aient",
            statement: "La imperfect, cele trei terminații se aud identic. Alegerea depinde doar de subiect: -ais (je, tu), -ait (il, elle, on), -aient (ils, elles).",
            examples: [
                .init(correct: "je parlais",     wrong: "je parlait",   gloss: "eu vorbeam"),
                .init(correct: "il parlait",     wrong: "il parlais",   gloss: "el vorbea"),
                .init(correct: "elles parlaient", wrong: "elles parlait", gloss: "ele vorbeau")
            ],
            exceptions: [],
            mnemonic: "Găsește subiectul, scrii terminația. Urechea nu te ajută aici.",
            level: .b1),

        OrthoRule(
            id: "verbEndings.futur-conditionnel",
            module: .verbEndings,
            title: "-rai sau -rais ?",
            statement: "Viitorul face «je parlerai» (o singură persoană, o singură acțiune sigură), condiționalul face «je parlerais». Testul: pune persoana a III-a. «Il parlera» → viitor, deci -rai. «Il parlerait» → condițional, deci -rais.",
            examples: [
                .init(correct: "je parlerai demain",       wrong: "je parlerais demain",  gloss: "voi vorbi mâine — viitor"),
                .init(correct: "je parlerais si je pouvais", wrong: "je parlerai si je pouvais", gloss: "aș vorbi dacă aș putea — condițional")
            ],
            exceptions: [],
            mnemonic: "Trece la «il»: -a este viitor, -ait este condițional.",
            level: .b2)
    ]

    // =========================================================================
    // MARK: - Accords
    // =========================================================================

    static let agreements: [OrthoRule] = [
        OrthoRule(
            id: "agreements.participe-etre",
            module: .agreements,
            title: "Participiul cu «être»",
            statement: "Cu auxiliarul «être», participiul trecut se acordă întotdeauna cu subiectul, în gen și număr.",
            examples: [
                .init(correct: "Elle est partie",     wrong: "Elle est parti",   gloss: "ea a plecat — subiect feminin"),
                .init(correct: "Ils sont arrivés",    wrong: "Ils sont arrivé",  gloss: "ei au sosit — subiect masculin plural"),
                .init(correct: "Elles sont venues",   wrong: "Elles sont venu",  gloss: "ele au venit")
            ],
            exceptions: [],
            mnemonic: "«Être» privește subiectul. Mereu.",
            level: .b1),

        OrthoRule(
            id: "agreements.participe-avoir",
            module: .agreements,
            title: "Participiul cu «avoir»",
            statement: "Cu auxiliarul «avoir», participiul NU se acordă cu subiectul. Se acordă cu complementul direct — dar numai dacă acesta stă ÎNAINTEA verbului.",
            examples: [
                .init(correct: "J'ai mangé les pommes",       wrong: "J'ai mangées les pommes", gloss: "complementul e după verb → fără acord"),
                .init(correct: "Les pommes que j'ai mangées", wrong: "Les pommes que j'ai mangé", gloss: "«que» reia «les pommes», plasat înainte → acord"),
                .init(correct: "Je les ai vues",              wrong: "Je les ai vu",             gloss: "«les» (feminin plural) e înaintea verbului → acord")
            ],
            exceptions: ["Cu «en» nu se face acord: «des pommes, j'en ai mangé».",
                         "«fait» + infinitiv rămâne invariabil: «elle s'est fait mal»."],
            mnemonic: "Caută complementul direct. Dacă e în fața verbului, acorzi.",
            level: .b1),

        OrthoRule(
            id: "agreements.pronominaux",
            module: .agreements,
            title: "Verbele pronominale",
            statement: "La verbele pronominale, acordul urmează tot regula complementului direct plasat înainte. «Elle s'est lavée» (s' = complement direct) dar «Elle s'est lavé les mains» (complementul e «les mains», după verb).",
            examples: [
                .init(correct: "Elle s'est lavée",            wrong: "Elle s'est lavé",       gloss: "s-a spălat — «s'» este complement direct"),
                .init(correct: "Elle s'est lavé les mains",   wrong: "Elle s'est lavée les mains", gloss: "și-a spălat mâinile — complementul vine după"),
                .init(correct: "Elles se sont parlé",         wrong: "Elles se sont parlées", gloss: "și-au vorbit — «parler à», deci complement indirect: fără acord")
            ],
            exceptions: ["Verbele care cer «à» (parler, écrire, téléphoner, sourire) nu dau acord."],
            mnemonic: "Întreabă: «spălat pe cine?». Dacă răspunsul e înainte, acorzi.",
            level: .b2),

        OrthoRule(
            id: "agreements.adjectif",
            module: .agreements,
            title: "Acordul adjectivului",
            statement: "Adjectivul se acordă în gen și număr cu substantivul, chiar dacă marca nu se aude. Adjectivele de culoare compuse sau derivate din substantive rămân invariabile: «des yeux marron», «des robes bleu clair».",
            examples: [
                .init(correct: "une grande maison",   wrong: "une grand maison",  gloss: "o casă mare"),
                .init(correct: "des livres anciens",  wrong: "des livres ancien", gloss: "cărți vechi"),
                .init(correct: "des yeux marron",     wrong: "des yeux marrons",  gloss: "ochi căprui — «marron» e substantiv, invariabil")
            ],
            exceptions: ["marron", "orange", "kaki", "bleu clair", "vert foncé"],
            mnemonic: "Culorile care sunt și fructe nu se acordă.",
            level: .a2)
    ]

    // =========================================================================
    // MARK: - Pluriels et féminins
    // =========================================================================

    static let plurals: [OrthoRule] = [
        OrthoRule(
            id: "plurals.al-aux",
            module: .plurals,
            title: "-al devine -aux",
            statement: "Substantivele în -al fac pluralul în -aux: journal → journaux, cheval → chevaux, animal → animaux.",
            examples: [
                .init(correct: "journaux", wrong: "journals", gloss: "ziare"),
                .init(correct: "chevaux",  wrong: "chevals",  gloss: "cai"),
                .init(correct: "animaux",  wrong: "animals",  gloss: "animale")
            ],
            exceptions: ["bal", "carnaval", "chacal", "festival", "récital", "régal", "cal"],
            mnemonic: "La BAL de CARNAVAL, ȘACALUL merge la FESTIVAL, la RECITAL, ce REGAL.",
            level: .a2),

        OrthoRule(
            id: "plurals.ou-oux",
            module: .plurals,
            title: "-ou face -ous, cu șapte excepții",
            statement: "Substantivele în -ou primesc un s la plural. Șapte fac excepție și primesc x: bijou, caillou, chou, genou, hibou, joujou, pou.",
            examples: [
                .init(correct: "trous",   wrong: "troux",   gloss: "găuri — regula generală"),
                .init(correct: "bijoux",  wrong: "bijous",  gloss: "bijuterii — excepție"),
                .init(correct: "genoux",  wrong: "genous",  gloss: "genunchi — excepție")
            ],
            exceptions: ["bijou", "caillou", "chou", "genou", "hibou", "joujou", "pou"],
            mnemonic: "Vino cu BIJUTERIA, PIETRICICA, VARZA, GENUNCHIUL, BUFNIȚA, JUCĂRIA și PĂDUCHELE: cei șapte cu x.",
            level: .b1),

        OrthoRule(
            id: "plurals.eau-eu-x",
            module: .plurals,
            title: "-au, -eau, -eu primesc x",
            statement: "Substantivele în -au, -eau și -eu fac pluralul cu x, nu cu s: bateau → bateaux, cheveu → cheveux.",
            examples: [
                .init(correct: "bateaux", wrong: "bateaus", gloss: "bărci"),
                .init(correct: "cheveux", wrong: "cheveus", gloss: "păr"),
                .init(correct: "pneus",   wrong: "pneux",   gloss: "anvelope — excepție")
            ],
            exceptions: ["landau", "sarrau", "bleu", "pneu", "émeu"],
            mnemonic: "Doar PNEU și BLEU refuză x-ul.",
            level: .a2),

        OrthoRule(
            id: "plurals.ail-aux",
            module: .plurals,
            title: "-ail face -ails, cu șapte excepții",
            statement: "Substantivele în -ail primesc un s. Șapte fac pluralul în -aux: bail, corail, émail, soupirail, travail, vantail, vitrail.",
            examples: [
                .init(correct: "détails",  wrong: "détaux",   gloss: "detalii — regula generală"),
                .init(correct: "travaux",  wrong: "travails", gloss: "lucrări — excepție"),
                .init(correct: "vitraux",  wrong: "vitrails", gloss: "vitralii — excepție")
            ],
            exceptions: ["bail", "corail", "émail", "soupirail", "travail", "vantail", "vitrail"],
            mnemonic: "MUNCA (travail) și VITRALIUL (vitrail) sunt cele două de reținut.",
            level: .b1),

        OrthoRule(
            id: "plurals.nombres",
            module: .plurals,
            title: "vingt, cent, mille",
            statement: "«Vingt» și «cent» primesc s doar dacă sunt înmulțite ȘI nu sunt urmate de alt numeral: «quatre-vingts» dar «quatre-vingt-deux»; «deux cents» dar «deux cent trois». «Mille» este întotdeauna invariabil.",
            examples: [
                .init(correct: "quatre-vingts",     wrong: "quatre-vingt",   gloss: "optzeci — înmulțit, nimic după"),
                .init(correct: "quatre-vingt-deux", wrong: "quatre-vingts-deux", gloss: "optzeci și doi — urmat de alt numeral"),
                .init(correct: "deux cents",        wrong: "deux cent",      gloss: "două sute"),
                .init(correct: "trois mille",       wrong: "trois milles",   gloss: "trei mii — «mille» invariabil")
            ],
            exceptions: ["million", "milliard"],
            mnemonic: "Dacă vine ceva după, s-ul dispare. «Mille» nu se mișcă niciodată.",
            level: .b1)
    ]

    // =========================================================================
    // MARK: - Consonnes doubles
    // =========================================================================

    static let doubleLetters: [OrthoRule] = [
        OrthoRule(
            id: "doubleLetters.principe",
            module: .doubleLetters,
            title: "De ce dublează franceza",
            statement: "Consoana dublă nu se aude, dar ea închide silaba și menține vocala precedentă deschisă. Româna a simplificat aproape toate aceste grupuri — de aici greșelile constante: «atenție» dar «attention».",
            examples: [
                .init(correct: "attention", wrong: "atention", gloss: "atenție"),
                .init(correct: "adresse",   wrong: "adrese",   gloss: "adresă"),
                .init(correct: "pomme",     wrong: "pome",     gloss: "măr")
            ],
            exceptions: [],
            mnemonic: "Dacă româna are o consoană, franceza are adesea două.",
            level: .a1),

        OrthoRule(
            id: "doubleLetters.appeler-jeter",
            module: .doubleLetters,
            title: "appeler / jeter: dublarea la conjugare",
            statement: "«Appeler» și «jeter» dublează consoana când terminația este mută: j'appelle, je jette — dar nous appelons, nous jetons. Alte verbe preferă accentul grav: j'achète, je pèle.",
            examples: [
                .init(correct: "j'appelle",     wrong: "j'appele",    gloss: "sun, chem"),
                .init(correct: "nous appelons", wrong: "nous appellons", gloss: "sunăm — terminația se aude, fără dublare"),
                .init(correct: "j'achète",      wrong: "j'achette",   gloss: "cumpăr — accent, nu dublare")
            ],
            exceptions: ["acheter", "peler", "geler", "mener", "lever"],
            mnemonic: "Dacă terminația se aude, consoana rămâne simplă.",
            level: .b1)
    ]

    // =========================================================================
    // MARK: - Lettres muettes
    // =========================================================================

    static let silentLetters: [OrthoRule] = [
        OrthoRule(
            id: "silentLetters.finales",
            module: .silentLetters,
            title: "Litera finală care nu se aude",
            statement: "Ca să afli litera mută de la sfârșitul unui cuvânt, caută un cuvânt din aceeași familie în care litera se aude: «petit» → «petite», «grand» → «grandeur», «sang» → «sanguin».",
            examples: [
                .init(correct: "petit",  wrong: "peti",  gloss: "mic — proba: «petite»"),
                .init(correct: "grand",  wrong: "gran",  gloss: "mare — proba: «grandeur»"),
                .init(correct: "sang",   wrong: "san",   gloss: "sânge — proba: «sanguin»"),
                .init(correct: "tabac",  wrong: "taba",  gloss: "tutun — proba: «tabagie»")
            ],
            exceptions: [],
            mnemonic: "Caută ruda cuvântului: ea îți arată litera ascunsă.",
            level: .a2),

        OrthoRule(
            id: "silentLetters.h-muet",
            module: .silentLetters,
            title: "h mut și h aspirat",
            statement: "H-ul francez nu se pronunță niciodată, dar se poartă în două feluri. H mut acceptă eliziunea și legătura: «l'homme», «les_hommes». H aspirat le refuză pe amândouă: «le héros», «les | héros».",
            examples: [
                .init(correct: "l'homme",  wrong: "le homme",  gloss: "omul — h mut"),
                .init(correct: "l'hôtel",  wrong: "le hôtel",  gloss: "hotelul — h mut"),
                .init(correct: "le héros", wrong: "l'héros",   gloss: "eroul — h aspirat"),
                .init(correct: "le hasard", wrong: "l'hasard", gloss: "hazardul — h aspirat")
            ],
            exceptions: ["héros", "hasard", "haut", "honte", "hibou", "haricot", "hache"],
            mnemonic: "Eroul, hazardul și fasolea nu se lasă elidați.",
            level: .b1),

        OrthoRule(
            id: "silentLetters.liaison",
            module: .silentLetters,
            title: "Legătura (la liaison)",
            statement: "O consoană finală mută se trezește înaintea unei vocale: «les amis» se aude /le-za-mi/. Legătura este obligatorie după determinant, pronume și adjectiv antepus; este interzisă după «et» și înaintea unui h aspirat.",
            examples: [
                .init(correct: "les amis",     wrong: nil, gloss: "prietenii — se aude /le-za-mi/"),
                .init(correct: "un grand ami", wrong: nil, gloss: "un mare prieten — se aude /gʁɑ̃-ta-mi/"),
                .init(correct: "et il vient",  wrong: nil, gloss: "și el vine — după «et» NU se face legătura")
            ],
            exceptions: ["et", "h aspirat", "«oui»", "«onze»"],
            mnemonic: "«et» nu leagă niciodată.",
            level: .b1)
    ]

    // =========================================================================
    // MARK: - Pièges roumain -> français
    // =========================================================================

    static let roTraps: [OrthoRule] = [
        OrthoRule(
            id: "roTraps.circonflexe-s",
            module: .roTraps,
            title: "Unde româna are S, franceza are accent",
            statement: "Latina avea un s; româna l-a păstrat, franceza l-a pierdut și a pus în locul lui un accent circumflex. «Fereastră» → «fenêtre», «spital» → «hôpital», «insulă» → «île», «coastă» → «côte».",
            examples: [
                .init(correct: "fenêtre", wrong: "fenetre", gloss: "fereastră"),
                .init(correct: "hôpital", wrong: "hopital", gloss: "spital"),
                .init(correct: "île",     wrong: "ile",     gloss: "insulă"),
                .init(correct: "côte",    wrong: "cote",    gloss: "coastă"),
                .init(correct: "pâte",    wrong: "pate",    gloss: "pastă"),
                .init(correct: "goût",    wrong: "gout",    gloss: "gust")
            ],
            exceptions: [],
            mnemonic: "Vezi un S în românește? Pune un acoperiș în franceză.",
            level: .a2),

        OrthoRule(
            id: "roTraps.consonnes-doubles",
            module: .roTraps,
            title: "Consoanele pe care româna le-a simplificat",
            statement: "Cuvintele savante comune celor două limbi păstrează în franceză consoana dublă latină, pe care româna a redus-o: atenție/attention, adresă/adresse, profesor/professeur, comunicare/communication.",
            examples: [
                .init(correct: "attention",   wrong: "atention",  gloss: "atenție"),
                .init(correct: "adresse",     wrong: "adrese",    gloss: "adresă"),
                .init(correct: "professeur",  wrong: "profesor",  gloss: "profesor"),
                .init(correct: "appartement", wrong: "apartement", gloss: "apartament")
            ],
            exceptions: ["trafic", "confort", "balcon"],
            mnemonic: "Cuvântul îți sună cunoscut? Verifică dacă franceza nu dublează.",
            level: .a1),

        OrthoRule(
            id: "roTraps.lettres-savantes",
            module: .roTraps,
            title: "ph, th, ch, y: literele savante",
            statement: "Acolo unde româna scrie f, t, h sau i în cuvinte de origine greacă, franceza păstrează grafia savantă: farmacie/pharmacie, teatru/théâtre, tehnic/technique, ritm/rythme.",
            examples: [
                .init(correct: "pharmacie", wrong: "farmacie", gloss: "farmacie"),
                .init(correct: "théâtre",   wrong: "teatre",   gloss: "teatru"),
                .init(correct: "technique", wrong: "tehnique", gloss: "tehnic"),
                .init(correct: "rythme",    wrong: "ritme",    gloss: "ritm")
            ],
            exceptions: [],
            mnemonic: "Cuvânt grecesc = literă savantă. Româna a simplificat, franceza nu.",
            level: .a2),

        OrthoRule(
            id: "roTraps.genres",
            module: .roTraps,
            title: "Genurile care nu se potrivesc",
            statement: "Genul comandă acordul, deci ortografia. Unele cuvinte își schimbă genul între cele două limbi: «carte» (f) devine «un livre» (m), «problemă» (f) devine «un problème» (m), «dinte» (m) devine «une dent» (f).",
            examples: [
                .init(correct: "un livre ouvert",     wrong: "une livre ouverte",  gloss: "o carte deschisă"),
                .init(correct: "un problème difficile", wrong: "une problème difficile", gloss: "o problemă dificilă"),
                .init(correct: "une dent blanche",    wrong: "un dent blanc",      gloss: "un dinte alb")
            ],
            exceptions: [],
            mnemonic: "Învață articolul odată cu substantivul — nu genul din română.",
            level: .a2)
    ]

    // =========================================================================
    // MARK: - Homophones (dérivées des familles)
    // =========================================================================

    /// Les règles d'homophones ne sont pas écrites à la main : elles sont
    /// **dérivées** des familles déclarées dans `OrthoSeeds`. Une famille
    /// ajoutée là devient automatiquement une règle consultable ici — pas de
    /// contenu à tenir en double, donc pas de contenu qui diverge.
    static let homophoneRules: [OrthoRule] = {
        return OrthoSeeds.homophoneSets.map { set in
            let forms = set.forms.joined(separator: " / ")
            let tests = set.members
                .map { "« \($0.form) » : \($0.test)" }
                .joined(separator: " ")
            return OrthoRule(
                id: "homophones." + set.id,
                module: .homophones,
                title: forms,
                statement: "Toate se pronunță \(set.sound). Alegerea se face prin substituție, nu după ureche. \(tests)",
                examples: set.members.map {
                    OrthoExample(correct: $0.example, wrong: nil, gloss: $0.gloss)
                },
                exceptions: [],
                mnemonic: nil,
                level: set.level)
        }
    }()

    // =========================================================================
    // MARK: - Index
    // =========================================================================

    static let all: [OrthoRule] =
        accents + homophoneRules + verbEndings + agreements
            + plurals + doubleLetters + silentLetters + roTraps

    static func rules(for module: OrthoModule) -> [OrthoRule] {
        switch module {
        case .accents:       return accents
        case .homophones:    return homophoneRules
        case .verbEndings:   return verbEndings
        case .agreements:    return agreements
        case .plurals:       return plurals
        case .doubleLetters: return doubleLetters
        case .silentLetters: return silentLetters
        case .roTraps:       return roTraps
        }
    }

    static func rule(id: String) -> OrthoRule? {
        all.first { $0.id == id }
    }

    static func rules(for module: OrthoModule, upTo level: ProficiencyLevel) -> [OrthoRule] {
        let list = rules(for: module).filter { $0.level <= level }
        return list.isEmpty ? rules(for: module) : list
    }
}
