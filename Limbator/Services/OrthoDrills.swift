import Foundation

/// La banque d'exercices.
///
/// Deux sources, délibérément :
///
/// 1. **Des exercices écrits à la main** pour les règles qui demandent une
///    phrase réelle, avec un contexte qui rend la bonne réponse évidente une
///    fois la règle comprise — et seulement à ce moment-là.
///
/// 2. **Des exercices dérivés** des familles d'homophones et des exemples des
///    règles. Ce qui est déjà déclaré une fois (dans `OrthoSeeds`, dans
///    `OrthoRules`) devient un exercice sans être ressaisi : une famille
///    ajoutée là produit immédiatement ses exercices ici, et rien ne peut
///    diverger entre la règle et l'entraînement.
enum OrthoDrills {

    // =========================================================================
    // MARK: - Accents
    // =========================================================================

    static let accentDrills: [OrthoDrill] = [
        .init(ruleId: "accents.cedille", module: .accents, kind: .choice,
              instruction: "Alege forma corectă.",
              sentence: "Le ___ range les verres.", answer: "garçon",
              distractors: ["garcon", "garçone"],
              explanation: "Sedila păstrează sunetul /s/ înainte de o. Fără ea s-ar citi «gar-kon»."),
        .init(ruleId: "accents.cedille", module: .accents, kind: .choice,
              instruction: "Alege forma corectă.",
              sentence: "J'ai ___ ta lettre hier.", answer: "reçu",
              distractors: ["recu", "réçu"],
              explanation: "«Reçu» — sedilă înainte de u. «Recu» s-ar citi /rəky/ cu /k/."),
        .init(ruleId: "accents.cedille", module: .accents, kind: .choice,
              instruction: "Unde NU se pune sedila?",
              sentence: "Regarde ___ de plus près.", answer: "ceci",
              distractors: ["çeci", "cecï"],
              explanation: "Înainte de e și i, c-ul se citește deja /s/: sedila e inutilă."),
        .init(ruleId: "accents.aigu-grave", module: .accents, kind: .choice,
              instruction: "é sau è ?",
              sentence: "Je ___ que tu viendras.", answer: "espère",
              distractors: ["espére", "espere"],
              explanation: "Silaba următoare conține un e mut («-re»), deci accent grav: espère."),
        .init(ruleId: "accents.aigu-grave", module: .accents, kind: .choice,
              instruction: "é sau è ?",
              sentence: "Il faut ___ avant de partir.", answer: "espérer",
              distractors: ["espèrer", "esperer"],
              explanation: "Silaba următoare este «-rer», fără e mut: accent ascuțit, espérer."),
        .init(ruleId: "accents.e-sans-accent", module: .accents, kind: .choice,
              instruction: "Cu sau fără accent?",
              sentence: "Elle porte une ___ robe.", answer: "belle",
              distractors: ["bèlle", "bélle"],
              explanation: "Consoana dublă «ll» închide silaba: e-ul nu primește niciodată accent."),
        .init(ruleId: "accents.e-sans-accent", module: .accents, kind: .choice,
              instruction: "Cu sau fără accent?",
              sentence: "La ___ est humide ce matin.", answer: "terre",
              distractors: ["tèrre", "térre"],
              explanation: "«rr» dublu — deci fără accent, ca în «belle», «cette», «essence»."),
        .init(ruleId: "accents.trema", module: .accents, kind: .choice,
              instruction: "Alege forma corectă.",
              sentence: "Il est trop ___ pour comprendre.", answer: "naïf",
              distractors: ["naif", "naîf"],
              explanation: "Trema desparte cele două vocale: na-if. Fără ea s-ar citi /nɛf/."),
        .init(ruleId: "accents.trema", module: .accents, kind: .choice,
              instruction: "Alege forma corectă.",
              sentence: "Nous fêtons ___ en famille.", answer: "Noël",
              distractors: ["Noel", "Noèl"],
              explanation: "No-ël, în două silabe. Trema stă pe a doua vocală."),
        .init(ruleId: "accents.circonflexe", module: .accents, kind: .choice,
              instruction: "Cu sau fără acoperiș?",
              sentence: "Nous marchons dans la ___.", answer: "forêt",
              distractors: ["foret", "forét"],
              explanation: "Circumflexul ține locul unui s dispărut — compară cu engleza «forest»."),
        .init(ruleId: "accents.circonflexe", module: .accents, kind: .choice,
              instruction: "Care formă cere circumflexul?",
              sentence: "Je suis ___ de moi.", answer: "sûr",
              distractors: ["sur", "sùr"],
              explanation: "«Sûr» (sigur) se deosebește de «sur» (pe) doar prin acest accent."),
        .init(ruleId: "accents.majuscules", module: .accents, kind: .choice,
              instruction: "Franceza îngrijită păstrează accentul pe majusculă.",
              sentence: "___ bientôt !", answer: "À",
              distractors: ["A", "Á"],
              explanation: "Majuscula nu scutește de accent: «À bientôt», «État», «Élève»."),
        .init(ruleId: "accents.aigu-grave", module: .accents, kind: .accent,
              instruction: "Adaugă accentele care lipsesc.",
              sentence: "L'___ écoute son professeur.", answer: "élève",
              distractors: ["eleve", "éleve", "elève"],
              explanation: "Două accente ascuțite? Nu: é-l-è-v-e. Al doilea e este urmat de o silabă cu e mut, deci primește accent grav."),
        .init(ruleId: "accents.circonflexe", module: .accents, kind: .accent,
              instruction: "Adaugă accentele care lipsesc.",
              sentence: "Il travaille à l'___ depuis dix ans.", answer: "hôpital",
              distractors: ["hopital", "hòpital", "hôpîtal"],
              explanation: "Un singur accent, pe o: hôpital. Vine din «hospital» — s-ul a devenit ô.")
    ]

    // =========================================================================
    // MARK: - Terminaisons verbales
    // =========================================================================

    static let verbEndingDrills: [OrthoDrill] = [
        .init(ruleId: "verbEndings.er-e-ez", module: .verbEndings, kind: .choice,
              instruction: "Testul cu «vendre»: -er, -é sau -ez ?",
              sentence: "Il va ___ une lettre.", answer: "écrire",
              distractors: ["écrit", "écrivez"],
              explanation: "«Il va vendre» merge → infinitiv. Aici verbul e neregulat: «écrire»."),
        .init(ruleId: "verbEndings.er-e-ez", module: .verbEndings, kind: .choice,
              instruction: "Testul cu «vendre»: -er sau -é ?",
              sentence: "Nous allons ___ au restaurant.", answer: "manger",
              distractors: ["mangé", "mangez"],
              explanation: "«Nous allons vendre» merge → infinitiv, deci «manger»."),
        .init(ruleId: "verbEndings.er-e-ez", module: .verbEndings, kind: .choice,
              instruction: "Testul cu «vendu»: -er sau -é ?",
              sentence: "Elle a ___ toute la nuit.", answer: "travaillé",
              distractors: ["travailler", "travaillez"],
              explanation: "«Elle a vendu» merge → participiu trecut, deci «travaillé»."),
        .init(ruleId: "verbEndings.er-e-ez", module: .verbEndings, kind: .choice,
              instruction: "Care subiect cere -ez ?",
              sentence: "Vous ___ très bien le français.", answer: "parlez",
              distractors: ["parler", "parlé"],
              explanation: "Subiectul «vous» cere terminația -ez."),
        .init(ruleId: "verbEndings.er-e-ez", module: .verbEndings, kind: .choice,
              instruction: "După prepoziție vine infinitivul.",
              sentence: "Elle est venue pour t'___.", answer: "aider",
              distractors: ["aidé", "aidez"],
              explanation: "După o prepoziție («pour», «sans», «avant de») verbul stă la infinitiv."),
        .init(ruleId: "verbEndings.ent-muet", module: .verbEndings, kind: .choice,
              instruction: "Se aude la fel — dar cum se scrie?",
              sentence: "Les enfants ___ dans la cour.", answer: "jouent",
              distractors: ["joue", "jouens"],
              explanation: "Persoana a III-a plural: -ent, care nu se aude niciodată."),
        .init(ruleId: "verbEndings.ent-muet", module: .verbEndings, kind: .choice,
              instruction: "Singular sau plural?",
              sentence: "Mes voisins ___ trop fort.", answer: "parlent",
              distractors: ["parle", "parles"],
              explanation: "«Mes voisins» este plural: «parlent», cu -ent mut."),
        .init(ruleId: "verbEndings.imparfait", module: .verbEndings, kind: .choice,
              instruction: "Găsește subiectul, apoi terminația.",
              sentence: "Quand j'___ petit, j'habitais à Cluj.", answer: "étais",
              distractors: ["était", "étaient"],
              explanation: "Subiectul este «je»: terminația imperfectului este -ais."),
        .init(ruleId: "verbEndings.imparfait", module: .verbEndings, kind: .choice,
              instruction: "Găsește subiectul, apoi terminația.",
              sentence: "Les rues ___ désertes ce soir-là.", answer: "étaient",
              distractors: ["était", "étais"],
              explanation: "«Les rues» este plural: -aient."),
        .init(ruleId: "verbEndings.futur-conditionnel", module: .verbEndings, kind: .choice,
              instruction: "Viitor sau condițional? Treci la «il».",
              sentence: "Demain, je ___ à Paris.", answer: "partirai",
              distractors: ["partirais", "partirait"],
              explanation: "«Il partira» → viitor, deci -ai. Acțiunea e sigură, are o dată."),
        .init(ruleId: "verbEndings.futur-conditionnel", module: .verbEndings, kind: .choice,
              instruction: "Viitor sau condițional? Treci la «il».",
              sentence: "Si j'avais le temps, je ___ ce livre.", answer: "lirais",
              distractors: ["lirai", "lirait"],
              explanation: "«Il lirait» → condițional, deci -ais. Condiția o cere."),
        .init(ruleId: "verbEndings.er-e-ez", module: .verbEndings, kind: .fill,
              instruction: "Scrie verbul la forma potrivită (verbul: manger).",
              sentence: "Hier soir, nous avons ___ des crêpes.", answer: "mangé",
              explanation: "«Nous avons vendu» → participiu trecut: mangé."),
        .init(ruleId: "verbEndings.er-e-ez", module: .verbEndings, kind: .fill,
              instruction: "Scrie verbul la forma potrivită (verbul: chanter).",
              sentence: "Elle adore ___ sous la douche.", answer: "chanter",
              explanation: "«Elle adore vendre» → infinitiv: chanter.")
    ]

    // =========================================================================
    // MARK: - Accords
    // =========================================================================

    static let agreementDrills: [OrthoDrill] = [
        .init(ruleId: "agreements.participe-etre", module: .agreements, kind: .choice,
              instruction: "Auxiliarul «être» privește subiectul.",
              sentence: "Elle est ___ à huit heures.", answer: "partie",
              distractors: ["parti", "parties"],
              explanation: "Subiect feminin singular → participiul ia -e: partie."),
        .init(ruleId: "agreements.participe-etre", module: .agreements, kind: .choice,
              instruction: "Auxiliarul «être» privește subiectul.",
              sentence: "Mes sœurs sont ___ hier soir.", answer: "arrivées",
              distractors: ["arrivé", "arrivés"],
              explanation: "Subiect feminin plural → -ées."),
        .init(ruleId: "agreements.participe-avoir", module: .agreements, kind: .choice,
              instruction: "Complementul stă după verb — se face acordul?",
              sentence: "J'ai ___ les pommes du jardin.", answer: "mangé",
              distractors: ["mangée", "mangées"],
              explanation: "Cu «avoir», complementul plasat DUPĂ verb nu dă acord."),
        .init(ruleId: "agreements.participe-avoir", module: .agreements, kind: .choice,
              instruction: "Complementul stă înaintea verbului — se face acordul?",
              sentence: "Les pommes que j'ai ___ étaient mûres.", answer: "mangées",
              distractors: ["mangé", "mangés"],
              explanation: "«Que» reia «les pommes» (feminin plural) și stă înainte → acord: mangées."),
        .init(ruleId: "agreements.participe-avoir", module: .agreements, kind: .choice,
              instruction: "Pronumele «les» este complement direct antepus.",
              sentence: "Ces lettres ? Je les ai ___ ce matin.", answer: "écrites",
              distractors: ["écrit", "écrits"],
              explanation: "«Les» = «ces lettres», feminin plural, plasat înainte → écrites."),
        .init(ruleId: "agreements.pronominaux", module: .agreements, kind: .choice,
              instruction: "Spălat pe cine? Răspunsul decide acordul.",
              sentence: "Elle s'est ___ les mains.", answer: "lavé",
              distractors: ["lavée", "lavées"],
              explanation: "Complementul direct este «les mains», plasat DUPĂ: fără acord."),
        .init(ruleId: "agreements.pronominaux", module: .agreements, kind: .choice,
              instruction: "Spălat pe cine? Răspunsul decide acordul.",
              sentence: "Elle s'est ___ avant le dîner.", answer: "lavée",
              distractors: ["lavé", "lavées"],
              explanation: "«S'» este complementul direct și stă înainte → acord: lavée."),
        .init(ruleId: "agreements.pronominaux", module: .agreements, kind: .choice,
              instruction: "«Parler à» cere complement indirect.",
              sentence: "Elles se sont ___ pendant une heure.", answer: "parlé",
              distractors: ["parlées", "parlés"],
              explanation: "Se spune «parler À quelqu'un»: complement indirect, deci niciun acord."),
        .init(ruleId: "agreements.adjectif", module: .agreements, kind: .choice,
              instruction: "Acordă adjectivul.",
              sentence: "Une ___ maison au bord de la Loire.", answer: "grande",
              distractors: ["grand", "grandes"],
              explanation: "«Maison» este feminin singular: grande."),
        .init(ruleId: "agreements.adjectif", module: .agreements, kind: .choice,
              instruction: "Atenție la culorile invariabile.",
              sentence: "Elle a de beaux yeux ___.", answer: "marron",
              distractors: ["marrons", "marronnes"],
              explanation: "«Marron» este la origine un substantiv (castană): rămâne invariabil."),
        .init(ruleId: "agreements.participe-avoir", module: .agreements, kind: .fill,
              instruction: "Scrie participiul acordat corect (verbul: voir).",
              sentence: "La tour Eiffel ? Je l'ai ___ hier.", answer: "vue",
              explanation: "«L'» reia «la tour Eiffel», feminin singular, plasat înainte → vue."),
        .init(ruleId: "agreements.participe-etre", module: .agreements, kind: .fill,
              instruction: "Scrie participiul acordat corect (verbul: rentrer).",
              sentence: "Mes cousines sont ___ tard.", answer: "rentrées",
              explanation: "Auxiliar «être» + subiect feminin plural → rentrées.")
    ]

    // =========================================================================
    // MARK: - Pluriels
    // =========================================================================

    static let pluralDrills: [OrthoDrill] = [
        .init(ruleId: "plurals.al-aux", module: .plurals, kind: .choice,
              instruction: "Pune la plural.",
              sentence: "Il lit trois ___ chaque matin.", answer: "journaux",
              distractors: ["journals", "journeaux"],
              explanation: "-al devine -aux: journal → journaux."),
        .init(ruleId: "plurals.al-aux", module: .plurals, kind: .choice,
              instruction: "Atenție: acesta este o excepție.",
              sentence: "Nous avons vu deux ___ de musique.", answer: "festivals",
              distractors: ["festivaux", "festivales"],
              explanation: "«Festival» face parte din excepții: bal, carnaval, chacal, festival, récital, régal."),
        .init(ruleId: "plurals.ou-oux", module: .plurals, kind: .choice,
              instruction: "-ous sau -oux ?",
              sentence: "Elle range ses ___ dans une boîte.", answer: "bijoux",
              distractors: ["bijous", "bijouxs"],
              explanation: "«Bijou» este unul dintre cele șapte cuvinte în -ou care iau x."),
        .init(ruleId: "plurals.ou-oux", module: .plurals, kind: .choice,
              instruction: "-ous sau -oux ?",
              sentence: "Le mur a plusieurs ___.", answer: "trous",
              distractors: ["troux", "trouxs"],
              explanation: "Regula generală: -ou ia s. Doar cele șapte excepții iau x."),
        .init(ruleId: "plurals.eau-eu-x", module: .plurals, kind: .choice,
              instruction: "-x sau -s ?",
              sentence: "Les ___ passent sous le pont.", answer: "bateaux",
              distractors: ["bateaus", "batteaux"],
              explanation: "-eau face pluralul cu x: bateau → bateaux."),
        .init(ruleId: "plurals.eau-eu-x", module: .plurals, kind: .choice,
              instruction: "Atenție: excepție.",
              sentence: "Il a changé les quatre ___.", answer: "pneus",
              distractors: ["pneux", "pneaus"],
              explanation: "«Pneu» și «bleu» sunt excepțiile care iau s."),
        .init(ruleId: "plurals.ail-aux", module: .plurals, kind: .choice,
              instruction: "-ails sau -aux ?",
              sentence: "Les ___ de la cathédrale sont magnifiques.", answer: "vitraux",
              distractors: ["vitrails", "vitreaux"],
              explanation: "«Vitrail» face parte din cele șapte care fac -aux."),
        .init(ruleId: "plurals.ail-aux", module: .plurals, kind: .choice,
              instruction: "-ails sau -aux ?",
              sentence: "Donne-moi tous les ___ de l'histoire.", answer: "détails",
              distractors: ["détaux", "détailles"],
              explanation: "Regula generală: -ail ia s. «Détail» nu este o excepție."),
        .init(ruleId: "plurals.nombres", module: .plurals, kind: .choice,
              instruction: "Cu sau fără s ?",
              sentence: "Il a payé ___ euros.", answer: "quatre-vingts",
              distractors: ["quatre-vingt", "quatre-vingtes"],
              explanation: "«Vingt» înmulțit și neurmat de alt numeral primește s."),
        .init(ruleId: "plurals.nombres", module: .plurals, kind: .choice,
              instruction: "Cu sau fără s ?",
              sentence: "Elle a ___ ans aujourd'hui.", answer: "quatre-vingt-deux",
              distractors: ["quatre-vingts-deux", "quatre-vingt-deuxs"],
              explanation: "Urmat de alt numeral, «vingt» pierde s-ul."),
        .init(ruleId: "plurals.nombres", module: .plurals, kind: .choice,
              instruction: "«Mille» se acordă?",
              sentence: "La ville compte trois ___ habitants.", answer: "mille",
              distractors: ["milles", "milliers"],
              explanation: "«Mille» este invariabil, mereu."),
        .init(ruleId: "plurals.al-aux", module: .plurals, kind: .fill,
              instruction: "Scrie pluralul lui «animal».",
              sentence: "Le zoo abrite cent ___.", answer: "animaux",
              explanation: "-al → -aux: animal → animaux.")
    ]

    // =========================================================================
    // MARK: - Consonnes doubles
    // =========================================================================

    static let doubleLetterDrills: [OrthoDrill] = [
        .init(ruleId: "doubleLetters.principe", module: .doubleLetters, kind: .choice,
              instruction: "Una sau două consoane?",
              sentence: "Fais ___ à la marche.", answer: "attention",
              distractors: ["atention", "attension"],
              explanation: "Doi de t: at-tention. Româna a simplificat, franceza nu."),
        .init(ruleId: "doubleLetters.principe", module: .doubleLetters, kind: .choice,
              instruction: "Una sau două consoane?",
              sentence: "Donne-moi ton ___ postale.", answer: "adresse",
              distractors: ["adrese", "addresse"],
              explanation: "Doi de s: adre-sse. Cu un singur s s-ar citi /adrəz/."),
        .init(ruleId: "doubleLetters.principe", module: .doubleLetters, kind: .choice,
              instruction: "Una sau două consoane?",
              sentence: "Ils cherchent un ___ à Lyon.", answer: "appartement",
              distractors: ["apartement", "appartament"],
              explanation: "Doi de p, și terminația -ement: ap-par-te-ment."),
        .init(ruleId: "doubleLetters.principe", module: .doubleLetters, kind: .choice,
              instruction: "Una sau două consoane?",
              sentence: "Elle mange une ___ verte.", answer: "pomme",
              distractors: ["pome", "pommme"],
              explanation: "Doi de m: pom-me. Consoana dublă nu se aude, dar ține vocala precedentă deschisă."),
        .init(ruleId: "doubleLetters.appeler-jeter", module: .doubleLetters, kind: .choice,
              instruction: "Terminația se aude sau nu?",
              sentence: "Je t'___ ce soir.", answer: "appelle",
              distractors: ["appele", "apelle"],
              explanation: "Terminația «-e» este mută → consoana se dublează: j'appelle."),
        .init(ruleId: "doubleLetters.appeler-jeter", module: .doubleLetters, kind: .choice,
              instruction: "Terminația se aude sau nu?",
              sentence: "Nous ___ les voisins demain.", answer: "appelons",
              distractors: ["appellons", "apelons"],
              explanation: "Terminația «-ons» se aude → consoana rămâne simplă: nous appelons."),
        .init(ruleId: "doubleLetters.appeler-jeter", module: .doubleLetters, kind: .choice,
              instruction: "Dublare sau accent grav?",
              sentence: "J'___ du pain tous les matins.", answer: "achète",
              distractors: ["achette", "achete"],
              explanation: "«Acheter» preferă accentul grav: j'achète, nu «j'achette»."),
        .init(ruleId: "doubleLetters.principe", module: .doubleLetters, kind: .choice,
              instruction: "Una sau două consoane?",
              sentence: "Le ___ explique la règle.", answer: "professeur",
              distractors: ["profeseur", "professor"],
              explanation: "Doi de s și terminația -eur: pro-fes-seur."),
        .init(ruleId: "doubleLetters.principe", module: .doubleLetters, kind: .fill,
              instruction: "Scrie cuvântul: «comunicare» în franceză.",
              sentence: "La ___ entre eux est difficile.", answer: "communication",
              explanation: "Doi de m: com-mu-ni-ca-tion."),
        .init(ruleId: "doubleLetters.principe", module: .doubleLetters, kind: .correction,
              instruction: "Găsește greșeala și rescrie cuvântul subliniat.",
              sentence: "Je vous recomande ce restaurant.", answer: "recommande",
              explanation: "Doi de m: re-com-mande. Româna scrie «recomand», franceza dublează.")
    ]

    // =========================================================================
    // MARK: - Lettres muettes
    // =========================================================================

    static let silentLetterDrills: [OrthoDrill] = [
        .init(ruleId: "silentLetters.finales", module: .silentLetters, kind: .choice,
              instruction: "Ce literă mută se ascunde la final?",
              sentence: "C'est un ___ village de Provence.", answer: "petit",
              distractors: ["peti", "petis"],
              explanation: "Proba: femininul «petite» face t-ul să se audă."),
        .init(ruleId: "silentLetters.finales", module: .silentLetters, kind: .choice,
              instruction: "Ce literă mută se ascunde la final?",
              sentence: "Il y a beaucoup de ___ dans la rue.", answer: "bruit",
              distractors: ["brui", "bruis"],
              explanation: "Proba: «bruitage» face t-ul să se audă."),
        .init(ruleId: "silentLetters.finales", module: .silentLetters, kind: .choice,
              instruction: "Ce literă mută se ascunde la final?",
              sentence: "Une goutte de ___ sur la neige.", answer: "sang",
              distractors: ["san", "sant"],
              explanation: "Proba: «sanguin» face g-ul să se audă."),
        .init(ruleId: "silentLetters.h-muet", module: .silentLetters, kind: .choice,
              instruction: "Se elidează sau nu?",
              sentence: "___ est arrivé en retard.", answer: "L'homme",
              distractors: ["Le homme", "La homme"],
              explanation: "H mut: eliziunea este obligatorie, «l'homme»."),
        .init(ruleId: "silentLetters.h-muet", module: .silentLetters, kind: .choice,
              instruction: "Se elidează sau nu?",
              sentence: "___ du film meurt à la fin.", answer: "Le héros",
              distractors: ["L'héros", "La héros"],
              explanation: "H aspirat: fără eliziune și fără legătură, «le héros»."),
        .init(ruleId: "silentLetters.h-muet", module: .silentLetters, kind: .choice,
              instruction: "Se elidează sau nu?",
              sentence: "Elle déteste ___ vert.", answer: "le haricot",
              distractors: ["l'haricot", "la haricot"],
              explanation: "«Haricot» are h aspirat — de aceea se spune «les | haricots», fără legătură."),
        .init(ruleId: "silentLetters.liaison", module: .silentLetters, kind: .choice,
              instruction: "Unde NU se face legătura?",
              sentence: "Il est parti ___ elle est restée.", answer: "et",
              distractors: ["et_", "ett"],
              explanation: "După «et» legătura este întotdeauna interzisă."),
        .init(ruleId: "silentLetters.finales", module: .silentLetters, kind: .fill,
              instruction: "Scrie cuvântul (indiciu: «grandeur»).",
              sentence: "C'est un très ___ jardin.", answer: "grand",
              explanation: "Litera mută este d — proba: «grandeur», «grande»."),
        .init(ruleId: "silentLetters.finales", module: .silentLetters, kind: .fill,
              instruction: "Scrie cuvântul (indiciu: «tabagie»).",
              sentence: "Il achète son journal au ___.", answer: "tabac",
              explanation: "Litera mută este c — proba: «tabagie».")
    ]

    // =========================================================================
    // MARK: - Pièges roumain -> français
    // =========================================================================

    static let roTrapDrills: [OrthoDrill] = [
        .init(ruleId: "roTraps.circonflexe-s", module: .roTraps, kind: .choice,
              instruction: "«fereastră» în franceză:",
              sentence: "Ouvre la ___, il fait chaud.", answer: "fenêtre",
              distractors: ["fenetre", "fenestre"],
              explanation: "S-ul din «fereastră» a devenit accentul circumflex: fenêtre."),
        .init(ruleId: "roTraps.circonflexe-s", module: .roTraps, kind: .choice,
              instruction: "«spital» în franceză:",
              sentence: "Elle travaille à l'___.", answer: "hôpital",
              distractors: ["hopital", "hospital"],
              explanation: "S-ul din «spital» a devenit ô: hôpital."),
        .init(ruleId: "roTraps.circonflexe-s", module: .roTraps, kind: .choice,
              instruction: "«insulă» în franceză:",
              sentence: "Nous partons sur une ___ grecque.", answer: "île",
              distractors: ["ile", "isle"],
              explanation: "S-ul din «insulă» a devenit î: île."),
        .init(ruleId: "roTraps.circonflexe-s", module: .roTraps, kind: .choice,
              instruction: "«a costa» în franceză:",
              sentence: "Combien ça va ___ ?", answer: "coûter",
              distractors: ["couter", "couster"],
              explanation: "S-ul din «a costa» a devenit û: coûter."),
        .init(ruleId: "roTraps.consonnes-doubles", module: .roTraps, kind: .choice,
              instruction: "«profesor» în franceză:",
              sentence: "Mon ___ de français est belge.", answer: "professeur",
              distractors: ["profesor", "profeseur"],
              explanation: "Doi de s și terminația -eur, nu -or."),
        .init(ruleId: "roTraps.consonnes-doubles", module: .roTraps, kind: .choice,
              instruction: "«a recomanda» în franceză:",
              sentence: "Je te ___ ce livre.", answer: "recommande",
              distractors: ["recomande", "récommande"],
              explanation: "Doi de m: re-com-mande."),
        .init(ruleId: "roTraps.lettres-savantes", module: .roTraps, kind: .choice,
              instruction: "«farmacie» în franceză:",
              sentence: "La ___ est fermée le dimanche.", answer: "pharmacie",
              distractors: ["farmacie", "pharmassie"],
              explanation: "ph acolo unde româna scrie f — cuvânt de origine greacă."),
        .init(ruleId: "roTraps.lettres-savantes", module: .roTraps, kind: .choice,
              instruction: "«teatru» în franceză:",
              sentence: "Nous allons au ___ ce soir.", answer: "théâtre",
              distractors: ["teatre", "theatre"],
              explanation: "Trei semne într-un cuvânt scurt: th, é și â."),
        .init(ruleId: "roTraps.lettres-savantes", module: .roTraps, kind: .choice,
              instruction: "«tehnic» în franceză:",
              sentence: "C'est un problème ___.", answer: "technique",
              distractors: ["tehnique", "technic"],
              explanation: "ch acolo unde româna scrie h: tech-nique."),
        .init(ruleId: "roTraps.genres", module: .roTraps, kind: .choice,
              instruction: "«carte» este feminin în română. Și în franceză?",
              sentence: "J'ai lu ___ livre en deux jours.", answer: "un",
              distractors: ["une", "la"],
              explanation: "«Livre» este masculin în franceză, deși «carte» este feminin în română."),
        .init(ruleId: "roTraps.genres", module: .roTraps, kind: .choice,
              instruction: "«problemă» este feminin în română. Și în franceză?",
              sentence: "C'est ___ problème difficile.", answer: "un",
              distractors: ["une", "la"],
              explanation: "«Problème» este masculin — ca toate cuvintele în -ème."),
        .init(ruleId: "roTraps.genres", module: .roTraps, kind: .choice,
              instruction: "«dinte» este masculin în română. Și în franceză?",
              sentence: "Il s'est cassé ___ dent.", answer: "une",
              distractors: ["un", "le"],
              explanation: "«Dent» este feminin în franceză: «une dent blanche»."),
        .init(ruleId: "roTraps.consonnes-doubles", module: .roTraps, kind: .fill,
              instruction: "Scrie «apartament» în franceză.",
              sentence: "Ils louent un ___ à Montmartre.", answer: "appartement",
              explanation: "Doi de p, terminația -ement: ap-par-te-ment."),
        .init(ruleId: "roTraps.circonflexe-s", module: .roTraps, kind: .fill,
              instruction: "Scrie «pădure» în franceză (indiciu: engleza spune «forest»).",
              sentence: "Nous marchons dans la ___.", answer: "forêt",
              explanation: "Circumflexul ține locul s-ului dispărut.")
    ]

    // =========================================================================
    // MARK: - Exercices dérivés des familles d'homophones
    // =========================================================================

    /// Construit un exercice par graphie déclarée : la phrase d'exemple de la
    /// famille, la graphie retirée, et toutes les autres graphies proposées
    /// comme leurres. La bonne réponse est correcte **par construction** —
    /// aucune saisie manuelle ne peut la fausser.
    static var homophoneDrills: [OrthoDrill] {
        var drills: [OrthoDrill] = []
        for set in OrthoSeeds.homophoneSets {
            for member in set.members {
                guard let gapped = gap(member.form, in: member.example) else { continue }
                let others = set.members
                    .filter { $0.form != member.form }
                    .map(\.form)
                guard !others.isEmpty else { continue }
                drills.append(OrthoDrill(
                    ruleId: "homophones." + set.id,
                    module: .homophones,
                    kind: .choice,
                    instruction: "Alege grafia corectă.",
                    sentence: gapped,
                    answer: member.form,
                    distractors: Array(others.prefix(3)),
                    explanation: "« \(member.form) » = \(member.nature). \(member.test)"))
            }
        }
        return drills
    }

    /// Remplace la première occurrence **du mot entier** par le marqueur `___`.
    /// La comparaison se fait mot à mot : sans cela, chercher « a » dans
    /// « Il a un chien » trouverait le « a » de « chien ».
    static func gap(_ word: String, in sentence: String) -> String? {
        let separators = CharacterSet(charactersIn: " ")
        let parts = sentence.components(separatedBy: separators)
        var replaced = false
        var out: [String] = []
        for part in parts {
            if !replaced, stripPunctuation(part).lowercased() == word.lowercased() {
                out.append(part.replacingOccurrences(of: stripPunctuation(part), with: "___"))
                replaced = true
            } else {
                out.append(part)
            }
        }
        return replaced ? out.joined(separator: " ") : nil
    }

    private static func stripPunctuation(_ s: String) -> String {
        s.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?«»\"()"))
    }

    // =========================================================================
    // MARK: - Index
    // =========================================================================

    static func handwritten(for module: OrthoModule) -> [OrthoDrill] {
        switch module {
        case .accents:       return accentDrills
        case .homophones:    return homophoneDrills
        case .verbEndings:   return verbEndingDrills
        case .agreements:    return agreementDrills
        case .plurals:       return pluralDrills
        case .doubleLetters: return doubleLetterDrills
        case .silentLetters: return silentLetterDrills
        case .roTraps:       return roTrapDrills
        }
    }

    static var all: [OrthoDrill] {
        OrthoModule.allCases.flatMap { handwritten(for: $0) }
    }

    /// Les exercices d'un module, mélangés de façon déterministe à partir de
    /// `seed` : deux ouvertures de l'écran donnent des séries différentes, mais
    /// une même série ne se réordonne pas sous les doigts de l'utilisateur.
    static func drills(module: OrthoModule, count: Int, seed: UInt64 = 0) -> [OrthoDrill] {
        let pool = handwritten(for: module)
        guard !pool.isEmpty else { return [] }
        let ordered = pool.sorted { lhs, rhs in
            let a = OrthoDrill.seedHash(String(seed) + "-" + lhs.id.uuidString)
            let b = OrthoDrill.seedHash(String(seed) + "-" + rhs.id.uuidString)
            return a < b
        }
        return Array(ordered.prefix(max(1, count)))
    }

    /// Les exercices attachés à une règle précise — utilisés pour la révision
    /// ciblée après une faute.
    static func drills(ruleId: String, count: Int = 5) -> [OrthoDrill] {
        Array(all.filter { $0.ruleId == ruleId }.prefix(count))
    }
}
