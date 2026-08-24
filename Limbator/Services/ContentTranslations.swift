import Foundation

/// Traduit le CONTENU pédagogique.
///
/// Les leçons, règles et exercices de Limbator sont écrits en roumain — la
/// langue de l'apprenant visé. Quand l'utilisateur choisit une autre langue
/// d'interface, cette couche traduit ce qui structure l'écran : noms de
/// modules, de niveaux, de thèmes, d'histoires, de jeux, d'insignes, catégories
/// de fautes, titres de règles, natures grammaticales.
///
/// Les textes longs (énoncés de règles, explications d'exercices, indices de
/// dictée) restent en roumain hors de cette table : le repli rend la chaîne
/// source telle quelle, donc rien ne disparaît de l'écran.
///
/// FICHIER GÉNÉRÉ — ne pas modifier à la main.
/// Source : scripts/gen_content_l10n.py  ·  Régénérer : python3 scripts/gen_content_l10n.py
enum ContentL10n {

    /// Traduit une chaîne source roumaine vers la langue courante.
    static func s(_ ro: String) -> String {
        switch L.lang {
        case "ro": return ro
        case "fr": return table[ro]?.fr ?? ro
        case "en": return table[ro]?.en ?? ro
        // Les langues romanes proches lisent mieux le français que l'anglais.
        case "it", "es", "pt": return table[ro]?.fr ?? ro
        default:   return table[ro]?.en ?? ro
        }
    }

    /// Nombre d'entrées — utilisé par les tests de couverture.
    static var entryCount: Int { table.count }

    // MARK: - Consignes interpolées
    //
    // Ces libellés portent une valeur variable : ils ne peuvent pas passer par
    // la table, qui indexe des chaînes entières.

    static func matchPrompt(_ word: String) -> String {
        switch L.lang {
        case "fr": return "Que veut dire « \(word) » ?"
        case "en": return "What does “\(word)” mean?"
        default:   return "Ce înseamnă « \(word) »?"
        }
    }

    static func listeningPrompt() -> String {
        switch L.lang {
        case "fr": return "Qu'est-ce que tu viens d'entendre ?"
        case "en": return "What did you just hear?"
        default:   return "Ce tocmai ai auzit?"
        }
    }

    static func translationPrompt(_ word: String) -> String {
        switch L.lang {
        case "fr": return "Choisis la traduction de « \(word) »"
        case "en": return "Choose the translation of “\(word)”"
        default:   return "Alege traducerea pentru « \(word) »"
        }
    }

    static func spellPrompt(_ word: String) -> String {
        switch L.lang {
        case "fr": return "Comment s'écrit ce mot ?"
        case "en": return "How is this word spelled?"
        default:   return "Cum se scrie acest cuvânt?"
        }
    }

    static func accentPrompt() -> String {
        switch L.lang {
        case "fr": return "Où vont les accents ?"
        case "en": return "Where do the accents go?"
        default:   return "Unde se pun accentele?"
        }
    }


    // MARK: - Table roumain -> (français, anglais)

    static let table: [String: (fr: String, en: String)] = [
        "Accente": ("Accents", "Accents"),
        "Homofone": ("Homophones", "Homophones"),
        "Terminații verbale": ("Terminaisons verbales", "Verb endings"),
        "Acorduri": ("Accords", "Agreement"),
        "Plurale și feminine": ("Pluriels et féminins", "Plurals and feminines"),
        "Consoane duble": ("Consonnes doubles", "Double consonants"),
        "Litere mute": ("Lettres muettes", "Silent letters"),
        "Capcane româno-franceze": ("Pièges roumain / français", "Romanian–French traps"),
        "é è ê ë à â î ï ô û ç — unde și de ce": ("é è ê ë à â î ï ô û ç — où et pourquoi", "é è ê ë à â î ï ô û ç — where and why"),
        "a / à, ou / où, c'est / s'est, ces / ses": ("a / à, ou / où, c'est / s'est, ces / ses", "a / à, ou / où, c'est / s'est, ces / ses"),
        "-é, -er, -ez : testul cu «vendre»": ("-é, -er, -ez : le test de « vendre »", "-é, -er, -ez: the “vendre” test"),
        "Participiul trecut cu être și avoir": ("Le participe passé avec être et avoir", "The past participle with être and avoir"),
        "-al → -aux, bijou, caillou, chou…": ("-al → -aux, bijou, caillou, chou…", "-al → -aux, bijou, caillou, chou…"),
        "appeler, adresse, attention": ("appeler, adresse, attention", "appeler, adresse, attention"),
        "petit, grand, temps — și h mut": ("petit, grand, temps — et le h muet", "petit, grand, temps — and the mute h"),
        "fereastră → fenêtre : S-ul devine accent": ("« fereastră » → « fenêtre » : le S devient accent", "“fereastră” → “fenêtre”: the S becomes an accent"),
        "Începător": ("Débutant", "Beginner"),
        "Elementar": ("Élémentaire", "Elementary"),
        "Intermediar": ("Intermédiaire", "Intermediate"),
        "Avansat": ("Avancé", "Advanced"),
        "Autonom": ("Autonome", "Autonomous"),
        "Măiestrie": ("Maîtrise", "Mastery"),
        "Primele cuvinte și expresii": ("Les premiers mots et expressions", "First words and phrases"),
        "Conversații simple, prezentul": ("Conversations simples, le présent", "Simple conversations, the present"),
        "Trecutul, acordurile de bază": ("Le passé, les accords de base", "The past, basic agreement"),
        "Subjonctiv, nuanțe, texte lungi": ("Subjonctif, nuances, textes longs", "Subjunctive, nuance, long texts"),
        "Ortografie fără ezitare": ("Une orthographe sans hésitation", "Spelling without hesitation"),
        "Nivel de redactor francez": ("Niveau rédacteur francophone", "French copy-editor level"),
        "Salutări și prezentare": ("Salutations et présentations", "Greetings and introductions"),
        "Numere și cifre": ("Les nombres", "Numbers"),
        "Familia": ("La famille", "Family"),
        "Mâncare și băutură": ("Manger et boire", "Food and drink"),
        "Orașul și direcțiile": ("La ville et les directions", "The city and directions"),
        "Cumpărături": ("Les courses", "Shopping"),
        "Vremea și anotimpurile": ("Le temps et les saisons", "Weather and seasons"),
        "Verbe la prezent": ("Les verbes au présent", "Verbs in the present"),
        "Trecutul și acordurile": ("Le passé et les accords", "The past and agreement"),
        "Emoții și sentimente": ("Les émotions", "Emotions"),
        "Munca și școala": ("Le travail et les études", "Work and study"),
        "Călătorii în Franța": ("Voyager en France", "Travelling in France"),
        "Cultură franceză": ("La culture française", "French culture"),
        "Scrisul îngrijit": ("Écrire sans fautes", "Writing without mistakes"),
        "Bonjour, enchanté, je m'appelle… și accentul din «enchanté»": ("Bonjour, enchanté, je m'appelle… et l'accent d'« enchanté »", "Bonjour, enchanté, je m'appelle… and the accent in “enchanté”"),
        "De la zéro la mille — și celebrul «quatre-vingts» cu s": ("De zéro à mille — et le fameux « quatre-vingts » avec s", "From zéro to mille — and the famous “quatre-vingts” with its s"),
        "Membrii familiei, posesivele mon/ma/mes": ("Les membres de la famille, mon / ma / mes", "Family members, mon / ma / mes"),
        "Pain, fromage, café — și articolele partitive du/de la": ("Pain, fromage, café — et les partitifs du / de la", "Pain, fromage, café — and the partitives du / de la"),
        "Rue, boulevard, à gauche, tout droit — și «à» cu accent grav": ("Rue, boulevard, à gauche, tout droit — et le « à » accent grave", "Rue, boulevard, à gauche, tout droit — and “à” with its grave accent"),
        "Prețuri, mărimi, «combien ça coûte ?» — și circonflexul din coûter": ("Prix, tailles, « combien ça coûte ? » — et le circonflexe de coûter", "Prices, sizes, “combien ça coûte?” — and the circumflex in coûter"),
        "Il fait beau, il pleut, l'été — și expresiile impersonale": ("Il fait beau, il pleut, l'été — et les tournures impersonnelles", "Il fait beau, il pleut, l'été — and impersonal turns of phrase"),
        "être, avoir, aller, faire — și terminația «-ent» care nu se aude": ("être, avoir, aller, faire — et la terminaison « -ent » qu'on n'entend pas", "être, avoir, aller, faire — and the “-ent” you never hear"),
        "être ou avoir ? Și acordul participiului — inima ortografiei": ("être ou avoir ? Et l'accord du participe — le cœur de l'orthographe", "être or avoir? And participle agreement — the heart of French spelling"),
        "Heureux, inquiet, ému — și femininele neregulate": ("Heureux, inquiet, ému — et les féminins irréguliers", "Heureux, inquiet, ému — and irregular feminines"),
        "Métiers, bureau, entretien — și dublele consoane din «professionnel»": ("Métiers, bureau, entretien — et les doubles consonnes de « professionnel »", "Métiers, bureau, entretien — and the double letters in “professionnel”"),
        "Gare, billet, hôtel — și circonflexul care ascunde un S": ("Gare, billet, hôtel — et le circonflexe qui cache un S", "Gare, billet, hôtel — and the circumflex hiding an S"),
        "Literatură, cinema, gastronomie — și numele proprii": ("Littérature, cinéma, gastronomie — et les noms propres", "Literature, cinema, gastronomy — and proper nouns"),
        "E-mail, scrisoare, eseu — toate regulile puse la treabă": ("E-mail, lettre, essai — toutes les règles à l'œuvre", "Email, letter, essay — every rule at work"),
        "Scrisoarea lui Brâncuși": ("La lettre de Brancusi", "Brancusi's letter"),
        "Bilet dus spre Paris": ("Un aller simple pour Paris", "A one-way ticket to Paris"),
        "Secretul Loarei": ("Le secret de la Loire", "The secret of the Loire"),
        "Noapte albă la Montmartre": ("Nuit blanche à Montmartre", "A sleepless night in Montmartre"),
        "Un tânăr sculptor din Hobița ajunge la Paris pe jos. Atelierul din Impasse Ronsin, marmura, tăcerea — și primele lui cuvinte în franceză.": ("Un jeune sculpteur de Hobița arrive à Paris à pied. L'atelier de l'impasse Ronsin, le marbre, le silence — et ses premiers mots de français.", "A young sculptor from Hobița walks to Paris. The studio on impasse Ronsin, the marble, the silence — and his first words of French."),
        "Ioana coboară în Gare du Nord cu două valize și un dicționar. Prima zi, prima cafea, primul formular de completat — corect.": ("Ioana descend à la gare du Nord avec deux valises et un dictionnaire. Premier jour, premier café, premier formulaire à remplir — correctement.", "Ioana steps off at Gare du Nord with two suitcases and a dictionary. First day, first coffee, first form to fill in — correctly."),
        "Un castel, o fereastră care nu se închide niciodată și un cuvânt cu accent circonflex care ascunde o literă dispărută.": ("Un château, une fenêtre qui ne se ferme jamais, et un mot à accent circonflexe qui cache une lettre disparue.", "A château, a window that never shuts, and a circumflexed word hiding a vanished letter."),
        "Doi prieteni, o scară de o sută de trepte și o noapte în care fiecare accent contează.": ("Deux amis, un escalier de cent marches, et une nuit où chaque accent compte.", "Two friends, a hundred-step staircase, and a night where every accent counts."),
        "Drumul pe jos": ("La longue marche", "The long walk"),
        "Atelierul alb": ("L'atelier blanc", "The white studio"),
        "Pasărea": ("L'oiseau", "The bird"),
        "Scrisoarea acasă": ("La lettre au pays", "The letter home"),
        "Gara de Nord": ("Gare du Nord", "Gare du Nord"),
        "Formularul": ("Le formulaire", "The form"),
        "Cafeaua de dimineață": ("Le café du matin", "The morning coffee"),
        "Vecinul de palier": ("Le voisin de palier", "The neighbour across the hall"),
        "Fereastra deschisă": ("La fenêtre ouverte", "The open window"),
        "Pădurea": ("La forêt", "The forest"),
        "Litera dispărută": ("La lettre disparue", "The vanished letter"),
        "Scara": ("L'escalier", "The staircase"),
        "Portretistul": ("Le portraitiste", "The portraitist"),
        "Zorii": ("L'aube", "Dawn"),
        "Perechi": ("Paires", "Pairs"),
        "Construiește fraza": ("Construis la phrase", "Build the sentence"),
        "Ureche fină": ("Oreille fine", "Sharp ear"),
        "Studio vocal": ("Studio vocal", "Voice studio"),
        "Flash memorie": ("Flash mémoire", "Memory flash"),
        "Alege-ți drumul": ("Choisis ton chemin", "Choose your path"),
        "Roata Parisului": ("La roue de Paris", "The Paris wheel"),
        "Dictare fulger": ("Dictée éclair", "Lightning dictation"),
        "Vânătoare de accente": ("Chasse aux accents", "Accent hunt"),
        "Duel de homofone": ("Duel d'homophones", "Homophone duel"),
        "Leagă franceza de română": ("Relie le français au roumain", "Match French to Romanian"),
        "Pune cuvintele în ordine": ("Remets les mots dans l'ordre", "Put the words in order"),
        "Recunoaște ce auzi": ("Reconnais ce que tu entends", "Recognise what you hear"),
        "Pronunția ta, notată de IA": ("Ta prononciation, notée par l'IA", "Your pronunciation, scored by AI"),
        "Trei secunde per carte": ("Trois secondes par carte", "Three seconds per card"),
        "O scenă, mai multe căi": ("Une scène, plusieurs chemins", "One scene, several paths"),
        "Norocul îți alege proba": ("Le hasard choisit ton épreuve", "Chance picks your challenge"),
        "Scrie exact ce auzi": ("Écris exactement ce que tu entends", "Write exactly what you hear"),
        "Pune accentele la locul lor": ("Mets les accents à leur place", "Put the accents where they belong"),
        "a sau à ? ce sau se ?": ("a ou à ? ce ou se ?", "a or à? ce or se?"),
        "Primul tău cuvânt franțuzesc": ("Ton premier mot français", "Your first French word"),
        "Trei zile la rând": ("Trois jours d'affilée", "Three days in a row"),
        "Șapte zile la rând": ("Sept jours d'affilée", "Seven days in a row"),
        "Treizeci de zile la rând": ("Trente jours d'affilée", "Thirty days in a row"),
        "Ai terminat prima dictare": ("Tu as terminé ta première dictée", "You finished your first dictation"),
        "O dictare fără nicio greșeală": ("Une dictée sans la moindre faute", "A dictation without a single mistake"),
        "Zece dictări terminate": ("Dix dictées terminées", "Ten dictations completed"),
        "Modulul de accente stăpânit": ("Le module des accents maîtrisé", "The accents module mastered"),
        "Modulul de homofone stăpânit": ("Le module des homophones maîtrisé", "The homophones module mastered"),
        "Acordul participiului stăpânit": ("L'accord du participe maîtrisé", "Participle agreement mastered"),
        "Prima poveste terminată": ("Première histoire terminée", "First story finished"),
        "Povestea lui Brâncuși, citită până la capăt": ("L'histoire de Brancusi, lue jusqu'au bout", "Brancusi's story, read to the end"),
        "100% la un mini-joc": ("100 % à un mini-jeu", "100% on a mini-game"),
        "O sută de cuvinte stăpânite": ("Cent mots maîtrisés", "A hundred words mastered"),
        "Obișnuit": ("Commun", "Common"),
        "Rar": ("Rare", "Rare"),
        "Epic": ("Épique", "Epic"),
        "Legendar": ("Légendaire", "Legendary"),
        "Accent lipsă": ("Accent manquant", "Missing accent"),
        "Accent greșit": ("Mauvais accent", "Wrong accent"),
        "Accent în plus": ("Accent en trop", "Extra accent"),
        "Sedilă lipsă (ç)": ("Cédille manquante (ç)", "Missing cedilla (ç)"),
        "Sedilă în plus": ("Cédille en trop", "Extra cedilla"),
        "Tremă lipsă (ë ï ü)": ("Tréma manquant (ë ï ü)", "Missing diaeresis (ë ï ü)"),
        "Consoană dublă": ("Consonne double", "Double consonant"),
        "Literă mută": ("Lettre muette", "Silent letter"),
        "Homofon": ("Homophone", "Homophone"),
        "Terminație verbală": ("Terminaison verbale", "Verb ending"),
        "Acord": ("Accord", "Agreement"),
        "Eliziune (l')": ("Élision (l')", "Elision (l')"),
        "Apostrof": ("Apostrophe", "Apostrophe"),
        "Cratimă": ("Trait d'union", "Hyphen"),
        "Ligatură (œ æ)": ("Ligature (œ æ)", "Ligature (œ æ)"),
        "Majusculă": ("Majuscule", "Capital letter"),
        "Punctuație": ("Ponctuation", "Punctuation"),
        "Spațiere": ("Espacement", "Spacing"),
        "Influență din română": ("Influence du roumain", "Romanian interference"),
        "Ordinea cuvintelor": ("Ordre des mots", "Word order"),
        "Cuvânt lipsă": ("Mot manquant", "Missing word"),
        "Cuvânt în plus": ("Mot en trop", "Extra word"),
        "Greșeală de tastare": ("Faute de frappe", "Typo"),
        "é sau è ?": ("é ou è ?", "é or è?"),
        "Când e-ul NU poartă accent": ("Quand le e ne prend PAS d'accent", "When e takes NO accent"),
        "Sedila (ç)": ("La cédille (ç)", "The cedilla (ç)"),
        "Trema (ë, ï, ü)": ("Le tréma (ë, ï, ü)", "The diaeresis (ë, ï, ü)"),
        "Accentul circumflex": ("L'accent circonflexe", "The circumflex"),
        "Accentele pe majuscule": ("Les accents sur les majuscules", "Accents on capitals"),
        "-er, -é sau -ez ?": ("-er, -é ou -ez ?", "-er, -é or -ez?"),
        "-ent care nu se aude": ("Le -ent qu'on n'entend pas", "The -ent you never hear"),
        "-ais, -ait, -aient": ("-ais, -ait, -aient", "-ais, -ait, -aient"),
        "-rai sau -rais ?": ("-rai ou -rais ?", "-rai or -rais?"),
        "Participiul cu «être»": ("Le participe avec « être »", "The participle with “être”"),
        "Participiul cu «avoir»": ("Le participe avec « avoir »", "The participle with “avoir”"),
        "Verbele pronominale": ("Les verbes pronominaux", "Pronominal verbs"),
        "Acordul adjectivului": ("L'accord de l'adjectif", "Adjective agreement"),
        "-al devine -aux": ("-al devient -aux", "-al becomes -aux"),
        "-ou face -ous, cu șapte excepții": ("-ou fait -ous, avec sept exceptions", "-ou takes -ous, with seven exceptions"),
        "-au, -eau, -eu primesc x": ("-au, -eau, -eu prennent un x", "-au, -eau, -eu take an x"),
        "-ail face -ails, cu șapte excepții": ("-ail fait -ails, avec sept exceptions", "-ail takes -ails, with seven exceptions"),
        "vingt, cent, mille": ("vingt, cent, mille", "vingt, cent, mille"),
        "De ce dublează franceza": ("Pourquoi le français double", "Why French doubles letters"),
        "appeler / jeter: dublarea la conjugare": ("appeler / jeter : le doublement en conjugaison", "appeler / jeter: doubling in conjugation"),
        "Litera finală care nu se aude": ("La lettre finale qu'on n'entend pas", "The final letter you never hear"),
        "h mut și h aspirat": ("h muet et h aspiré", "mute h and aspirate h"),
        "Legătura (la liaison)": ("La liaison", "Liaison"),
        "Unde româna are S, franceza are accent": ("Là où le roumain a un S, le français a un accent", "Where Romanian has an S, French has an accent"),
        "Consoanele pe care româna le-a simplificat": ("Les consonnes que le roumain a simplifiées", "The consonants Romanian simplified"),
        "ph, th, ch, y: literele savante": ("ph, th, ch, y : les lettres savantes", "ph, th, ch, y: the learned letters"),
        "Genurile care nu se potrivesc": ("Les genres qui ne concordent pas", "Genders that don't match"),
        "Vezi un S în românește? Pune un acoperiș în franceză.": ("Un S en roumain ? Un accent circonflexe en français.", "An S in Romanian? A circumflex in French."),
        "Circumflexul este piatra funerară a unui s.": ("Le circonflexe est la pierre tombale d'un s.", "The circumflex is the tombstone of an s."),
        "A, O, U cer sedila. E, I, Y o refuză.": ("A, O, U appellent la cédille. E, I, Y la refusent.", "A, O, U call for the cedilla. E, I, Y refuse it."),
        "Trema desparte. Fără ea, vocalele se lipesc.": ("Le tréma sépare. Sans lui, les voyelles se collent.", "The diaeresis separates. Without it, the vowels stick together."),
        "«Vendre» sau «vendu» ? Verbul de control al întregii limbi franceze.": ("« Vendre » ou « vendu » ? Le verbe témoin de toute la langue française.", "“Vendre” or “vendu”? The one verb that settles it all."),
        "Nu-l auzi niciodată, îl scrii de fiecare dată.": ("Tu ne l'entends jamais, tu l'écris à chaque fois.", "You never hear it, you write it every time."),
        "«Être» privește subiectul. Mereu.": ("« Être » regarde le sujet. Toujours.", "“Être” looks at the subject. Always."),
        "Caută complementul direct. Dacă e în fața verbului, acorzi.": ("Cherche le complément direct. S'il est devant, tu accordes.", "Find the direct object. If it comes first, you agree."),
        "Culorile care sunt și fructe nu se acordă.": ("Les couleurs qui sont aussi des fruits ne s'accordent pas.", "Colours that are also fruit don't agree."),
        "Majuscula nu scutește de accent.": ("La majuscule ne dispense pas de l'accent.", "A capital letter is no excuse to drop the accent."),
        "Dacă româna are o consoană, franceza are adesea două.": ("Si le roumain a une consonne, le français en a souvent deux.", "Where Romanian has one consonant, French often has two."),
        "Caută ruda cuvântului: ea îți arată litera ascunsă.": ("Cherche un mot de la même famille : il révèle la lettre cachée.", "Find a related word: it reveals the hidden letter."),
        "«et» nu leagă niciodată.": ("« et » ne fait jamais la liaison.", "“et” never liaises."),
        "verbul «avoir», persoana a III-a singular": ("le verbe « avoir », 3e personne du singulier", "the verb “avoir”, third person singular"),
        "prepoziție (la, spre, în)": ("préposition (à, vers, dans)", "preposition (to, towards, in)"),
        "conjuncție (sau)": ("conjonction (ou bien)", "conjunction (or)"),
        "adverb de loc sau de timp (unde)": ("adverbe de lieu ou de temps (où)", "adverb of place or time (where)"),
        "conjuncție (și)": ("conjonction (et)", "conjunction (and)"),
        "verbul «être», persoana a III-a singular": ("le verbe « être », 3e personne du singulier", "the verb “être”, third person singular"),
        "adjectiv posesiv (al său)": ("adjectif possessif (son)", "possessive adjective (his/her)"),
        "verbul «être», persoana a III-a plural": ("le verbe « être », 3e personne du pluriel", "the verb “être”, third person plural"),
        "pronume subiect (se, noi, cineva)": ("pronom sujet (on)", "subject pronoun (one, we, someone)"),
        "verbul «avoir», persoana a III-a plural": ("le verbe « avoir », 3e personne du pluriel", "the verb “avoir”, third person plural"),
        "determinant sau pronume demonstrativ": ("déterminant ou pronom démonstratif", "demonstrative determiner or pronoun"),
        "pronume reflexiv, mereu lângă un verb": ("pronom réfléchi, toujours devant un verbe", "reflexive pronoun, always before a verb"),
        "determinant demonstrativ plural (aceste)": ("déterminant démonstratif pluriel (ces)", "plural demonstrative determiner (these)"),
        "determinant posesiv plural (ale sale)": ("déterminant possessif pluriel (ses)", "plural possessive determiner (his/her)"),
        "«cela este» — prezentare": ("« cela est » — présentatif", "“cela est” — presentative"),
        "pronume reflexiv + «être», urmat de participiu": ("pronom réfléchi + « être », suivi d'un participe", "reflexive pronoun + “être”, followed by a participle"),
        "verbul «savoir», je / tu": ("le verbe « savoir », je / tu", "the verb “savoir”, je / tu"),
        "verbul «savoir», il / elle / on": ("le verbe « savoir », il / elle / on", "the verb “savoir”, il / elle / on"),
        "articol hotărât sau pronume complement": ("article défini ou pronom complément", "definite article or object pronoun"),
        "adverb de loc (acolo)": ("adverbe de lieu (là)", "adverb of place (there)"),
        "pronume + verbul «avoir»": ("pronom + verbe « avoir »", "pronoun + the verb “avoir”"),
        "conjuncție (dar)": ("conjonction (mais)", "conjunction (but)"),
        "determinant posesiv plural (ai mei)": ("déterminant possessif pluriel (mes)", "plural possessive determiner (my)"),
        "verbul «mettre», il / elle": ("le verbe « mettre », il / elle", "the verb “mettre”, il / elle"),
        "verbul «mettre», je / tu": ("le verbe « mettre », je / tu", "the verb “mettre”, je / tu"),
        "numele lunii mai": ("le nom du mois de mai", "the name of the month of May"),
        "adverb de cantitate (puțin)": ("adverbe de quantité (peu)", "adverb of quantity (little)"),
        "verbul «pouvoir», il / elle / on": ("le verbe « pouvoir », il / elle / on", "the verb “pouvoir”, il / elle / on"),
        "verbul «pouvoir», je / tu": ("le verbe « pouvoir », je / tu", "the verb “pouvoir”, je / tu"),
        "conjuncție de timp (când)": ("conjonction de temps (quand)", "time conjunction (when)"),
        "apare doar în «quant à» (cât despre)": ("n'apparaît que dans « quant à »", "appears only in “quant à”"),
        "«que» + «en»": ("« que » + « en »", "“que” + “en”"),
        "adverb sau prepoziție (aproape)": ("adverbe ou préposition (près)", "adverb or preposition (near)"),
        "adjectiv (gata, pregătit)": ("adjectif (prêt)", "adjective (ready)"),
        "pronume complement, invariabil, înainte de verb": ("pronom complément, invariable, devant le verbe", "object pronoun, invariable, before the verb"),
        "determinant posesiv plural": ("déterminant possessif pluriel", "plural possessive determiner"),
        "adjectiv sau adverb, masculin singular": ("adjectif ou adverbe, masculin singulier", "adjective or adverb, masculine singular"),
        "masculin plural": ("masculin pluriel", "masculine plural"),
        "substantiv feminin (tuse)": ("nom féminin (la toux)", "feminine noun (cough)"),
        "prepoziție (fără)": ("préposition (sans)", "preposition (without)"),
        "«se» + «en», lângă un verb": ("« se » + « en », devant un verbe", "“se” + “en”, before a verb"),
        "numeralul 100": ("le numéral 100", "the numeral 100"),
        "substantiv masculin (sânge)": ("nom masculin (le sang)", "masculine noun (blood)"),
        "substantiv (timp, vreme)": ("nom (le temps)", "noun (time, weather)"),
        "adverb de cantitate (atât)": ("adverbe de quantité (tant)", "adverb of quantity (so much)"),
        "«te» + «en»": ("« te » + « en »", "“te” + “en”"),
        "prepoziție (pe, deasupra)": ("préposition (sur)", "preposition (on, above)"),
        "adjectiv (sigur)": ("adjectif (sûr)", "adjective (sure)"),
        "articol partitiv sau contractat («de le»)": ("article partitif ou contracté (« de le »)", "partitive or contracted article (“de le”)"),
        "participiul trecut al lui «devoir»": ("le participe passé de « devoir »", "the past participle of “devoir”"),
        "determinant posesiv feminin": ("déterminant possessif féminin", "feminine possessive determiner"),
        "pronume demonstrativ (asta)": ("pronom démonstratif (ça)", "demonstrative pronoun (that)"),
        "adjectiv de culoare (verde)": ("adjectif de couleur (vert)", "colour adjective (green)"),
        "substantiv masculin (pahar, sticlă)": ("nom masculin (le verre)", "masculine noun (glass)"),
        "prepoziție (spre) sau vers de poezie": ("préposition (vers) ou vers de poésie", "preposition (towards) or a line of verse"),
        "substantiv masculin (vierme)": ("nom masculin (le ver)", "masculine noun (worm)"),
        "substantiv feminin (mare)": ("nom féminin (la mer)", "feminine noun (sea)"),
        "substantiv feminin (mamă)": ("nom féminin (la mère)", "feminine noun (mother)"),
        "substantiv (primar)": ("nom (le maire)", "noun (mayor)"),
        "substantiv feminin (voce)": ("nom féminin (la voix)", "feminine noun (voice)"),
        "substantiv feminin (cale, linie)": ("nom féminin (la voie)", "feminine noun (way, track)"),
        "verbul «voir», je / tu": ("le verbe « voir », je / tu", "the verb “voir”, je / tu"),
        "verbul «voir», il / elle": ("le verbe « voir », il / elle", "the verb “voir”, il / elle"),
        "conjuncție negativă (nici)": ("conjonction négative (ni)", "negative conjunction (nor)"),
        "«ne» + «y»": ("« ne » + « y »", "“ne” + “y”"),
        "substantiv feminin (sfârșit) sau adjectiv (fin)": ("nom féminin (la fin) ou adjectif (fin)", "feminine noun (end) or adjective (fine)"),
        "substantiv feminin (foame)": ("nom féminin (la faim)", "feminine noun (hunger)"),
        "Alege grafia corectă.": ("Choisis la bonne graphie.", "Choose the correct spelling."),
        "Feminină": ("Féminine", "Feminine"),
        "Masculină": ("Masculine", "Masculine"),
    ]
}
