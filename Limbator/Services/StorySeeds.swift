import Foundation

/// Les scènes des quatre récits, écrites à la main.
///
/// Deux d'entre eux partent de Roumanie : l'atelier de Brancusi impasse Ronsin,
/// et l'arrivée d'une étudiante gare du Nord. Ce n'est pas une coquetterie —
/// un apprenant lit mieux, et retient davantage, quand le texte le concerne.
///
/// Chaque scène porte un **arrêt sur mot** : un terme du paragraphe dont
/// l'orthographe mérite qu'on s'arrête. Le récit devient ainsi une leçon
/// d'orthographe déguisée, ce qui est la seule forme de leçon qu'on lise
/// volontiers.
enum StorySeeds {

    static func scenes(story: Story, chapter: StoryChapter) -> [StoryScene] {
        switch story.slug {
        case "brancusi":     return brancusi(chapter: chapter.index)
        case "aller-simple": return allerSimple(chapter: chapter.index)
        case "loire":        return loire(chapter: chapter.index)
        case "montmartre":   return montmartre(chapter: chapter.index)
        default:             return [opening(story: story)]
        }
    }

    // =========================================================================
    // MARK: - La lettre de Brancusi
    // =========================================================================

    private static func brancusi(chapter: Int) -> [StoryScene] {
        switch chapter {
        case 1:
            return [
                scene("En 1904, un jeune homme quitte le village de Hobița, en Olténie. Il n'a pas d'argent pour le train. Il partira donc à pied.",
                      "În 1904, un tânăr pleacă din satul Hobița, în Oltenia. Nu are bani de tren. Va pleca deci pe jos.",
                      [hl("quitter", "a părăsi", "[ki.te]"), hl("argent", "bani", "[aʁ.ʒɑ̃]"), hl("à pied", "pe jos", "[a pje]")],
                      ortho("argent", "T-ul final este mut, dar se scrie. Proba: «argenterie».", .silentLetters)),
                scene("Il traverse la Hongrie, l'Autriche, la Bavière. Il dort dans les granges. À Lucerne, il tombe malade et doit s'arrêter deux mois.",
                      "Traversează Ungaria, Austria, Bavaria. Doarme prin șuri. La Lucerna se îmbolnăvește și trebuie să se oprească două luni.",
                      [hl("traverser", "a traversa", "[tʁa.vɛʁ.se]"), hl("malade", "bolnav", "[ma.lad]"), hl("s'arrêter", "a se opri", "[sa.ʁɛ.te]")],
                      ortho("s'arrêter", "Doi de r și circumflex pe ê: ar-rê-ter.", .accents)),
                scene("Le 14 juillet 1904, il arrive à Paris. Il ne parle pas un mot de français. Il a vingt-huit ans et quelques francs dans la poche.",
                      "Pe 14 iulie 1904 ajunge la Paris. Nu vorbește o vorbă franțuzească. Are douăzeci și opt de ani și câțiva franci în buzunar.",
                      [hl("arriver", "a sosi", "[a.ʁi.ve]"), hl("mot", "cuvânt", "[mo]"), hl("poche", "buzunar", "[pɔʃ]")],
                      ortho("mot", "T final mut. Proba: «motif», «motiver».", .silentLetters)),
                scene("Le premier mot qu'il apprend est « bonjour ». Le deuxième est « pierre ». Le troisième, dit-il plus tard, était « lumière ».",
                      "Primul cuvânt pe care îl învață este «bonjour». Al doilea este «pierre» (piatră). Al treilea, va spune mai târziu, era «lumière» (lumină).",
                      [hl("apprendre", "a învăța", "[a.pʁɑ̃dʁ]"), hl("pierre", "piatră", "[pjɛʁ]"), hl("lumière", "lumină", "[ly.mjɛʁ]")],
                      ortho("lumière", "Accent grav pe è, ca în «mère», «père», «rivière».", .accents),
                      choice("Ce cuvânt ai învăța primul într-o limbă nouă?",
                             ["« bonjour »", "« merci »", "« lumière »"]))
            ]
        case 2:
            return [
                scene("L'atelier se trouve impasse Ronsin, dans le quinzième arrondissement. Il est blanc. Tout y est blanc : les murs, la poussière, les blouses.",
                      "Atelierul se află pe Impasse Ronsin, în arondismentul cincisprezece. Este alb. Totul este alb acolo: pereții, praful, halatele.",
                      [hl("atelier", "atelier", "[a.tə.lje]"), hl("mur", "perete", "[myʁ]"), hl("poussière", "praf", "[pu.sjɛʁ]")],
                      ortho("poussière", "Doi de s și accent grav pe è.", .doubleLetters)),
                scene("Il refuse d'entrer chez Rodin. « Rien ne pousse à l'ombre des grands arbres », écrit-il. Il préfère tailler seul, lentement.",
                      "Refuză să intre la Rodin. «Nimic nu crește la umbra copacilor mari», scrie el. Preferă să cioplească singur, încet.",
                      [hl("refuser", "a refuza", "[ʁə.fy.ze]"), hl("ombre", "umbră", "[ɔ̃bʁ]"), hl("arbre", "copac", "[aʁbʁ]")],
                      ortho("préférer", "Două accente ascuțite, dar «je préfère» primește accent grav.", .accents)),
                scene("Il fabrique lui-même ses outils, ses meubles, sa porte. Il cuit son pain dans un four qu'il a bâti de ses mains.",
                      "Își fabrică singur uneltele, mobila, ușa. Își coace pâinea într-un cuptor pe care l-a zidit cu mâinile lui.",
                      [hl("outil", "unealtă", "[u.ti]"), hl("meuble", "mobilă", "[mœbl]"), hl("four", "cuptor", "[fuʁ]")],
                      ortho("outil", "L-ul final este mut — una dintre rarele excepții.", .silentLetters)),
                scene("Les visiteurs remarquent le silence. On n'entend que le ciseau sur la pierre, et parfois un disque de musique roumaine.",
                      "Vizitatorii remarcă tăcerea. Nu se aude decât dalta pe piatră și, uneori, un disc cu muzică românească.",
                      [hl("silence", "tăcere", "[si.lɑ̃s]"), hl("entendre", "a auzi", "[ɑ̃.tɑ̃dʁ]"), hl("parfois", "uneori", "[paʁ.fwa]")],
                      ortho("silence", "MASCULIN în franceză: «un silence complet», deși «liniștea» e feminin.", .roTraps))
            ]
        case 3:
            return [
                scene("En 1923, il commence un oiseau. Pas un oiseau posé : un oiseau en plein vol, réduit à sa seule trajectoire.",
                      "În 1923 începe o pasăre. Nu o pasăre așezată: o pasăre în plin zbor, redusă la traiectoria ei.",
                      [hl("oiseau", "pasăre", "[wa.zo]"), hl("vol", "zbor", "[vɔl]"), hl("réduire", "a reduce", "[ʁe.dɥiʁ]")],
                      ortho("oiseau", "Pluralul «oiseaux» primește un x, nu un s.", .plurals)),
                scene("« Je ne sculpte pas un oiseau », dit-il, « je sculpte le vol. » Le bronze est poli pendant des mois, jusqu'à devenir un miroir.",
                      "«Nu sculptez o pasăre», spune el, «sculptez zborul.» Bronzul este șlefuit luni întregi, până devine oglindă.",
                      [hl("sculpter", "a sculpta", "[skyl.te]"), hl("poli", "șlefuit", "[pɔ.li]"), hl("miroir", "oglindă", "[mi.ʁwaʁ]")],
                      ortho("sculpter", "P-ul nu se aude, dar se scrie: scul-p-ter.", .silentLetters)),
                scene("En 1926, la douane américaine refuse d'y voir une œuvre d'art. Un oiseau qui ne ressemble pas à un oiseau, disent-ils, est un objet industriel.",
                      "În 1926, vama americană refuză să vadă în ea o operă de artă. O pasăre care nu seamănă cu o pasăre, spun ei, este un obiect industrial.",
                      [hl("douane", "vamă", "[dwan]"), hl("œuvre", "operă", "[œvʁ]"), hl("ressembler", "a semăna", "[ʁə.sɑ̃.ble]")],
                      ortho("œuvre", "Ligatura œ. «Oeuvre» este o scriere de avarie, nu forma corectă.", .accents)),
                scene("Le procès dure deux ans. Brancusi gagne. Le tribunal reconnaît qu'une sculpture n'a pas à ressembler à son sujet.",
                      "Procesul durează doi ani. Brâncuși câștigă. Tribunalul recunoaște că o sculptură nu trebuie să semene cu subiectul ei.",
                      [hl("procès", "proces", "[pʁɔ.sɛ]"), hl("gagner", "a câștiga", "[ga.ɲe]"), hl("reconnaître", "a recunoaște", "[ʁə.kɔ.nɛtʁ]")],
                      ortho("procès", "Accent grav pe è și s final mut.", .accents),
                      choice("O sculptură trebuie să semene cu subiectul ei?",
                             ["Oui, sinon on ne comprend rien.", "Non, elle doit en montrer l'essence.", "Cela dépend de l'œuvre."]))
            ]
        default:
            return [
                scene("Il écrit rarement. Quand il le fait, c'est en roumain, puis il traduit lui-même, mot à mot, avec un dictionnaire posé sur le marbre.",
                      "Scrie rar. Când o face, scrie în românește, apoi traduce el însuși, cuvânt cu cuvânt, cu un dicționar pus pe marmură.",
                      [hl("écrire", "a scrie", "[e.kʁiʁ]"), hl("traduire", "a traduce", "[tʁa.dɥiʁ]"), hl("marbre", "marmură", "[maʁbʁ]")],
                      ortho("écrire", "É la început. Participiul este «écrit», cu t mut.", .accents)),
                scene("« Ma langue française est petite », note-t-il un jour. « Mais elle suffit à dire ce qui est simple, et je ne dis que des choses simples. »",
                      "«Franceza mea este mică», notează el într-o zi. «Dar îmi ajunge să spun ce este simplu, iar eu nu spun decât lucruri simple.»",
                      [hl("langue", "limbă", "[lɑ̃g]"), hl("suffire", "a fi de ajuns", "[sy.fiʁ]"), hl("simple", "simplu", "[sɛ̃pl]")],
                      ortho("suffire", "Doi de f: suf-fire.", .doubleLetters)),
                scene("Il meurt à Paris en 1957, français par passeport, roumain par la main. Son atelier est aujourd'hui reconstitué près du Centre Pompidou.",
                      "Moare la Paris în 1957, francez prin pașaport, român prin mână. Atelierul lui este astăzi reconstituit lângă Centre Pompidou.",
                      [hl("mourir", "a muri", "[mu.ʁiʁ]"), hl("main", "mână", "[mɛ̃]"), hl("aujourd'hui", "astăzi", "[o.ʒuʁ.dɥi]")],
                      ortho("aujourd'hui", "Un apostrof la mijloc, și un h mut la final.", .silentLetters))
            ]
        }
    }

    // =========================================================================
    // MARK: - Un aller simple pour Paris
    // =========================================================================

    private static func allerSimple(chapter: Int) -> [StoryScene] {
        switch chapter {
        case 1:
            return [
                scene("Le train s'arrête gare du Nord à sept heures douze. Ioana descend avec deux valises et un dictionnaire roumain-français.",
                      "Trenul se oprește în Gara de Nord la șapte și doisprezece. Ioana coboară cu două valize și un dicționar român-francez.",
                      [hl("gare", "gară", "[gaʁ]"), hl("valise", "valiză", "[va.liz]"), hl("descendre", "a coborî", "[de.sɑ̃dʁ]")],
                      ortho("s'arrête", "Doi de r și circumflex pe ê: ar-rê-te.", .accents)),
                scene("Le quai est immense. Elle cherche la sortie et se trompe deux fois. Personne ne la regarde : c'est la première chose qu'elle apprend de Paris.",
                      "Peronul este imens. Caută ieșirea și greșește de două ori. Nimeni nu se uită la ea: este primul lucru pe care îl învață despre Paris.",
                      [hl("quai", "peron", "[kɛ]"), hl("sortie", "ieșire", "[sɔʁ.ti]"), hl("se tromper", "a greși", "[sə tʁɔ̃.pe]")],
                      ortho("immense", "Doi de m: im-mense. Româna scrie «imens».", .roTraps)),
                scene("Dehors, il pleut. Elle sort le papier où elle a noté l'adresse : douze, rue des Petites-Écuries. Elle relit deux fois l'accent sur « Écuries ».",
                      "Afară plouă. Scoate hârtia pe care a notat adresa: doisprezece, rue des Petites-Écuries. Recitește de două ori accentul de pe «Écuries».",
                      [hl("dehors", "afară", "[də.ɔʁ]"), hl("adresse", "adresă", "[a.dʁɛs]"), hl("relire", "a reciti", "[ʁə.liʁ]")],
                      ortho("adresse", "Doi de s. Cu un singur s s-ar citi /a.dʁəz/.", .roTraps),
                      choice("Ce faci prima dată într-un oraș necunoscut?",
                             ["Je cherche un café.", "Je marche au hasard.", "Je demande mon chemin."]))
            ]
        case 2:
            return [
                scene("À la préfecture, on lui tend un formulaire. Nom, prénom, date de naissance, lieu de naissance. Puis : « Situation de famille ».",
                      "La prefectură i se întinde un formular. Nume, prenume, data nașterii, locul nașterii. Apoi: «Situația familială».",
                      [hl("formulaire", "formular", "[fɔʁ.my.lɛʁ]"), hl("naissance", "naștere", "[nɛ.sɑ̃s]"), hl("tendre", "a întinde", "[tɑ̃dʁ]")],
                      ortho("naissance", "Doi de s: nais-sance.", .doubleLetters)),
                scene("Elle hésite sur « célibataire ». Deux accents ? Un seul ? Elle écrit au crayon, puis repasse à l'encre quand elle est sûre.",
                      "Ezită la «célibataire». Două accente? Unul singur? Scrie cu creionul, apoi trece cu cerneala când e sigură.",
                      [hl("hésiter", "a ezita", "[e.zi.te]"), hl("crayon", "creion", "[kʁɛ.jɔ̃]"), hl("encre", "cerneală", "[ɑ̃kʁ]")],
                      ortho("sûre", "Circumflexul deosebește «sûre» (sigură) de «sur» (pe).", .homophones)),
                scene("L'employé relit, hoche la tête, tamponne. « C'est bien écrit », dit-il. Ioana garde cette phrase pendant des années.",
                      "Funcționarul recitește, dă din cap, ștampilează. «Este bine scris», spune el. Ioana păstrează fraza asta ani de zile.",
                      [hl("employé", "funcționar", "[ɑ̃.plwa.je]"), hl("tamponner", "a ștampila", "[tɑ̃.pɔ.ne]"), hl("garder", "a păstra", "[gaʁ.de]")],
                      ortho("employé", "Accent ascuțit pe é. La feminin: «employée».", .accents))
            ]
        case 3:
            return [
                scene("Le café du coin ouvre à six heures. Elle commande « un café » et le garçon répond « un café ! » exactement sur le même ton.",
                      "Cafeneaua din colț se deschide la ora șase. Comandă «un café», iar chelnerul repetă «un café!» exact pe același ton.",
                      [hl("café", "cafea", "[ka.fe]"), hl("commander", "a comanda", "[kɔ.mɑ̃.de]"), hl("répondre", "a răspunde", "[ʁe.pɔ̃dʁ]")],
                      ortho("commander", "Doi de m: com-mander. Româna scrie «a comanda».", .roTraps)),
                scene("Au bout d'une semaine, il lui dit « bonjour » avant qu'elle ne l'ait dit. C'est, décide-t-elle, le premier jour où elle habite Paris.",
                      "După o săptămână, el îi spune «bonjour» înainte să apuce ea. Este, decide ea, prima zi în care locuiește la Paris.",
                      [hl("semaine", "săptămână", "[sə.mɛn]"), hl("décider", "a decide", "[de.si.de]"), hl("habiter", "a locui", "[a.bi.te]")],
                      ortho("habiter", "H mut: «j'habite», cu eliziune.", .silentLetters))
            ]
        default:
            return [
                scene("Le voisin du dessus s'appelle monsieur Grandet. Il descend l'escalier lentement, une main sur la rampe, et salue toujours.",
                      "Vecinul de deasupra se numește domnul Grandet. Coboară scara încet, cu o mână pe balustradă, și salută întotdeauna.",
                      [hl("voisin", "vecin", "[vwa.zɛ̃]"), hl("escalier", "scară", "[ɛs.ka.lje]"), hl("saluer", "a saluta", "[sa.lɥe]")],
                      ortho("s'appelle", "Doi de p și doi de l la forma conjugată: ap-pel-le.", .doubleLetters)),
                scene("Un soir, il frappe à sa porte avec un livre. « Vous apprenez le français ? Prenez celui-là. C'est mal écrit, vous verrez les fautes. »",
                      "Într-o seară bate la ușa ei cu o carte. «Învățați franceza? Luați-o pe asta. Este prost scrisă, o să vedeți greșelile.»",
                      [hl("frapper", "a bate", "[fʁa.pe]"), hl("porte", "ușă", "[pɔʁt]"), hl("faute", "greșeală", "[fot]")],
                      ortho("livre", "MASCULIN în franceză: «un livre», deși «cartea» e feminin.", .roTraps))
            ]
        }
    }

    // =========================================================================
    // MARK: - Le secret de la Loire
    // =========================================================================

    private static func loire(chapter: Int) -> [StoryScene] {
        switch chapter {
        case 1:
            return [
                scene("Au château de Villandry, une fenêtre du deuxième étage ne se ferme jamais. On l'a réparée trois fois. Elle s'ouvre toujours à l'aube.",
                      "La castelul Villandry, o fereastră de la etajul doi nu se închide niciodată. A fost reparată de trei ori. Se deschide mereu în zori.",
                      [hl("château", "castel", "[ʃɑ.to]"), hl("fenêtre", "fereastră", "[fə.nɛtʁ]"), hl("aube", "zori", "[ob]")],
                      ortho("fenêtre", "S-ul din «fereastră» a devenit accentul circumflex.", .roTraps)),
                scene("La gardienne raconte l'histoire aux visiteurs. Elle la raconte bien, avec les pauses qu'il faut, et personne ne la croit tout à fait.",
                      "Îngrijitoarea le spune vizitatorilor povestea. O spune bine, cu pauzele necesare, și nimeni nu o crede pe de-a-ntregul.",
                      [hl("gardienne", "îngrijitoare", "[gaʁ.djɛn]"), hl("raconter", "a povesti", "[ʁa.kɔ̃.te]"), hl("croire", "a crede", "[kʁwaʁ]")],
                      ortho("gardienne", "Femininul dublează n-ul: gardien → gardienne.", .plurals))
            ]
        case 2:
            return [
                scene("Derrière le château commence la forêt. Elle descend jusqu'au fleuve et personne n'y coupe plus de bois depuis 1789.",
                      "În spatele castelului începe pădurea. Coboară până la fluviu și nimeni nu mai taie lemne acolo din 1789.",
                      [hl("forêt", "pădure", "[fɔ.ʁɛ]"), hl("fleuve", "fluviu", "[flœv]"), hl("bois", "lemn", "[bwa]")],
                      ortho("forêt", "Ca la «fenêtre»: un s a dispărut sub accent.", .roTraps)),
                scene("Un chêne y porte une entaille ancienne, à hauteur d'homme. Une lettre y est gravée. On distingue une barre, puis un accent.",
                      "Un stejar poartă acolo o crestătură veche, la înălțimea unui om. O literă este gravată. Se distinge o bară, apoi un accent.",
                      [hl("chêne", "stejar", "[ʃɛn]"), hl("graver", "a grava", "[gʁa.ve]"), hl("distinguer", "a distinge", "[dis.tɛ̃.ge]")],
                      ortho("chêne", "Circumflex pe ê. «Chene» fără accent nu există.", .accents))
            ]
        default:
            return [
                scene("Un archiviste finit par comprendre. La lettre gravée est un s : la forme ancienne du mot « forest », avant que l'accent ne le remplace.",
                      "Un arhivar ajunge să înțeleagă. Litera gravată este un s: forma veche a cuvântului «forest», înainte ca accentul să îl înlocuiască.",
                      [hl("archiviste", "arhivar", "[aʁ.ʃi.vist]"), hl("comprendre", "a înțelege", "[kɔ̃.pʁɑ̃dʁ]"), hl("remplacer", "a înlocui", "[ʁɑ̃.pla.se]")],
                      ortho("archiviste", "ch acolo unde româna scrie h: ar-chi-viste.", .roTraps)),
                scene("La fenêtre, dit-il, s'appelait « fenestre ». Elle ne refuse pas de se fermer : elle refuse d'oublier la lettre qu'on lui a prise.",
                      "Fereastra, spune el, se numea «fenestre». Nu refuză să se închidă: refuză să uite litera care i-a fost luată.",
                      [hl("oublier", "a uita", "[u.bli.je]"), hl("prendre", "a lua", "[pʁɑ̃dʁ]"), hl("refuser", "a refuza", "[ʁə.fy.ze]")],
                      ortho("oublier", "Verbul se conjugă «j'oublie», fără accent.", .verbEndings),
                      choice("Ce ai grava tu pe un stejar?",
                             ["Une lettre disparue.", "Un nom.", "Une date."]))
            ]
        }
    }

    // =========================================================================
    // MARK: - Nuit blanche à Montmartre
    // =========================================================================

    private static func montmartre(chapter: Int) -> [StoryScene] {
        switch chapter {
        case 1:
            return [
                scene("Il y a deux cent vingt-deux marches pour monter à Montmartre. Paul les compte à voix haute. Léa lui dit qu'il se trompe depuis la trentième.",
                      "Sunt două sute douăzeci și două de trepte până sus la Montmartre. Paul le numără cu voce tare. Léa îi spune că greșește de la a treizecea.",
                      [hl("marche", "treaptă", "[maʁʃ]"), hl("monter", "a urca", "[mɔ̃.te]"), hl("compter", "a număra", "[kɔ̃.te]")],
                      ortho("compter", "P-ul nu se aude: comp-ter. Ca în «sculpter».", .silentLetters)),
                scene("En haut, la ville est plate et jaune. On voit jusqu'à la Défense. Le vent monte du sud et sent la pluie.",
                      "Sus, orașul este plat și galben. Se vede până la La Défense. Vântul urcă dinspre sud și miroase a ploaie.",
                      [hl("plat", "plat", "[pla]"), hl("vent", "vânt", "[vɑ̃]"), hl("sentir", "a mirosi", "[sɑ̃.tiʁ]")],
                      ortho("vent", "T final mut. Proba: «venteux».", .silentLetters))
            ]
        case 2:
            return [
                scene("Place du Tertre, un portraitiste range ses fusains. Il propose de les dessiner tous les deux pour le prix d'un seul.",
                      "În Place du Tertre, un portretist își strânge cărbunele. Le propune să îi deseneze pe amândoi la prețul unuia singur.",
                      [hl("portraitiste", "portretist", "[pɔʁ.tʁɛ.tist]"), hl("ranger", "a strânge", "[ʁɑ̃.ʒe]"), hl("dessiner", "a desena", "[de.si.ne]")],
                      ortho("dessiner", "Doi de s: des-siner. Cu un singur s: /dəziner/.", .doubleLetters)),
                scene("Il travaille vite. À la fin, il retourne la feuille et écrit deux mots au dos : « à bientôt ». Paul remarque l'accent grave.",
                      "Lucrează repede. La final, întoarce foaia și scrie două cuvinte pe verso: «à bientôt». Paul observă accentul grav.",
                      [hl("feuille", "foaie", "[fœj]"), hl("retourner", "a întoarce", "[ʁə.tuʁ.ne]"), hl("dos", "spate", "[do]")],
                      ortho("à bientôt", "Un accent grav pe à, un circumflex pe ô.", .accents),
                      choice("Ce ai scrie pe spatele unui portret?",
                             ["« à bientôt »", "la date du jour", "rien du tout"]))
            ]
        default:
            return [
                scene("Ils redescendent à quatre heures. Les rues sont lavées, les cafés encore fermés. Un boulanger sort une caisse de pain chaud.",
                      "Coboară la ora patru. Străzile sunt spălate, cafenelele încă închise. Un brutar scoate o ladă cu pâine caldă.",
                      [hl("redescendre", "a coborî", "[ʁə.de.sɑ̃dʁ]"), hl("laver", "a spăla", "[la.ve]"), hl("boulanger", "brutar", "[bu.lɑ̃.ʒe]")],
                      ortho("boulanger", "-er final se citește /e/. Femininul: «boulangère».", .verbEndings)),
                scene("Léa garde le portrait dans son sac pendant des mois. Les deux mots au dos finissent par s'effacer. L'accent, lui, reste lisible.",
                      "Léa ține portretul în geantă luni de zile. Cele două cuvinte de pe verso ajung să se șteargă. Accentul, în schimb, rămâne lizibil.",
                      [hl("sac", "geantă", "[sak]"), hl("s'effacer", "a se șterge", "[se.fa.se]"), hl("lisible", "lizibil", "[li.zibl]")],
                      ortho("s'effacer", "Doi de f: ef-facer.", .doubleLetters))
            ]
        }
    }

    // =========================================================================
    // MARK: - Fabriques
    // =========================================================================

    private static func opening(story: Story) -> StoryScene {
        StoryScene(
            paragraphFrench: "L'histoire commence ici.",
            paragraphNative: "Povestea începe aici.",
            highlightedVocab: [hl("histoire", "poveste", "[is.twaʁ]")],
            choice: nil,
            orthoHighlight: nil)
    }

    private static func scene(_ french: String, _ native: String,
                              _ vocab: [HighlightedWord],
                              _ ortho: StoryScene.OrthoHighlight? = nil,
                              _ choice: StoryChoice? = nil) -> StoryScene {
        StoryScene(paragraphFrench: french, paragraphNative: native,
                   highlightedVocab: vocab, choice: choice, orthoHighlight: ortho)
    }

    private static func hl(_ french: String, _ translation: String, _ ipa: String) -> HighlightedWord {
        HighlightedWord(french: french, translation: translation, phonetic: ipa)
    }

    private static func ortho(_ word: String, _ note: String,
                              _ module: OrthoModule) -> StoryScene.OrthoHighlight {
        StoryScene.OrthoHighlight(word: word, note: note, module: module)
    }

    private static func choice(_ prompt: String, _ options: [String]) -> StoryChoice {
        StoryChoice(prompt: prompt, options: options)
    }
}
