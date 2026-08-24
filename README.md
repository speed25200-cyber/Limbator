# Limbator

> **Învață franceza din română.** Gemma 4 4B en local pour la pédagogie, voix
> neurale française sur l'appareil, et un correcteur d'orthographe qui explique
> au lieu de sanctionner. 100 % iPhone, 100 % hors ligne.

---

## Ce que fait Limbator, et pourquoi

Apprendre le français quand on parle roumain part avec un avantage considérable
et un piège permanent. Neuf mots savants sur dix se ressemblent — et la
ressemblance s'arrête à l'orthographe. *Atenție* donne **attention** avec deux
t. *Adresă* donne **adresse** avec deux s. *Fereastră* donne **fenêtre**, où le
s latin a disparu sous un accent circonflexe.

C'est là que Limbator travaille. Pas sur le vocabulaire — que le roumanophone
devine — mais sur l'écrit, où il se trompe.

La différence tient dans un seul composant : **un correcteur qui ne dit pas
« faux », mais dit pourquoi.**

Écrire *a* pour *à* n'est pas un accent oublié : c'est une confusion entre deux
mots, et la réponse utile n'est pas « n'oublie pas l'accent » mais *« remplace
par avait : si la phrase tient, c'est le verbe »*. Écrire *peti* pour *petit*
n'est pas une confusion de mots : c'est une lettre muette oubliée, et la réponse
utile est *« cherche le féminin : petite »*. Écrire *atention* n'est ni l'un ni
l'autre : c'est le roumain qui parle, et il faut le nommer.

Vingt-trois catégories de fautes, chacune avec son explication, son test de
substitution et sa règle. C'est tout ce que l'application est.

---

## L'architecture en une page

| Couche | Technologie | Où |
|---|---|---|
| Interface | SwiftUI · iOS 17+ · sombre exclusif | — |
| Modèle | **Gemma 4 4B** 4 bits via MLX-Swift (Neural Engine + Metal) | appareil |
| Voix | **VITS Piper fr_FR** via sherpa-onnx, féminine et masculine | appareil |
| Voix (option) | Azure neural fr-FR, expressif | réseau |
| Voix (repli) | Apple Premium / Enhanced fr-FR | appareil |
| Correction | Moteur d'orthographe écrit à la main | appareil |
| Planification | SM-2 sur les règles et les mots | appareil |
| Illustrations | Formes SwiftUI vectorielles | — |

**Aucun appel réseau** après le premier téléchargement du modèle. Aucun emoji.
Aucune télémétrie.

### Le moteur d'orthographe

Trois fichiers portent l'essentiel de la valeur de l'app.

**`FrenchPhonology`** phonétise le français. Pas une transcription API complète :
une *clé de son*, volontairement grossière, faite pour que les homophones se
rencontrent. Sans elle, impossible de distinguer une faute de son (l'apprenant a
mal entendu) d'une faute de règle (il a mal choisi) — la distinction qui décide
de toute la correction. Elle sait que le `-ent` de « ils parlent » ne se
prononce pas, que le tréma de « naïf » interdit la lecture en digramme, et que
« est » ne se lit pas comme il s'écrit.

**`OrthographyEngine`** aligne l'attendu et l'écrit par Needleman-Wunsch sur les
jetons — avec un coût de substitution modulé par la ressemblance, pour que deux
graphies proches restent appariées au lieu de produire une suppression suivie
d'une insertion. Puis il descend au caractère, et classe l'écart. L'ordre des
tests va du plus explicatif au plus générique : on ne répond jamais « faute de
frappe » quand on peut répondre « accord du participe passé ».

**`RomanianInterference`** contient soixante-huit pièges nommés, dont le plus
beau pont entre les deux langues : **là où le roumain a gardé le S latin, le
français a mis un accent circonflexe.** *fereastră* → **fenêtre**, *spital* →
**hôpital**, *insulă* → **île**, *coastă* → **côte**, *gust* → **goût**. Une
seule règle couvre des dizaines de mots, et une fois vue, elle ne s'oublie plus.

### Gemma enrichit, mais ne peut pas se tromper devant l'apprenant

Un modèle de quatre milliards de paramètres écrit un français convaincant — et
invente. Il place un accent de trop, propose un homophone comme bonne réponse,
accorde un participe qui ne doit pas l'être. En orthographe, un énoncé fautif
est pire que pas d'énoncé du tout : l'apprenant retient la faute.

La règle appliquée partout est donc la même :

> **Le contenu vérifié est la source de vérité. Gemma enrichit, puis sa sortie
> est réancrée sur les valeurs vérifiées ; ce qui ne peut pas l'être est jeté.**

Concrètement : la liste de vocabulaire lui est donnée et il ne peut pas en
sortir ; ses exemples ne sont retenus que s'ils contiennent réellement le mot ;
ses dictées ne passent que si elles mettent vraiment à l'épreuve la règle
annoncée ; et **les exercices d'orthographe ne lui sont jamais confiés** — ils
viennent des banques vérifiées, où la bonne réponse est juste par construction.

---

## Le contenu

Tout est écrit à la main, en roumain, et vérifié.

| | |
|---|---|
| Familles d'homophones | **24**, chacune avec son test de substitution |
| Règles d'orthographe | **52** (28 rédigées + 24 dérivées des familles) |
| Exercices | **84** écrits à la main + un par graphie d'homophone |
| Dictées | **57**, de A1 à C1, chacune ciblant des règles nommées |
| Cartes de vocabulaire | **169**, réparties sur 14 leçons |
| Pièges roumain / français | **68** |
| Récits interactifs | **4** |

### Les huit chantiers de l'orthographe

Accents · Homophones · Terminaisons verbales · Accords · Pluriels et féminins ·
Consonnes doubles · Lettres muettes · **Pièges roumano-français**

Chacun affiche sa maîtrise — non pas un pourcentage d'exercices faits, mais la
**force de mémoire** calculée par la répétition espacée. La nuance est décisive :
on peut avoir tout réussi hier et n'avoir rien retenu.

### Les récits

Deux des quatre partent de Roumanie, ce qui n'est pas une coquetterie : un
apprenant lit mieux, et retient davantage, quand le texte le concerne.

- **Scrisoarea lui Brâncuși** — un sculpteur de Hobița arrive à Paris à pied en
  1904. L'atelier de l'impasse Ronsin, le marbre, et ses premiers mots de
  français.
- **Bilet dus spre Paris** — Ioana descend gare du Nord avec deux valises et un
  dictionnaire. Premier formulaire à remplir, correctement.
- **Secretul Loarei** — un château, une fenêtre qui ne se ferme jamais, et un
  accent circonflexe qui cache une lettre disparue.
- **Noapte albă la Montmartre** — deux amis, cent marches, et une nuit où chaque
  accent compte.

Chaque scène porte un **arrêt sur mot** : un terme du paragraphe dont
l'orthographe mérite qu'on s'arrête. Le récit devient une leçon déguisée — la
seule forme de leçon qu'on lise volontiers.

---

## L'icône

Un **É** didone — le classique typographique français, à fort contraste entre
pleins et déliés — surmonté d'un accent aigu détaché, en or.

Le motif n'est pas décoratif. En français, l'accent ne se pose pas sur une
lettre : il en fait partie. *Eleve* n'est pas *élève* mal écrit, c'est un mot qui
n'existe pas. Montrer l'accent séparé, dans une autre matière que la lettre, dit
exactement ce que l'application enseigne.

L'icône est **engendrée par un script** (`scripts/make_app_icon.py`) et
l'intégration continue vérifie qu'elle se régénère à l'octet près. Elle vérifie
aussi, en analysant les pixels dorés, que l'accent **monte vers la droite** :
l'aigu monte (é), le grave descend (è), et une application qui corrige
l'orthographe ne peut pas afficher une faute sur l'écran d'accueil.

---

## Construire

```bash
git clone https://github.com/speed25200-cyber/Limbator.git
cd Limbator

# 1. Vérification statique — quelques secondes, aucune dépendance Apple
pip install tree-sitter tree-sitter-swift Pillow pyyaml
./scripts/run_all_checks.sh

# 2. Voix neurales françaises (~150 Mo, non versionnées)
./scripts/download_voice.sh

# 3. Projet Xcode (project.yml est la source de vérité)
brew install xcodegen && xcodegen generate
open Limbator.xcodeproj
```

Dans Xcode : choisir son équipe de signature, puis **Cmd-U** pour les tests,
**Cmd-R** pour lancer sur un iPhone 14 Pro ou plus récent (iOS 17+).

Au premier lancement, l'app est **immédiatement utilisable** : tout le contenu
pédagogique est embarqué. Gemma se télécharge en arrière-plan, avec un bandeau
qui montre l'avancée réelle — pourcentage, mégaoctets, débit — et, en cas
d'échec, la cause exacte et un bouton pour réessayer.

### Choix du modèle

Limbator vise **Gemma 4 4B** en 4 bits : le meilleur rapport qualité/mémoire
pour du français correct — un modèle plus petit hésite sur les accords et
invente des accents. Une variante plus légère est gardée en second : sur un
iPhone dont la mémoire est déjà entamée, mieux vaut un modèle qui se charge
qu'un modèle idéal que le système tue. Le choix se fait au premier lancement et
se retient.

---

## Vérification

Le compilateur Swift n'existe pas sur Linux, et les minutes macOS coûtent cher.
Treize contrôles tournent donc en quelques secondes, avant toute compilation.

```
1.  Syntaxe Swift              tree-sitter, 61 fichiers
2.  Pièges de compilation      arité de buildBlock, @ViewBuilder, chemins de clé
3.  Références                 types, cas d'énumération, 208 clés de traduction
4.  Switch exhaustifs          22 switch sur énumération
5.  Chaînes de format          arguments cohérents dans les trois langues
6.  Logique d'orthographe      31 groupes phonétiques, 36 classifications
7.  Contenu pédagogique        84 exercices, 57 dictées, cohérence croisée
8.  Risques d'arrêt brutal     déballage forcé, try!, fatalError, indexation
9.  Fichiers structurés        JSON, plist, xcprivacy, schémas
10. Configuration              project.yml et codemagic.yaml cohérents
11. Aucun emoji
12. Ressources indispensables
13. Orientation de l'accent    analyse des pixels de l'icône
```

Le contrôle 2 cherche trois fautes que rien ne signale sans compilateur, et dont
le message d'Xcode ne désigne même pas la ligne : un conteneur SwiftUI qui
dépasse dix vues filles, une fonction `some View` qui se ramifie sans
`@ViewBuilder`, et un chemin de clé pointant vers une étiquette de tuple —
`\.mark` sur un `(index: Int, mark: Character)` ne compile pas, alors que
`{ $0.mark }` passe. La troisième règle a été écrite après avoir commis
exactement cette faute.

Le contrôle 6 mérite un mot. `scripts/ortho_port.py` est une transposition
Python fidèle du moteur d'orthographe, et `exec_ortho_logic.py` la fait tourner
sur du vrai français — en lisant les tables (pièges roumains, familles
d'homophones) **directement dans les sources Swift**, pour qu'elles ne puissent
pas diverger en silence. Cette approche a déjà attrapé quatre bugs réels : un
accent grave dessiné à la place d'un aigu dans l'icône, une graphie « fautive »
qui était la bonne, une réponse figurant parmi ses propres leurres, et deux
indexations de tableau capables de fermer l'app au lancement.

Côté Xcode, trois suites XCTest couvrent le moteur, le contenu et la
progression.

---

## Confidentialité

- Toutes les données restent **sur l'appareil**. Aucune télémétrie, aucun SDK
  de suivi.
- `PrivacyInfo.xcprivacy` ne déclare que `UserDefaults`, `FileTimestamp`,
  `DiskSpace` et `SystemBootTime`.
- Le micro n'est demandé que pour le studio vocal.
- Le modèle Gemma se télécharge une fois depuis HuggingFace, puis plus rien.
- **Aucune clé d'API n'est inscrite dans ce dépôt.** La voix Azure, facultative,
  se configure depuis l'app ou par variable secrète d'intégration continue.

---

## Limites connues

Dites franchement plutôt que découvertes à l'usage.

- **La note de prononciation est approximative.** Une évaluation acoustique
  réelle demande un encodeur audio embarqué que Limbator n'a pas encore ; la
  note actuelle se fonde sur la durée rapportée à la longueur attendue.
  L'interface le dit à l'utilisateur au lieu de faire passer un nombre pour une
  mesure.
- **La traduction du contenu long s'arrête au roumain.** L'interface est
  complète en roumain, français et anglais (229 clés) ; les noms de modules, de
  niveaux, de thèmes, de règles et les catégories de fautes aussi (249 entrées).
  Les énoncés de règles et les explications d'exercices, en revanche, restent en
  roumain quand on change de langue — le repli affiche la chaîne source, donc
  rien ne disparaît de l'écran. Pour étendre : une seule table, dans
  `scripts/gen_content_l10n.py`.
- **espeak-ng est sous GPL v3.** Voir [VOIX.md](VOIX.md) avant toute
  distribution commerciale.
- **Le phonétiseur est approché.** Il vise la collision des homophones, pas
  l'exactitude API. Quelques mots rares sont lus de travers ; aucun ne crée de
  fausse paire d'homophones dans le corpus vérifié.

---

## Structure

```
Limbator/
├── LimbatorApp.swift
├── Models/          Language · Lesson · Orthography · Story · Game · User
├── Services/
│   ├── OrthographyEngine       alignement, diff, classification en 23 catégories
│   ├── OrthoExplainer          ce qu'on dit à l'apprenant devant chaque faute
│   ├── RomanianInterference    68 pièges roumain / français
│   ├── OrthoSeeds · OrthoRules · OrthoDrills · DictationBank
│   ├── GemmaService            Gemma 4 4B, coupe-circuit anti boucle de plantage
│   ├── ContentGenerator        Gemma enrichit, puis on réancre
│   ├── TTSService              cascade à quatre moteurs, quatre modes de lecture
│   ├── FrenchSpeller           épellation avec les accents nommés
│   ├── SpacedRepetition        SM-2
│   └── ContentSeeds · StorySeeds · GameSeeds
├── Views/
│   ├── Orthographe/            le cœur : dictée, modules, exercices
│   ├── Lessons/ Games/ Stories/ Home/ Profile/ Onboarding/
│   └── Components/             OrthoDiffView, ListenBar, AccentEmblem…
├── Utilities/       FrenchPhonology · Theme · Localizer (engendré)
└── Resources/       Info.plist · PrivacyInfo.xcprivacy · Assets · Voice/
```

Trois fichiers sont **engendrés** et ne doivent pas être modifiés à la main —
`Localizer.swift`, `ContentTranslations.swift` et `AppIcon-1024.png`. La CI
vérifie qu'ils correspondent à leurs générateurs.
