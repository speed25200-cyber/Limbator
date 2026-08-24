import Foundation

/// Une histoire interactive. Les quatre récits de Limbator sont choisis pour
/// parler à un lecteur roumain : deux d'entre eux mettent en scène des Roumains
/// à Paris — l'atelier de Brâncuși et l'arrivée d'une étudiante d'aujourd'hui.
struct Story: Identifiable, Codable, Hashable {
    let id: UUID
    let slug: String
    /// Titre dans la langue de l'apprenant (source roumaine).
    let title: String
    /// Titre français.
    let frenchTitle: String
    let illustrationKey: String
    /// Résumé, source roumaine.
    let synopsis: String
    let chapters: [StoryChapter]
    let difficulty: ProficiencyLevel
    let estimatedMinutes: Int
    /// Le point d'orthographe que le récit travaille en creux.
    let orthoFocus: OrthoModule

    init(id: UUID = .init(), slug: String, title: String, frenchTitle: String,
         illustrationKey: String, synopsis: String, chapters: [StoryChapter],
         difficulty: ProficiencyLevel, estimatedMinutes: Int,
         orthoFocus: OrthoModule) {
        self.id = id; self.slug = slug; self.title = title
        self.frenchTitle = frenchTitle
        self.illustrationKey = illustrationKey
        self.synopsis = synopsis; self.chapters = chapters
        self.difficulty = difficulty; self.estimatedMinutes = estimatedMinutes
        self.orthoFocus = orthoFocus
    }

    var localizedTitle: String    { ContentL10n.s(title) }
    var localizedSynopsis: String { ContentL10n.s(synopsis) }

    static let builtIn: [Story] = [
        Story(
            slug: "brancusi",
            title: "Scrisoarea lui Brâncuși",
            frenchTitle: "La lettre de Brancusi",
            illustrationKey: "atelier",
            synopsis: "Un tânăr sculptor din Hobița ajunge la Paris pe jos. Atelierul din Impasse Ronsin, marmura, tăcerea — și primele lui cuvinte în franceză.",
            chapters: [
                StoryChapter(index: 1, titleNative: "Drumul pe jos",
                             titleFrench: "La longue marche", iconName: "figure.walk"),
                StoryChapter(index: 2, titleNative: "Atelierul alb",
                             titleFrench: "L'atelier blanc", iconName: "hammer.fill"),
                StoryChapter(index: 3, titleNative: "Pasărea",
                             titleFrench: "L'oiseau", iconName: "bird.fill"),
                StoryChapter(index: 4, titleNative: "Scrisoarea acasă",
                             titleFrench: "La lettre au pays", iconName: "envelope.fill")
            ],
            difficulty: .b1, estimatedMinutes: 22, orthoFocus: .accents
        ),
        Story(
            slug: "aller-simple",
            title: "Bilet dus spre Paris",
            frenchTitle: "Un aller simple pour Paris",
            illustrationKey: "gareDuNord",
            synopsis: "Ioana coboară în Gare du Nord cu două valize și un dicționar. Prima zi, prima cafea, primul formular de completat — corect.",
            chapters: [
                StoryChapter(index: 1, titleNative: "Gara de Nord",
                             titleFrench: "Gare du Nord", iconName: "tram.fill"),
                StoryChapter(index: 2, titleNative: "Formularul",
                             titleFrench: "Le formulaire", iconName: "doc.text.fill"),
                StoryChapter(index: 3, titleNative: "Cafeaua de dimineață",
                             titleFrench: "Le café du matin", iconName: "cup.and.saucer.fill"),
                StoryChapter(index: 4, titleNative: "Vecinul de palier",
                             titleFrench: "Le voisin de palier", iconName: "door.left.hand.open")
            ],
            difficulty: .a2, estimatedMinutes: 16, orthoFocus: .homophones
        ),
        Story(
            slug: "loire",
            title: "Secretul Loarei",
            frenchTitle: "Le secret de la Loire",
            illustrationKey: "chateau",
            synopsis: "Un castel, o fereastră care nu se închide niciodată și un cuvânt cu accent circonflex care ascunde o literă dispărută.",
            chapters: [
                StoryChapter(index: 1, titleNative: "Fereastra deschisă",
                             titleFrench: "La fenêtre ouverte", iconName: "window.vertical.open"),
                StoryChapter(index: 2, titleNative: "Pădurea",
                             titleFrench: "La forêt", iconName: "tree.fill"),
                StoryChapter(index: 3, titleNative: "Litera dispărută",
                             titleFrench: "La lettre disparue", iconName: "sparkle")
            ],
            difficulty: .b1, estimatedMinutes: 14, orthoFocus: .roTraps
        ),
        Story(
            slug: "montmartre",
            title: "Noapte albă la Montmartre",
            frenchTitle: "Nuit blanche à Montmartre",
            illustrationKey: "montmartre",
            synopsis: "Doi prieteni, o scară de o sută de trepte și o noapte în care fiecare accent contează.",
            chapters: [
                StoryChapter(index: 1, titleNative: "Scara",
                             titleFrench: "L'escalier", iconName: "stairs"),
                StoryChapter(index: 2, titleNative: "Portretistul",
                             titleFrench: "Le portraitiste", iconName: "paintpalette.fill"),
                StoryChapter(index: 3, titleNative: "Zorii",
                             titleFrench: "L'aube", iconName: "sunrise.fill")
            ],
            difficulty: .a2, estimatedMinutes: 12, orthoFocus: .silentLetters
        )
    ]

    /// Histoire de secours — garantit qu'aucun accès par index ne peut échouer.
    static let fallback = Story(
        slug: "fallback", title: "—", frenchTitle: "—",
        illustrationKey: "seine", synopsis: "—", chapters: [],
        difficulty: .a1, estimatedMinutes: 1, orthoFocus: .accents)

    static func story(slug: String) -> Story {
        builtIn.first(where: { $0.slug == slug }) ?? builtIn.first ?? fallback
    }

    static var first: Story { builtIn.first ?? fallback }

    /// Chapitre sûr : renvoie toujours un chapitre valide (le premier par défaut).
    func chapter(_ index: Int) -> StoryChapter {
        chapters.first(where: { $0.index == index })
            ?? chapters.first
            ?? StoryChapter(index: 1, titleNative: "—", titleFrench: "—", iconName: "book.fill")
    }

    /// Le chapitre suivant celui-ci, s'il existe.
    ///
    /// On avance par **numéro déclaré**, jamais par nombre de chapitres : un
    /// récit dont les chapitres ne seraient pas numérotés 1, 2, 3… laissait la
    /// lecture bloquée avant la fin, ou proposait un chapitre inexistant.
    func chapterIndex(after index: Int) -> Int? {
        chapters.map(\.index).filter { $0 > index }.min()
    }

    func chapterIndex(before index: Int) -> Int? {
        chapters.map(\.index).filter { $0 < index }.max()
    }
}

struct StoryChapter: Identifiable, Codable, Hashable {
    var id: Int { index }
    let index: Int
    /// Titre dans la langue de l'apprenant (source roumaine).
    let titleNative: String
    let titleFrench: String
    let iconName: String        // SF Symbol

    var localizedTitleNative: String { ContentL10n.s(titleNative) }
}

/// Une scène : un paragraphe français, sa traduction, du vocabulaire mis en
/// lumière, et parfois un embranchement narratif.
struct StoryScene: Codable, Identifiable, Hashable {
    let id: UUID
    let paragraphFrench: String
    /// Traduction dans la langue de l'apprenant (source roumaine).
    let paragraphNative: String
    let highlightedVocab: [HighlightedWord]
    let choice: StoryChoice?
    /// Le mot du paragraphe qui mérite un arrêt orthographique (nil si aucun).
    let orthoHighlight: OrthoHighlight?

    init(id: UUID = .init(), paragraphFrench: String, paragraphNative: String,
         highlightedVocab: [HighlightedWord], choice: StoryChoice? = nil,
         orthoHighlight: OrthoHighlight? = nil) {
        self.id = id; self.paragraphFrench = paragraphFrench
        self.paragraphNative = paragraphNative
        self.highlightedVocab = highlightedVocab
        self.choice = choice; self.orthoHighlight = orthoHighlight
    }

    var localizedParagraphNative: String { ContentL10n.s(paragraphNative) }

    /// L'arrêt sur image orthographique d'une scène.
    struct OrthoHighlight: Codable, Hashable {
        /// Le mot français concerné, tel qu'il apparaît dans le paragraphe.
        let word: String
        /// L'explication, source roumaine.
        let note: String
        let module: OrthoModule

        var localizedNote: String { ContentL10n.s(note) }
    }
}

struct HighlightedWord: Codable, Hashable, Identifiable {
    var id: String { french }
    let french: String
    /// Traduction, source roumaine.
    let translation: String
    let phonetic: String

    var localizedTranslation: String { ContentL10n.s(translation) }
}

struct StoryChoice: Codable, Hashable {
    /// Question posée, source roumaine.
    let prompt: String
    /// Options — en français (c'est aussi un exercice de lecture).
    let options: [String]

    var localizedPrompt: String { ContentL10n.s(prompt) }
}
