import SwiftUI

/// Palette « Nuit Française » — encre de nuit, bleu de France, or champagne.
/// Pensée pour un rendu haut de gamme en mode sombre exclusif : fonds profonds
/// non saturés, accents métalliques, un seul rouge (jamais deux rouges côte à côte).
enum Theme {

    // MARK: - Couleurs de marque

    /// Fond le plus profond (quasi noir, légèrement bleuté).
    static let encre       = Color(hex: 0x05060F)
    /// Fond secondaire (cartes pleines, feuilles).
    static let nuit        = Color(hex: 0x0B1026)
    /// Bleu de France modernisé — couleur d'action principale.
    static let bleuFrance  = Color(hex: 0x2A6DF4)
    /// Indigo profond — dégradés, halo.
    static let indigo      = Color(hex: 0x4361EE)
    /// Violet lavande — IA / Gemma.
    static let lavande     = Color(hex: 0x8B6BFF)
    /// Or champagne — l'accent de marque (accents orthographiques, réussite).
    static let or          = Color(hex: 0xE8C56A)
    /// Or clair pour les hautes lumières.
    static let orClair     = Color(hex: 0xF5E1A4)
    /// Grenat — erreurs, alertes, drapeau.
    static let grenat      = Color(hex: 0xE4344A)
    /// Émeraude — validation, progression.
    static let emeraude    = Color(hex: 0x2ED9A3)
    /// Azur — écoute / audio.
    static let azur        = Color(hex: 0x4FD1F5)
    /// Rose poudré — dictée / expression.
    static let rose        = Color(hex: 0xFF7BA9)
    /// Ivoire — texte chaud sur fond sombre.
    static let ivoire      = Color(hex: 0xFFF6E9)

    static let glass       = Color.white.opacity(0.06)
    static let glassEdge   = Color.white.opacity(0.18)

    // MARK: - Dégradés

    static let primaryGradient = LinearGradient(
        colors: [bleuFrance, indigo, lavande],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Dégradé « or » réservé aux moments de réussite et aux accents.
    static let goldGradient = LinearGradient(
        colors: [orClair, or, Color(hex: 0xC79A3F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let nightGradient = LinearGradient(
        colors: [Color(hex: 0x05060F), Color(hex: 0x0B1026), Color(hex: 0x160A2E)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let auroraGradient = LinearGradient(
        colors: [bleuFrance, lavande, rose, or],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Tricolore stylisé (jamais utilisé brut : toujours adouci).
    static let tricolore = LinearGradient(
        colors: [bleuFrance, ivoire, grenat],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Typographie

    enum Typography {
        static let display     = Font.system(size: 42, weight: .black,    design: .rounded)
        static let title       = Font.system(size: 28, weight: .heavy,    design: .rounded)
        static let headline    = Font.system(size: 22, weight: .bold,     design: .rounded)
        static let body        = Font.system(size: 17, weight: .medium,   design: .rounded)
        static let caption     = Font.system(size: 13, weight: .semibold, design: .rounded)
        /// Réservée aux mots français analysés lettre par lettre (dictée, diff).
        static let ortho       = Font.system(size: 26, weight: .bold,     design: .serif)
        static let orthoSmall  = Font.system(size: 19, weight: .semibold, design: .serif)
        static let monoLarge   = Font.system(size: 32, weight: .black,    design: .monospaced)
        static let mono        = Font.system(size: 15, weight: .semibold, design: .monospaced)
    }

    // MARK: - Apparence globale

    static func applyGlobalAppearance() {
        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        tab.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Theme.glassEdge, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 10)
        )
    }

    func glow(_ color: Color, radius: CGFloat = 18) -> some View {
        self.shadow(color: color.opacity(0.55), radius: radius)
            .shadow(color: color.opacity(0.25), radius: radius * 2)
    }

    /// Liseré doré discret — utilisé pour distinguer un élément « maîtrisé ».
    func goldRim(cornerRadius: CGFloat = 24, lineWidth: CGFloat = 1.2) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Theme.goldGradient, lineWidth: lineWidth)
        )
    }
}
