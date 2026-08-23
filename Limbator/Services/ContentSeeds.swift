import Foundation

/// Le contenu embarqué.
///
/// Limbator doit être **entièrement utilisable dès la première seconde**, avant
/// que Gemma n'ait téléchargé le moindre octet, et pour toujours si l'apprenant
/// choisit de ne jamais le télécharger. Tout ce qui suit est donc écrit à la
/// main, vérifié, et suffisant à lui seul : quatorze leçons, leur vocabulaire,
/// leurs expressions, et le point d'orthographe de chacune.
///
/// Gemma vient ensuite enrichir ce socle — il ne le remplace pas, et surtout il
/// ne peut pas le contredire : `ContentGenerator` réancre systématiquement ce
/// que le modèle produit sur ces valeurs vérifiées.
///
/// Les traductions sont écrites en roumain ; `ContentL10n` les porte vers le
/// français ou l'anglais si l'interface change de langue.
enum ContentSeeds {

    // =========================================================================
    // MARK: - Point d'entrée
    // =========================================================================

    static func lesson(topic: LessonTopic) -> LessonContent {
        switch topic.slug {
        case "greetings":     return greetings()
        case "numbers":       return numbers()
        case "family":        return family()
        case "food":          return food()
        case "city":          return city()
        case "shopping":      return shopping()
        case "weather":       return weather()
        case "verbs-present": return verbsPresent()
        case "past":          return past()
        case "emotions":      return emotions()
        case "work":          return work()
        case "travel":        return travel()
        case "culture":       return culture()
        case "writing":       return writing()
        default:              return greetings()
        }
    }

    // =========================================================================
    // MARK: - 01 · Salutations
    // =========================================================================

    private static func greetings() -> LessonContent {
        LessonContent(
            topicSlug: "greetings",
            introduction: "Prima frază contează. Franceza cere politețe explicită: un «bonjour» omis se observă imediat. Începem cu ea — și cu accentul din «enchanté», care nu e un ornament.",
            cards: [
                card("bonjour", "[bɔ̃.ʒuʁ]", "bună ziua", "",
                     "Bonjour, comment allez-vous ?", "Bună ziua, ce mai faceți?",
                     note: "Un singur cuvânt, fără cratimă. «Bon» + «jour», lipite.", category: "salut"),
                card("bonsoir", "[bɔ̃.swaʁ]", "bună seara", "",
                     "Bonsoir, entrez donc.", "Bună seara, intrați vă rog.",
                     note: "«soir» se scrie cu -oir, ca «voir», «noir».", category: "salut"),
                card("salut", "[sa.ly]", "salut (familiar)", "",
                     "Salut, ça va ?", "Salut, ce faci?",
                     note: "T-ul final este mut, dar se scrie.", category: "salut"),
                card("au revoir", "[o ʁə.vwaʁ]", "la revedere", "",
                     "Au revoir et à bientôt !", "La revedere și pe curând!",
                     note: "Două cuvinte separate. «Aurevoir» într-un cuvânt este o greșeală frecventă.", category: "salut"),
                card("merci", "[mɛʁ.si]", "mulțumesc", "",
                     "Merci beaucoup, madame.", "Mulțumesc mult, doamnă.",
                     note: "Fără accent pe e. «Mérci» nu există.", category: "politețe"),
                card("s'il vous plaît", "[sil vu plɛ]", "vă rog", "",
                     "Un café, s'il vous plaît.", "O cafea, vă rog.",
                     note: "Trei cuvinte, un apostrof și un circumflex pe «plaît».", category: "politețe"),
                card("enchanté", "[ɑ̃.ʃɑ̃.te]", "încântat", "",
                     "Enchanté de faire votre connaissance.", "Încântat de cunoștință.",
                     note: "Accent ascuțit pe é. La feminin: «enchantée».", category: "politețe"),
                card("excusez-moi", "[ɛks.ky.ze.mwa]", "scuzați-mă", "",
                     "Excusez-moi, je suis en retard.", "Scuzați-mă, am întârziat.",
                     note: "Cratima este obligatorie între verb și pronume.", category: "politețe"),
                card("je m'appelle", "[ʒə.ma.pɛl]", "mă numesc", "",
                     "Je m'appelle Ioana, et vous ?", "Mă numesc Ioana, dumneavoastră?",
                     note: "Doi de p și doi de l: ap-pel-le.", category: "prezentare"),
                card("madame", "[ma.dam]", "doamnă", "f",
                     "Bonjour madame, asseyez-vous.", "Bună ziua doamnă, luați loc.",
                     note: "Un singur m la mijloc, spre deosebire de «pomme».", category: "prezentare")
            ],
            phrases: [
                phrase("Comment allez-vous ?", "Ce mai faceți?", "Formal, la prima întâlnire"),
                phrase("Ça va, et toi ?", "Merge, tu?", "Familiar, între prieteni"),
                phrase("Ravi de vous rencontrer.", "Încântat de cunoștință.", "Formal"),
                phrase("À demain !", "Pe mâine!", "La despărțire")
            ],
            grammarTip: "Franceza distinge «tu» (familiar) și «vous» (politicos sau plural). Cu un necunoscut, un profesor, un comerciant: mereu «vous». Româna face la fel cu «dumneavoastră» — regula îți este deja familiară.",
            culturalNote: "În Franța, «bonjour» nu este opțional. Intri într-o brutărie fără să saluți și vei fi servit rece. Se salută vânzătorul, șoferul de autobuz, vecinul de pe scară — de fiecare dată.",
            spotlight: spotlight(.accents, "Accentul face parte din cuvânt",
                "«Enchanté» fără accent nu este o scriere neglijentă: este un alt cuvânt, care nu există. În franceză accentul are valoare de literă.",
                [("enchanté", "enchante"), ("café", "cafe"), ("é", "e")]))
    }

    // =========================================================================
    // MARK: - 02 · Les nombres
    // =========================================================================

    private static func numbers() -> LessonContent {
        LessonContent(
            topicSlug: "numbers",
            introduction: "Prețuri, ore, vârste, adrese: numerele sunt peste tot. Iar franceza le scrie cu o regulă care surprinde pe toată lumea — «quatre-vingts» primește un s, «quatre-vingt-deux» îl pierde.",
            cards: [
                card("un", "[œ̃]", "unu", "", "Un café et un croissant.", "O cafea și un croissant.", category: "număr"),
                card("deux", "[dø]", "doi", "", "Deux billets, s'il vous plaît.", "Două bilete, vă rog.",
                     note: "X final, mut. Niciodată «deus».", category: "număr"),
                card("trois", "[tʁwa]", "trei", "", "Trois jours à Paris.", "Trei zile la Paris.",
                     note: "S final mut, dar obligatoriu.", category: "număr"),
                card("quatre", "[katʁ]", "patru", "", "Quatre heures du matin.", "Ora patru dimineața.", category: "număr"),
                card("cinq", "[sɛ̃k]", "cinci", "", "Cinq euros seulement.", "Doar cinci euro.",
                     note: "Q final, care aici se aude.", category: "număr"),
                card("six", "[sis]", "șase", "", "Six mois en France.", "Șase luni în Franța.", category: "număr"),
                card("sept", "[sɛt]", "șapte", "", "Sept heures et demie.", "Șapte și jumătate.",
                     note: "P-ul nu se aude, dar se scrie.", category: "număr"),
                card("huit", "[ɥit]", "opt", "", "Huit personnes à table.", "Opt persoane la masă.", category: "număr"),
                card("neuf", "[nœf]", "nouă", "", "Neuf euros la place.", "Nouă euro locul.", category: "număr"),
                card("dix", "[dis]", "zece", "", "Dix minutes à pied.", "Zece minute pe jos.", category: "număr"),
                card("vingt", "[vɛ̃]", "douăzeci", "", "Vingt ans aujourd'hui.", "Douăzeci de ani astăzi.",
                     note: "G și t finali, amândoi muți.", category: "număr"),
                card("cent", "[sɑ̃]", "o sută", "", "Cent euros, c'est cher.", "O sută de euro, e scump.",
                     note: "Se scrie ca «sang» și «sans», dar înseamnă altceva.", category: "număr"),
                card("mille", "[mil]", "o mie", "", "Deux mille personnes.", "Două mii de persoane.",
                     note: "Invariabil: niciodată «milles».", category: "număr"),
                card("quatre-vingts", "[ka.tʁə.vɛ̃]", "optzeci", "", "Quatre-vingts pages à lire.", "Optzeci de pagini de citit.",
                     note: "Cu cratimă și cu s — dar «quatre-vingt-deux» pierde s-ul.", category: "număr")
            ],
            phrases: [
                phrase("Combien ça coûte ?", "Cât costă?", "La cumpărături"),
                phrase("Il est trois heures.", "Este ora trei.", "Ora"),
                phrase("J'ai vingt-cinq ans.", "Am douăzeci și cinci de ani.", "Vârsta"),
                phrase("Deux cent trois euros.", "Două sute trei euro.", "Preț exact")
            ],
            grammarTip: "Între 70 și 99 franceza calculează: 70 = «soixante-dix» (60+10), 80 = «quatre-vingts» (4×20), 95 = «quatre-vingt-quinze» (4×20+15). Belgienii și elvețienii spun «septante» și «nonante» — mai simplu, dar nu este franceza standard.",
            culturalNote: "Prețurile franceze se scriu cu virgulă zecimală: 12,50 €. Punctul separă miile: 1 200 € se scrie adesea cu un spațiu.",
            spotlight: spotlight(.plurals, "S-ul care apare și dispare",
                "«Vingt» și «cent» primesc un s când sunt înmulțite și nu sunt urmate de alt numeral. Dacă vine ceva după, s-ul cade.",
                [("quatre-vingts", "quatre-vingt"), ("quatre-vingt-deux", "quatre-vingts-deux"), ("deux cents", "deux cent")]))
    }

    // =========================================================================
    // MARK: - 03 · La famille
    // =========================================================================

    private static func family() -> LessonContent {
        LessonContent(
            topicSlug: "family",
            introduction: "Cuvintele familiei seamănă izbitor cu cele românești — și tocmai de aceea se scriu greșit. «Mère» are accent grav, «sœur» are o ligatură, «fils» se citește /fis/.",
            cards: [
                card("mère", "[mɛʁ]", "mamă", "f", "Ma mère est médecin.", "Mama mea este medic.",
                     note: "Accent grav pe è. Se scrie ca «mer» (mare) și «maire» (primar), dar se aude la fel.", category: "familie"),
                card("père", "[pɛʁ]", "tată", "m", "Mon père travaille à Lyon.", "Tatăl meu lucrează la Lyon.",
                     note: "Accent grav pe è, ca la «mère».", category: "familie"),
                card("frère", "[fʁɛʁ]", "frate", "m", "J'ai deux frères.", "Am doi frați.",
                     note: "Accent grav pe primul e.", category: "familie"),
                card("sœur", "[sœʁ]", "soră", "f", "Ma sœur habite à Nice.", "Sora mea locuiește la Nisa.",
                     note: "Ligatura œ, nu «oe». Se tastează cu « e dans l'o ».", category: "familie"),
                card("fils", "[fis]", "fiu", "m", "Leur fils a dix ans.", "Fiul lor are zece ani.",
                     note: "Se citește /fis/: l-ul nu se aude, s-ul da. Excepție memorabilă.", category: "familie"),
                card("fille", "[fij]", "fiică, fată", "f", "Sa fille étudie le droit.", "Fiica lui studiază dreptul.",
                     note: "«ill» se citește /j/, ca în «famille».", category: "familie"),
                card("grand-mère", "[gʁɑ̃.mɛʁ]", "bunică", "f", "Ma grand-mère cuisine bien.", "Bunica mea gătește bine.",
                     note: "Cratima este obligatorie.", category: "familie"),
                card("oncle", "[ɔ̃kl]", "unchi", "m", "Mon oncle vit au Canada.", "Unchiul meu trăiește în Canada.", category: "familie"),
                card("tante", "[tɑ̃t]", "mătușă", "f", "Ma tante arrive demain.", "Mătușa mea sosește mâine.", category: "familie"),
                card("enfant", "[ɑ̃.fɑ̃]", "copil", "m", "Les enfants jouent dehors.", "Copiii se joacă afară.",
                     note: "Aceeași formă la masculin și feminin: «un enfant», «une enfant».", category: "familie"),
                card("parents", "[pa.ʁɑ̃]", "părinți", "m", "Mes parents sont retraités.", "Părinții mei sunt pensionari.",
                     note: "T-ul și s-ul finali sunt muți.", category: "familie"),
                card("femme", "[fam]", "femeie, soție", "f", "Sa femme est architecte.", "Soția lui este arhitectă.",
                     note: "Se citește /fam/, nu /fɛm/. Neregularitate celebră.", category: "familie")
            ],
            phrases: [
                phrase("Tu as des frères et sœurs ?", "Ai frați și surori?", "Conversație"),
                phrase("Je suis fille unique.", "Sunt copil unic (fată).", "Prezentare"),
                phrase("Toute la famille est là.", "Toată familia este aici.", "Reuniune"),
                phrase("Il ressemble à son père.", "Seamănă cu tatăl lui.", "Descriere")
            ],
            grammarTip: "Posesivul se acordă cu OBIECTUL posedat, nu cu posesorul: «son livre» = cartea lui SAU a ei. Româna face la fel cu «cartea sa» — dar franceza nu are echivalent pentru «al lor» la singular.",
            culturalNote: "«Belle-mère» înseamnă și soacră, și mama vitregă. Contextul decide — și adesea tonul vocii.",
            spotlight: spotlight(.homophones, "mer, mère, maire",
                "Trei cuvinte, un singur sunet /mɛʁ/. Marea, mama, primarul. Numai scrisul le deosebește.",
                [("ma mère", "ma mer"), ("la mer Méditerranée", "la mère Méditerranée"), ("le maire du village", "le mère du village")]))
    }

    // =========================================================================
    // MARK: - 04 · Manger et boire
    // =========================================================================

    private static func food() -> LessonContent {
        LessonContent(
            topicSlug: "food",
            introduction: "Franța parlează despre mâncare cu o seriozitate pe care o rezervă altfel doar gramaticii. Iar «œuf» îți cere de la primul cuvânt să stăpânești ligatura.",
            cards: [
                card("pain", "[pɛ̃]", "pâine", "m", "Un pain, s'il vous plaît.", "O pâine, vă rog.",
                     note: "«ain» se citește nazal /ɛ̃/, ca în «main», «demain».", category: "mâncare"),
                card("fromage", "[fʁɔ.maʒ]", "brânză", "m", "Le fromage vient après le plat.", "Brânza vine după felul principal.", category: "mâncare"),
                card("eau", "[o]", "apă", "f", "Une carafe d'eau, merci.", "O carafă cu apă, mulțumesc.",
                     note: "Trei litere pentru un singur sunet /o/. Pluralul: «eaux».", category: "băutură"),
                card("vin", "[vɛ̃]", "vin", "m", "Un verre de vin rouge.", "Un pahar de vin roșu.",
                     note: "Se scrie ca sunetul din «pain», dar cu «in».", category: "băutură"),
                card("café", "[ka.fe]", "cafea", "m", "Un café serré, s'il vous plaît.", "O cafea tare, vă rog.",
                     note: "Accent ascuțit pe é.", category: "băutură"),
                card("beurre", "[bœʁ]", "unt", "m", "Du beurre salé de Bretagne.", "Unt sărat din Bretania.",
                     note: "Doi de r: beur-re.", category: "mâncare"),
                card("œuf", "[œf]", "ou", "m", "Un œuf à la coque.", "Un ou fiert moale.",
                     note: "Ligatura œ. La plural «œufs» se citește /ø/, fără f.", category: "mâncare"),
                card("poisson", "[pwa.sɔ̃]", "pește", "m", "Le poisson du jour est le bar.", "Peștele zilei este lupul de mare.",
                     note: "Doi de s. Cu un singur s, «poison» înseamnă otravă.", category: "mâncare"),
                card("viande", "[vjɑ̃d]", "carne", "f", "Je ne mange pas de viande.", "Nu mănânc carne.", category: "mâncare"),
                card("légume", "[le.gym]", "legumă", "m", "Des légumes de saison.", "Legume de sezon.",
                     note: "Accent ascuțit pe é, și e masculin în franceză.", category: "mâncare"),
                card("gâteau", "[gɑ.to]", "prăjitură", "m", "Un gâteau au chocolat.", "O prăjitură cu ciocolată.",
                     note: "Circumflex pe â, plural «gâteaux» cu x.", category: "mâncare"),
                card("sel", "[sɛl]", "sare", "m", "Passe-moi le sel.", "Dă-mi sarea.",
                     note: "Masculin în franceză, deși «sarea» e feminin în română.", category: "mâncare")
            ],
            phrases: [
                phrase("L'addition, s'il vous plaît.", "Nota, vă rog.", "La restaurant"),
                phrase("Je voudrais réserver une table.", "Aș vrea să rezerv o masă.", "Rezervare"),
                phrase("C'est délicieux !", "Este delicios!", "Compliment"),
                phrase("Sans gluten, s'il vous plaît.", "Fără gluten, vă rog.", "Regim")
            ],
            grammarTip: "Articolul partitiv este obligatoriu: «je mange du pain», niciodată «je mange pain». Româna spune «mănânc pâine» fără articol — franceza refuză.",
            culturalNote: "Ordinea unui prânz franțuzesc: entrée, plat, fromage, dessert. Brânza vine ÎNAINTEA desertului — inversarea se remarcă.",
            spotlight: spotlight(.doubleLetters, "poisson sau poison ?",
                "Un singur s schimbă peștele în otravă. Consoana dublă nu se aude, dar decide sensul.",
                [("poisson", "poison"), ("dessert", "désert"), ("beurre", "beure")]))
    }

    // =========================================================================
    // MARK: - 05 · La ville
    // =========================================================================

    private static func city() -> LessonContent {
        LessonContent(
            topicSlug: "city",
            introduction: "Ca să ceri o direcție trebuie să stăpânești un cuvânt de două litere: «à». Fără accent, este verbul «avoir» și fraza nu mai are sens.",
            cards: [
                card("rue", "[ʁy]", "stradă", "f", "J'habite rue de Rivoli.", "Locuiesc pe strada Rivoli.",
                     note: "Fără articol înaintea numelui străzii: «rue de Rivoli».", category: "oraș"),
                card("place", "[plas]", "piață, loc", "f", "Rendez-vous place de la Bastille.", "Ne vedem în piața Bastilia.", category: "oraș"),
                card("gare", "[gaʁ]", "gară", "f", "La gare est à dix minutes.", "Gara este la zece minute.", category: "oraș"),
                card("pont", "[pɔ̃]", "pod", "m", "Le pont Neuf est le plus ancien.", "Podul Nou este cel mai vechi.",
                     note: "T-ul final este mut.", category: "oraș"),
                card("quartier", "[kaʁ.tje]", "cartier", "m", "C'est un quartier calme.", "Este un cartier liniștit.",
                     note: "«qu» se citește /k/, ca peste tot în franceză.", category: "oraș"),
                card("immeuble", "[i.mœbl]", "bloc, imobil", "m", "Un immeuble haussmannien.", "Un imobil haussmannian.",
                     note: "Doi de m: im-meuble.", category: "oraș"),
                card("à gauche", "[a goʃ]", "la stânga", "", "Tournez à gauche après le pont.", "Faceți la stânga după pod.",
                     note: "«à» cu accent grav — prepoziție, nu verbul «avoir».", category: "direcție"),
                card("à droite", "[a dʁwat]", "la dreapta", "", "La pharmacie est à droite.", "Farmacia este la dreapta.",
                     note: "«oi» se citește /wa/.", category: "direcție"),
                card("tout droit", "[tu dʁwa]", "drept înainte", "", "Continuez tout droit.", "Continuați drept înainte.",
                     note: "«tout droit» fără s, spre deosebire de «tous».", category: "direcție"),
                card("arrêt", "[a.ʁɛ]", "stație", "m", "L'arrêt de bus est là.", "Stația de autobuz este acolo.",
                     note: "Doi de r și circumflex pe ê.", category: "oraș"),
                card("plan", "[plɑ̃]", "hartă, plan", "m", "Vous avez un plan du métro ?", "Aveți o hartă de metrou?", category: "oraș"),
                card("loin", "[lwɛ̃]", "departe", "", "Ce n'est pas loin d'ici.", "Nu este departe de aici.",
                     note: "«oin» se citește /wɛ̃/.", category: "direcție")
            ],
            phrases: [
                phrase("Où est la gare, s'il vous plaît ?", "Unde este gara, vă rog?", "Cerere de direcție"),
                phrase("C'est à combien de minutes ?", "La câte minute este?", "Distanță"),
                phrase("Je cherche cette adresse.", "Caut această adresă.", "Orientare"),
                phrase("Prenez la deuxième à droite.", "Luați a doua la dreapta.", "Indicație")
            ],
            grammarTip: "«À» cu accent grav este prepoziția; «a» fără accent este verbul «avoir». Testul: încearcă «avait». «Il a un plan» → «il avait un plan», deci fără accent. «Il va à Paris» → «il va avait Paris» nu are sens, deci cu accent.",
            culturalNote: "Numerotarea arondismentelor pariziene urcă în spirală de la centru: 1er lângă Luvru, 20e la margine. Un parizian îți spune «j'habite dans le onzième» și presupune că știi unde e.",
            spotlight: spotlight(.homophones, "a sau à ?",
                "Cel mai frecvent piaj al francezei. Un accent grav separă verbul de prepoziție.",
                [("Il va à Paris", "Il va a Paris"), ("Il a un plan", "Il à un plan"), ("à gauche", "a gauche")]))
    }

    // =========================================================================
    // MARK: - 06 · Les courses
    // =========================================================================

    private static func shopping() -> LessonContent {
        LessonContent(
            topicSlug: "shopping",
            introduction: "«Combien ça coûte ?» — și iată circumflexul care ascunde un s. Româna spune «a costa»; franceza a pierdut s-ul și a pus un acoperiș în locul lui.",
            cards: [
                card("magasin", "[ma.ga.zɛ̃]", "magazin", "m", "Le magasin ferme à dix-neuf heures.", "Magazinul se închide la ora nouăsprezece.",
                     note: "Un singur s, citit /z/ între vocale.", category: "cumpărături"),
                card("prix", "[pʁi]", "preț", "m", "Le prix est affiché.", "Prețul este afișat.",
                     note: "X final mut, la fel la singular și plural.", category: "cumpărături"),
                card("cher", "[ʃɛʁ]", "scump", "", "C'est trop cher pour moi.", "Este prea scump pentru mine.",
                     note: "R-ul final se aude aici, spre deosebire de infinitivele în -er.", category: "cumpărături"),
                card("monnaie", "[mɔ.nɛ]", "mărunțiș", "f", "Je n'ai pas de monnaie.", "Nu am mărunțiș.",
                     note: "Doi de n și «aie» la final.", category: "cumpărături"),
                card("caisse", "[kɛs]", "casă (de marcat)", "f", "Payez à la caisse, s'il vous plaît.", "Plătiți la casă, vă rog.",
                     note: "Doi de s: cais-se.", category: "cumpărături"),
                card("coûter", "[ku.te]", "a costa", "", "Combien ça coûte ?", "Cât costă?",
                     note: "Circumflex pe û — s-ul din «a costa» a dispărut.", category: "cumpărături"),
                card("acheter", "[aʃ.te]", "a cumpăra", "", "Je voudrais acheter ce livre.", "Aș vrea să cumpăr această carte.",
                     note: "«j'achète» cu accent grav, nu cu dublă consoană.", category: "cumpărături"),
                card("taille", "[taj]", "mărime", "f", "Vous avez la taille au-dessus ?", "Aveți mărimea de deasupra?",
                     note: "«ill» se citește /j/.", category: "cumpărături"),
                card("essayer", "[e.se.je]", "a proba", "", "Je peux essayer ce manteau ?", "Pot proba acest palton?",
                     note: "Doi de s: es-sayer.", category: "cumpărături"),
                card("soldes", "[sɔld]", "reduceri", "m", "Les soldes commencent mercredi.", "Reducerile încep miercuri.",
                     note: "Masculin plural, folosit aproape mereu la plural.", category: "cumpărături"),
                card("reçu", "[ʁə.sy]", "bon fiscal", "m", "Gardez votre reçu.", "Păstrați bonul.",
                     note: "Sedilă înainte de u, altfel s-ar citi /rəky/.", category: "cumpărături"),
                card("gratuit", "[gʁa.tɥi]", "gratuit", "", "La livraison est gratuite.", "Livrarea este gratuită.",
                     note: "T-ul final este mut; la feminin «gratuite» îl face să se audă.", category: "cumpărături")
            ],
            phrases: [
                phrase("Combien ça coûte ?", "Cât costă?", "Preț"),
                phrase("Je regarde, merci.", "Doar mă uit, mulțumesc.", "Politicos, într-un magazin"),
                phrase("Vous acceptez la carte ?", "Acceptați cardul?", "Plată"),
                phrase("C'est une bonne affaire.", "Este o afacere bună.", "Comentariu")
            ],
            grammarTip: "«Ça» cu sedilă este pronumele demonstrativ («cela»); «sa» fără sedilă este posesivul. «Combien ça coûte ?» — niciodată «sa coûte».",
            culturalNote: "Soldurile franceze sunt reglementate prin lege: două perioade pe an, cu date fixate de stat. În afara lor, un magazin nu are dreptul să anunțe «soldes».",
            spotlight: spotlight(.roTraps, "Circumflexul care ascunde un S",
                "«A costa» în română, «coûter» în franceză. S-ul latin a dispărut și a lăsat un acoperiș. La fel: gust → goût, crustă → croûte.",
                [("coûter", "couter"), ("goût", "gout"), ("croûte", "croute")]))
    }

    // =========================================================================
    // MARK: - 07 · Le temps
    // =========================================================================

    private static func weather() -> LessonContent {
        LessonContent(
            topicSlug: "weather",
            introduction: "Vremea se spune impersonal: «il fait beau», literal «el face frumos». Iar «temps» poartă un s chiar și la singular.",
            cards: [
                card("soleil", "[sɔ.lɛj]", "soare", "m", "Il y a du soleil aujourd'hui.", "Este soare astăzi.",
                     note: "«eil» se citește /ɛj/.", category: "vreme"),
                card("pluie", "[plɥi]", "ploaie", "f", "La pluie a cessé.", "Ploaia a încetat.", category: "vreme"),
                card("vent", "[vɑ̃]", "vânt", "m", "Le vent souffle fort.", "Vântul suflă tare.",
                     note: "T-ul final este mut; «venteux» îl face să se audă.", category: "vreme"),
                card("neige", "[nɛʒ]", "zăpadă", "f", "Il y a de la neige en montagne.", "Este zăpadă la munte.", category: "vreme"),
                card("nuage", "[nɥaʒ]", "nor", "m", "Quelques nuages ce matin.", "Câțiva nori în această dimineață.", category: "vreme"),
                card("chaud", "[ʃo]", "cald", "", "Il fait chaud en août.", "Este cald în august.",
                     note: "D final mut; «chaude» îl face să se audă.", category: "vreme"),
                card("froid", "[fʁwa]", "frig", "", "Il fait froid dehors.", "Este frig afară.",
                     note: "D final mut, ca la «chaud».", category: "vreme"),
                card("orage", "[ɔ.ʁaʒ]", "furtună", "m", "Un orage éclate.", "Izbucnește o furtună.", category: "vreme"),
                card("printemps", "[pʁɛ̃.tɑ̃]", "primăvară", "m", "Au printemps, tout refleurit.", "Primăvara, totul înflorește din nou.",
                     note: "Trei litere finale mute: p, s — și «tem» nazal.", category: "anotimp"),
                card("été", "[e.te]", "vară", "m", "L'été dernier, à Nice.", "Vara trecută, la Nisa.",
                     note: "Două accente ascuțite. Se scrie ca participiul lui «être».", category: "anotimp"),
                card("automne", "[ɔ.tɔn]", "toamnă", "m", "L'automne est doux ici.", "Toamna este blândă aici.",
                     note: "M-ul nu se aude: se citește /ɔtɔn/.", category: "anotimp"),
                card("hiver", "[i.vɛʁ]", "iarnă", "m", "L'hiver a été long.", "Iarna a fost lungă.",
                     note: "H mut, deci «l'hiver». R-ul final se aude.", category: "anotimp")
            ],
            phrases: [
                phrase("Quel temps fait-il ?", "Ce vreme este?", "Întrebare"),
                phrase("Il fait beau aujourd'hui.", "Este frumos astăzi.", "Constatare"),
                phrase("Il va pleuvoir ce soir.", "O să plouă diseară.", "Prognoză"),
                phrase("Couvre-toi, il fait froid.", "Îmbracă-te, este frig.", "Sfat")
            ],
            grammarTip: "Expresiile de vreme folosesc «il» impersonal: «il pleut», «il neige», «il fait beau». Acest «il» nu desemnează pe nimeni — româna spune pur și simplu «plouă».",
            culturalNote: "«Il fait un temps de chien» înseamnă vreme îngrozitoare. Franceza are o colecție întreagă de expresii meteorologice cu animale.",
            spotlight: spotlight(.silentLetters, "Litera finală care nu se aude",
                "«Chaud», «froid», «vent» își ascund ultima literă. Ca s-o găsești, caută femininul sau un derivat: chaude, froide, venteux.",
                [("chaud", "chau"), ("froid", "froi"), ("vent", "ven")]))
    }

    // =========================================================================
    // MARK: - 08 · Les verbes au présent
    // =========================================================================

    private static func verbsPresent() -> LessonContent {
        LessonContent(
            topicSlug: "verbs-present",
            introduction: "Patru verbe deschid toate ușile: être, avoir, aller, faire. Și o terminație pe care nu o vei auzi niciodată: «-ent» al persoanei a III-a plural.",
            cards: [
                card("être", "[ɛtʁ]", "a fi", "", "Je suis roumain.", "Sunt român.",
                     note: "Circumflex pe ê. Formele: suis, es, est, sommes, êtes, sont.", category: "verb"),
                card("avoir", "[a.vwaʁ]", "a avea", "", "J'ai deux frères.", "Am doi frați.",
                     note: "Formele: ai, as, a, avons, avez, ont.", category: "verb"),
                card("aller", "[a.le]", "a merge", "", "Je vais au marché.", "Merg la piață.",
                     note: "Neregulat: vais, vas, va, allons, allez, vont.", category: "verb"),
                card("faire", "[fɛʁ]", "a face", "", "Que fais-tu ce soir ?", "Ce faci diseară?",
                     note: "«nous faisons» se citește /fəzɔ̃/, nu /fɛzɔ̃/.", category: "verb"),
                card("dire", "[diʁ]", "a spune", "", "Il dit toujours la vérité.", "Spune mereu adevărul.",
                     note: "«vous dites», nu «vous disez».", category: "verb"),
                card("pouvoir", "[pu.vwaʁ]", "a putea", "", "Je peux t'aider.", "Te pot ajuta.",
                     note: "«je peux» cu x, «il peut» cu t.", category: "verb"),
                card("vouloir", "[vu.lwaʁ]", "a vrea", "", "Je voudrais un café.", "Aș vrea o cafea.",
                     note: "«je voudrais» este mai politicos decât «je veux».", category: "verb"),
                card("savoir", "[sa.vwaʁ]", "a ști", "", "Je sais nager.", "Știu să înot.",
                     note: "«je sais» se scrie ca «ces», «ses», «c'est».", category: "verb"),
                card("venir", "[və.niʁ]", "a veni", "", "Elle vient demain.", "Ea vine mâine.", category: "verb"),
                card("prendre", "[pʁɑ̃dʁ]", "a lua", "", "Je prends le métro.", "Iau metroul.",
                     note: "«ils prennent» cu doi de n.", category: "verb"),
                card("voir", "[vwaʁ]", "a vedea", "", "Je vois la tour Eiffel.", "Văd turnul Eiffel.",
                     note: "«je vois» se scrie ca «voix» și «voie».", category: "verb"),
                card("devoir", "[də.vwaʁ]", "a trebui", "", "Je dois partir.", "Trebuie să plec.",
                     note: "Participiul «dû» poartă circumflex, ca să nu se confunde cu «du».", category: "verb")
            ],
            phrases: [
                phrase("Je suis en train de travailler.", "Sunt în curs de a lucra.", "Acțiune în desfășurare"),
                phrase("Qu'est-ce que tu fais ?", "Ce faci?", "Întrebare curentă"),
                phrase("On y va ?", "Mergem?", "Propunere"),
                phrase("Ils viennent avec nous.", "Ei vin cu noi.", "Plural")
            ],
            grammarTip: "Terminația «-ent» a persoanei a III-a plural nu se pronunță NICIODATĂ: «il parle» și «ils parlent» se aud identic. Numai contextul — și scrisul — le deosebesc.",
            culturalNote: "«On» a înlocuit «nous» în franceza vorbită: «on y va» pentru «nous y allons». La scris, în context formal, «nous» rămâne de rigoare.",
            spotlight: spotlight(.verbEndings, "Terminația mută",
                "«Ils parlent» se aude exact ca «il parle». Găsește subiectul înainte de a scrie terminația — urechea nu îți este de niciun ajutor aici.",
                [("ils parlent", "ils parle"), ("elles jouent", "elles joue"), ("ils mangent", "ils mange")]))
    }

    // =========================================================================
    // MARK: - 09 · Le passé et les accords
    // =========================================================================

    private static func past() -> LessonContent {
        LessonContent(
            topicSlug: "past",
            introduction: "Aici se joacă totul. Passé composé cere un auxiliar — être sau avoir — și fiecare impune propria regulă de acord. Este cea mai grea și cea mai utilă lecție din tot parcursul.",
            cards: [
                card("hier", "[jɛʁ]", "ieri", "", "Hier, nous sommes allés au musée.", "Ieri am fost la muzeu.",
                     note: "H mut, deci nu se elidează: «hier soir», nu «h'ier».", category: "trecut"),
                card("déjà", "[de.ʒa]", "deja", "", "J'ai déjà mangé.", "Am mâncat deja.",
                     note: "Două accente diferite: é ascuțit, à grav.", category: "trecut"),
                card("arrivé", "[a.ʁi.ve]", "sosit", "", "Elle est arrivée à midi.", "Ea a sosit la prânz.",
                     note: "Cu «être»: se acordă cu subiectul — «arrivée» la feminin.", category: "participiu"),
                card("parti", "[paʁ.ti]", "plecat", "", "Ils sont partis tôt.", "Ei au plecat devreme.",
                     note: "Cu «être»: «partis» la masculin plural.", category: "participiu"),
                card("mangé", "[mɑ̃.ʒe]", "mâncat", "", "J'ai mangé une pomme.", "Am mâncat un măr.",
                     note: "Cu «avoir» și complement după: niciun acord.", category: "participiu"),
                card("écrit", "[e.kʁi]", "scris", "", "Les lettres que j'ai écrites.", "Scrisorile pe care le-am scris.",
                     note: "Complement feminin plural, plasat înainte: «écrites».", category: "participiu"),
                card("pris", "[pʁi]", "luat", "", "J'ai pris le train.", "Am luat trenul.",
                     note: "Participiul lui «prendre», cu s final mut.", category: "participiu"),
                card("vu", "[vy]", "văzut", "", "Je l'ai vue hier.", "Am văzut-o ieri.",
                     note: "«vue» dacă «l'» reia un feminin.", category: "participiu"),
                card("fait", "[fɛ]", "făcut", "", "Ce qu'elle a fait est admirable.", "Ceea ce a făcut este admirabil.",
                     note: "«fait» urmat de infinitiv rămâne invariabil.", category: "participiu"),
                card("venu", "[və.ny]", "venit", "", "Elles sont venues ensemble.", "Ele au venit împreună.",
                     note: "Cu «être»: «venues» la feminin plural.", category: "participiu"),
                card("descendre", "[de.sɑ̃dʁ]", "a coborî", "", "Il est descendu du train.", "A coborât din tren.",
                     note: "Face parte din verbele care iau «être».", category: "verb"),
                card("rester", "[ʁɛs.te]", "a rămâne", "", "Nous sommes restés une semaine.", "Am rămas o săptămână.",
                     note: "Cu «être», deci acord: «restés».", category: "verb")
            ],
            phrases: [
                phrase("Qu'est-ce que tu as fait hier ?", "Ce ai făcut ieri?", "Întrebare"),
                phrase("Je suis né à Cluj.", "M-am născut la Cluj.", "Origine"),
                phrase("Elles se sont rencontrées à Paris.", "S-au întâlnit la Paris.", "Pronominal"),
                phrase("Nous avons beaucoup marché.", "Am mers mult pe jos.", "Bilanț")
            ],
            grammarTip: "Cu «être», participiul se acordă cu SUBIECTUL. Cu «avoir», nu se acordă cu subiectul — ci cu complementul direct, și doar dacă acesta este plasat înaintea verbului.",
            culturalNote: "Passé simple («il alla», «elle prit») nu se mai vorbește: îl întâlnești doar în romane și în presa literară. La oral, franceza folosește passé composé pentru tot.",
            spotlight: spotlight(.agreements, "Unde stă complementul?",
                "Cu «avoir», acordul depinde de o singură întrebare: complementul direct este înaintea verbului sau după?",
                [("J'ai mangé les pommes", "J'ai mangées les pommes"),
                 ("Les pommes que j'ai mangées", "Les pommes que j'ai mangé"),
                 ("Je les ai vues", "Je les ai vu")]))
    }

    // =========================================================================
    // MARK: - 10 · Les émotions
    // =========================================================================

    private static func emotions() -> LessonContent {
        LessonContent(
            topicSlug: "emotions",
            introduction: "Adjectivele emoției se acordă — și acordul lor nu se aude aproape niciodată. «Heureux» devine «heureuse»; «inquiet» devine «inquiète».",
            cards: [
                card("heureux", "[ø.ʁø]", "fericit", "", "Je suis heureux de te voir.", "Sunt fericit să te văd.",
                     note: "H mut. La feminin: «heureuse».", category: "emoție"),
                card("triste", "[tʁist]", "trist", "", "Elle a l'air triste.", "Pare tristă.",
                     note: "Aceeași formă la masculin și feminin.", category: "emoție"),
                card("inquiet", "[ɛ̃.kjɛ]", "îngrijorat", "", "Il est inquiet pour son fils.", "Este îngrijorat pentru fiul lui.",
                     note: "La feminin «inquiète», cu accent grav.", category: "emoție"),
                card("ému", "[e.my]", "emoționat", "", "J'étais très ému.", "Eram foarte emoționat.",
                     note: "Accent ascuțit pe é. La feminin: «émue».", category: "emoție"),
                card("fâché", "[fɑ.ʃe]", "supărat", "", "Elle est fâchée contre moi.", "Este supărată pe mine.",
                     note: "Circumflex pe â și accent ascuțit pe é.", category: "emoție"),
                card("surpris", "[syʁ.pʁi]", "surprins", "", "Nous étions surpris.", "Eram surprinși.",
                     note: "S final mut; la feminin «surprise» îl face să se audă.", category: "emoție"),
                card("fatigué", "[fa.ti.ge]", "obosit", "", "Je suis fatigué ce soir.", "Sunt obosit în seara asta.",
                     note: "«gu» păstrează sunetul /g/ înainte de é.", category: "emoție"),
                card("fier", "[fjɛʁ]", "mândru", "", "Il est fier de sa fille.", "Este mândru de fiica lui.",
                     note: "R-ul final se aude. La feminin: «fière».", category: "emoție"),
                card("calme", "[kalm]", "calm", "", "Reste calme, tout va bien.", "Rămâi calm, totul e bine.", category: "emoție"),
                card("peur", "[pœʁ]", "frică", "f", "J'ai peur du noir.", "Mi-e frică de întuneric.",
                     note: "Se folosește cu «avoir»: «avoir peur».", category: "emoție"),
                card("joie", "[ʒwa]", "bucurie", "f", "Quelle joie de te revoir !", "Ce bucurie să te revăd!", category: "emoție"),
                card("colère", "[kɔ.lɛʁ]", "furie", "f", "Il est en colère.", "Este furios.",
                     note: "Accent grav pe è.", category: "emoție")
            ],
            phrases: [
                phrase("Ça me fait plaisir.", "Îmi face plăcere.", "Bucurie"),
                phrase("Je suis désolé.", "Îmi pare rău.", "Scuze"),
                phrase("Ne t'inquiète pas.", "Nu-ți face griji.", "Liniștire"),
                phrase("J'ai hâte d'y être.", "Abia aștept.", "Nerăbdare")
            ],
            grammarTip: "Multe stări se exprimă cu «avoir», nu cu «être»: avoir peur, avoir faim, avoir soif, avoir froid, avoir raison. Româna spune «mi-e frică» — franceza spune «am frică».",
            culturalNote: "«Ça va ?» nu este o întrebare reală în franceza curentă: răspunsul așteptat este «ça va», chiar dacă nu merge deloc.",
            spotlight: spotlight(.plurals, "Femininele care schimbă tot",
                "Adjectivul feminin nu adaugă doar un e: «heureux» devine «heureuse», «inquiet» devine «inquiète», «fier» devine «fière».",
                [("heureuse", "heureux e"), ("inquiète", "inquiete"), ("fière", "fiere")]))
    }

    // =========================================================================
    // MARK: - 11 · Le travail
    // =========================================================================

    private static func work() -> LessonContent {
        LessonContent(
            topicSlug: "work",
            introduction: "Vocabularul profesional este aproape identic în cele două limbi — și tocmai de aceea plin de capcane. «Profesor» are doi de s în franceză, «personal» are doi de n.",
            cards: [
                card("travail", "[tʁa.vaj]", "muncă", "m", "J'aime mon travail.", "Îmi place munca mea.",
                     note: "Pluralul este «travaux», nu «travails».", category: "muncă"),
                card("bureau", "[by.ʁo]", "birou", "m", "Je vais au bureau à huit heures.", "Merg la birou la ora opt.",
                     note: "Pluralul «bureaux», cu x.", category: "muncă"),
                card("collègue", "[kɔ.lɛg]", "coleg", "m", "Mon collègue est belge.", "Colegul meu este belgian.",
                     note: "Doi de l și accent grav pe è.", category: "muncă"),
                card("réunion", "[ʁe.y.njɔ̃]", "ședință", "f", "La réunion commence à neuf heures.", "Ședința începe la ora nouă.",
                     note: "Accent ascuțit pe é.", category: "muncă"),
                card("professeur", "[pʁɔ.fe.sœʁ]", "profesor", "m", "Notre professeur est exigeant.", "Profesorul nostru este exigent.",
                     note: "Doi de s și terminația -eur, nu -or.", category: "școală"),
                card("élève", "[e.lɛv]", "elev", "m", "L'élève écoute attentivement.", "Elevul ascultă atent.",
                     note: "É ascuțit apoi è grav — două accente diferite în același cuvânt.", category: "școală"),
                card("école", "[e.kɔl]", "școală", "f", "L'école ouvre à huit heures.", "Școala se deschide la ora opt.",
                     note: "É la început — vine din «schola», unde s-ul a dispărut.", category: "școală"),
                card("examen", "[ɛg.za.mɛ̃]", "examen", "m", "J'ai réussi mon examen.", "Am reușit la examen.",
                     note: "«ex» se citește /ɛgz/ înainte de vocală.", category: "școală"),
                card("entreprise", "[ɑ̃.tʁə.pʁiz]", "firmă", "f", "Elle dirige une entreprise.", "Ea conduce o firmă.", category: "muncă"),
                card("métier", "[me.tje]", "meserie", "m", "Quel est votre métier ?", "Care este meseria dumneavoastră?",
                     note: "Accent ascuțit pe é.", category: "muncă"),
                card("personnel", "[pɛʁ.sɔ.nɛl]", "personal", "", "C'est un choix personnel.", "Este o alegere personală.",
                     note: "Doi de n: person-nel.", category: "muncă"),
                card("salaire", "[sa.lɛʁ]", "salariu", "m", "Le salaire est versé le 5.", "Salariul se virează pe 5.", category: "muncă")
            ],
            phrases: [
                phrase("Je travaille dans l'informatique.", "Lucrez în informatică.", "Prezentare profesională"),
                phrase("Je suis à la recherche d'un emploi.", "Caut un loc de muncă.", "Căutare"),
                phrase("Nous avons une réunion demain.", "Avem o ședință mâine.", "Organizare"),
                phrase("Bon courage pour ta journée !", "Spor la treabă!", "Încurajare")
            ],
            grammarTip: "Meseriile nu iau articol după «être»: «je suis professeur», nu «je suis un professeur». Cu un adjectiv, articolul revine: «je suis un bon professeur».",
            culturalNote: "«Bon courage» se spune la începutul unei zile de muncă, nu la sfârșit. La sfârșit se spune «bonne soirée».",
            spotlight: spotlight(.roTraps, "Consoanele pe care româna le-a pierdut",
                "Cuvintele savante comune celor două limbi păstrează în franceză consoana dublă latină. Româna a simplificat-o.",
                [("professeur", "profesor"), ("personnel", "personel"), ("collègue", "colegue")]))
    }

    // =========================================================================
    // MARK: - 12 · Voyager en France
    // =========================================================================

    private static func travel() -> LessonContent {
        LessonContent(
            topicSlug: "travel",
            introduction: "«Hôtel» își poartă acoperișul pentru că a fost cândva «hostel». De fiecare dată când vezi un circumflex, gândește-te la un s dispărut — și la cuvântul românesc care l-a păstrat.",
            cards: [
                card("billet", "[bi.jɛ]", "bilet", "m", "Un billet aller-retour, s'il vous plaît.", "Un bilet dus-întors, vă rog.",
                     note: "«ill» se citește /j/; t-ul final este mut.", category: "călătorie"),
                card("gare", "[gaʁ]", "gară", "f", "Rendez-vous à la gare de Lyon.", "Ne vedem la gara Lyon.", category: "călătorie"),
                card("avion", "[a.vjɔ̃]", "avion", "m", "L'avion décolle à midi.", "Avionul decolează la prânz.", category: "călătorie"),
                card("valise", "[va.liz]", "valiză", "f", "Ma valise est trop lourde.", "Valiza mea este prea grea.",
                     note: "Un singur s, citit /z/ între vocale.", category: "călătorie"),
                card("hôtel", "[o.tɛl]", "hotel", "m", "L'hôtel est près de la gare.", "Hotelul este aproape de gară.",
                     note: "Circumflex pe ô — a fost «hostel». H mut, deci «l'hôtel».", category: "călătorie"),
                card("séjour", "[se.ʒuʁ]", "sejur", "m", "Bon séjour en France !", "Sejur plăcut în Franța!",
                     note: "Accent ascuțit pe é.", category: "călătorie"),
                card("voyage", "[vwa.jaʒ]", "călătorie", "m", "Un voyage inoubliable.", "O călătorie de neuitat.",
                     note: "Masculin în franceză, deși «călătoria» e feminin în română.", category: "călătorie"),
                card("aéroport", "[a.e.ʁɔ.pɔʁ]", "aeroport", "m", "L'aéroport est loin du centre.", "Aeroportul este departe de centru.",
                     note: "Accent ascuțit pe é; t-ul final este mut.", category: "călătorie"),
                card("quai", "[kɛ]", "peron", "m", "Le train part du quai numéro trois.", "Trenul pleacă de la peronul trei.",
                     note: "«qu» = /k/, «ai» = /ɛ/.", category: "călătorie"),
                card("retard", "[ʁə.taʁ]", "întârziere", "m", "Le train a vingt minutes de retard.", "Trenul are douăzeci de minute întârziere.",
                     note: "D final mut; «retarder» îl face să se audă.", category: "călătorie"),
                card("île", "[il]", "insulă", "f", "Nous partons sur une île bretonne.", "Plecăm pe o insulă bretonă.",
                     note: "Circumflex pe î — «insulă» a păstrat s-ul, franceza nu.", category: "călătorie"),
                card("forêt", "[fɔ.ʁɛ]", "pădure", "f", "Une promenade en forêt.", "O plimbare în pădure.",
                     note: "Circumflex pe ê — compară cu englezescul «forest».", category: "natură")
            ],
            phrases: [
                phrase("À quelle heure part le train ?", "La ce oră pleacă trenul?", "Informație"),
                phrase("J'ai réservé une chambre.", "Am rezervat o cameră.", "Hotel"),
                phrase("Où est la sortie ?", "Unde este ieșirea?", "Orientare"),
                phrase("Le vol a été annulé.", "Zborul a fost anulat.", "Problemă")
            ],
            grammarTip: "Numele de țări feminine cer «en»: «en France», «en Roumanie». Cele masculine cer «au»: «au Canada», «au Portugal». Orașele cer «à»: «à Paris», «à Bucarest».",
            culturalNote: "În trenurile franceze, «composter» însemna odinioară să îți validezi biletul într-o mașină galbenă. Obiceiul a dispărut, cuvântul a rămas în vorbire.",
            spotlight: spotlight(.roTraps, "S-ul românesc, acoperișul francez",
                "Fereastră → fenêtre. Spital → hôpital. Insulă → île. Coastă → côte. O singură regulă acoperă zeci de cuvinte.",
                [("hôtel", "hotel"), ("île", "ile"), ("forêt", "foret")]))
    }

    // =========================================================================
    // MARK: - 13 · La culture
    // =========================================================================

    private static func culture() -> LessonContent {
        LessonContent(
            topicSlug: "culture",
            introduction: "Cuvintele culturii vin din greacă și își păstrează literele savante: théâtre, rythme, poésie. Româna le-a simplificat; franceza le-a păstrat intacte.",
            cards: [
                card("livre", "[livʁ]", "carte", "m", "Un livre que je relis souvent.", "O carte pe care o recitesc des.",
                     note: "MASCULIN în franceză, deși «cartea» e feminin în română.", category: "cultură"),
                card("roman", "[ʁɔ.mɑ̃]", "roman", "m", "Un roman de Camus.", "Un roman de Camus.", category: "cultură"),
                card("peinture", "[pɛ̃.tyʁ]", "pictură", "f", "La peinture impressionniste.", "Pictura impresionistă.", category: "cultură"),
                card("musée", "[my.ze]", "muzeu", "m", "Le musée d'Orsay ouvre à neuf heures.", "Muzeul d'Orsay se deschide la nouă.",
                     note: "Accent ascuțit pe é, deși e masculin.", category: "cultură"),
                card("chanson", "[ʃɑ̃.sɔ̃]", "cântec", "f", "Une chanson de Brel.", "Un cântec de Brel.",
                     note: "Feminin în franceză.", category: "cultură"),
                card("cinéma", "[si.ne.ma]", "cinema", "m", "On va au cinéma ce soir ?", "Mergem la cinema diseară?",
                     note: "Accent ascuțit pe é.", category: "cultură"),
                card("théâtre", "[te.ɑtʁ]", "teatru", "m", "Le théâtre de l'Odéon.", "Teatrul Odéon.",
                     note: "Trei semne: th, é și â. Româna scrie simplu «teatru».", category: "cultură"),
                card("poésie", "[pɔ.e.zi]", "poezie", "f", "La poésie de Rimbaud.", "Poezia lui Rimbaud.",
                     note: "Accent ascuțit pe é.", category: "cultură"),
                card("siècle", "[sjɛkl]", "secol", "m", "Au dix-neuvième siècle.", "În secolul al nouăsprezecelea.",
                     note: "Accent grav pe è.", category: "cultură"),
                card("écrivain", "[e.kʁi.vɛ̃]", "scriitor", "m", "Un écrivain roumain de Paris.", "Un scriitor român din Paris.",
                     note: "«ain» nazal la final.", category: "cultură"),
                card("sculpture", "[skyl.tyʁ]", "sculptură", "f", "Les sculptures de Brancusi.", "Sculpturile lui Brâncuși.", category: "cultură"),
                card("rythme", "[ʁitm]", "ritm", "m", "Le rythme de la phrase.", "Ritmul frazei.",
                     note: "y și th: ry-thme. Româna scrie «ritm».", category: "cultură")
            ],
            phrases: [
                phrase("Qu'est-ce que tu lis en ce moment ?", "Ce citești în momentul ăsta?", "Conversație"),
                phrase("C'est un chef-d'œuvre.", "Este o capodoperă.", "Apreciere"),
                phrase("L'exposition dure jusqu'en mai.", "Expoziția durează până în mai.", "Informație"),
                phrase("Je préfère la version originale.", "Prefer versiunea originală.", "Cinema")
            ],
            grammarTip: "Titlurile de opere iau majusculă doar la primul cuvânt și la numele proprii: «Le rouge et le noir», «À la recherche du temps perdu».",
            culturalNote: "Constantin Brâncuși a plecat din Hobița pe jos și a ajuns la Paris în 1904. Atelierul lui, reconstituit, se vizitează gratuit lângă Centre Pompidou.",
            spotlight: spotlight(.roTraps, "Literele savante",
                "Cuvintele venite din greacă păstrează în franceză ph, th, ch și y. Româna le-a transcris fonetic.",
                [("théâtre", "teatre"), ("rythme", "ritme"), ("poésie", "poezie")]))
    }

    // =========================================================================
    // MARK: - 14 · Écrire sans fautes
    // =========================================================================

    private static func writing() -> LessonContent {
        LessonContent(
            topicSlug: "writing",
            introduction: "Ultima lecție nu adaugă vocabular: pune la treabă tot ce ai învățat. Un e-mail profesional, o scrisoare, un text — și fiecare regulă la locul ei.",
            cards: [
                card("lettre", "[lɛtʁ]", "scrisoare, literă", "f", "J'ai reçu votre lettre.", "Am primit scrisoarea dumneavoastră.",
                     note: "Doi de t. Înseamnă și «literă».", category: "scris"),
                card("courriel", "[ku.ʁjɛl]", "e-mail", "m", "Je vous envoie un courriel.", "Vă trimit un e-mail.",
                     note: "Doi de r. Termenul oficial; în vorbire se spune «mail».", category: "scris"),
                card("phrase", "[fʁɑz]", "frază", "f", "Une phrase bien construite.", "O frază bine construită.",
                     note: "ph la început, ca în «pharmacie».", category: "scris"),
                card("paragraphe", "[pa.ʁa.gʁaf]", "paragraf", "m", "Trois paragraphes suffisent.", "Trei paragrafe sunt de ajuns.",
                     note: "ph la final: para-graphe.", category: "scris"),
                card("brouillon", "[bʁu.jɔ̃]", "ciornă", "m", "Fais d'abord un brouillon.", "Fă mai întâi o ciornă.",
                     note: "«ill» se citește /j/.", category: "scris"),
                card("orthographe", "[ɔʁ.tɔ.gʁaf]", "ortografie", "f", "Soigne ton orthographe.", "Ai grijă la ortografie.",
                     note: "Două grupuri savante: th și ph. Feminin în franceză.", category: "scris"),
                card("majuscule", "[ma.ʒys.kyl]", "majusculă", "f", "Une majuscule après le point.", "Majusculă după punct.", category: "scris"),
                card("virgule", "[viʁ.gyl]", "virgulă", "f", "N'oublie pas la virgule.", "Nu uita virgula.", category: "scris"),
                card("accent", "[ak.sɑ̃]", "accent", "m", "L'accent change le sens.", "Accentul schimbă sensul.",
                     note: "T-ul final este mut.", category: "scris"),
                card("signature", "[si.ɲa.tyʁ]", "semnătură", "f", "Votre signature, s'il vous plaît.", "Semnătura dumneavoastră, vă rog.",
                     note: "«gn» se citește /ɲ/.", category: "scris"),
                card("relire", "[ʁə.liʁ]", "a reciti", "", "Relis-toi avant d'envoyer.", "Recitește-te înainte de a trimite.",
                     note: "Sfatul cel mai util al acestei lecții.", category: "scris"),
                card("faute", "[fot]", "greșeală", "f", "Une faute d'accord.", "O greșeală de acord.",
                     note: "«au» se citește /o/.", category: "scris")
            ],
            phrases: [
                phrase("Je vous prie d'agréer mes salutations distinguées.", "Vă rog să primiți salutările mele distinse.", "Formulă de încheiere formală"),
                phrase("Cordialement,", "Cu stimă,", "Încheiere curentă"),
                phrase("Suite à votre message…", "Ca urmare a mesajului dumneavoastră…", "Deschidere"),
                phrase("Dans l'attente de votre réponse.", "În așteptarea răspunsului dumneavoastră.", "Încheiere")
            ],
            grammarTip: "În franceză se pune un spațiu ÎNAINTEA semnelor duble: « ; », « : », « ! », « ? ». Româna nu o face. Este detaliul care trădează imediat un text scris de un străin.",
            culturalNote: "Formulele de politețe franceze la sfârșitul unei scrisori sunt lungi și codificate. «Cordialement» este acceptabil aproape peste tot; «Bien à vous» este mai cald.",
            spotlight: spotlight(.agreements, "Recitește-te",
                "Nouă din zece greșeli de acord se văd la recitire. Caută subiectul fiecărui verb, apoi complementul fiecărui participiu.",
                [("Les lettres que j'ai écrites", "Les lettres que j'ai écrit"),
                 ("Elles sont venues", "Elles sont venu"),
                 ("Je vous prie d'agréer", "Je vous prie d'agréez")]))
    }

    // =========================================================================
    // MARK: - Fabriques
    // =========================================================================

    private static func card(_ french: String, _ ipa: String, _ translation: String,
                             _ gender: String, _ example: String, _ exampleTranslation: String,
                             note: String? = nil, category: String) -> VocabCard {
        VocabCard(french: french, phonetic: ipa, translation: translation, gender: gender,
                  exampleSentence: example, exampleTranslation: exampleTranslation,
                  spellingNote: note, category: category)
    }

    private static func phrase(_ french: String, _ translation: String,
                               _ context: String) -> LessonContent.Phrase {
        LessonContent.Phrase(french: french, translation: translation, context: context)
    }

    private static func spotlight(_ module: OrthoModule, _ title: String, _ rule: String,
                                  _ pairs: [(String, String)]) -> LessonContent.OrthoSpotlight {
        LessonContent.OrthoSpotlight(
            module: module, title: title, rule: rule,
            rightWrong: pairs.map { .init(right: $0.0, wrong: $0.1) })
    }
}
