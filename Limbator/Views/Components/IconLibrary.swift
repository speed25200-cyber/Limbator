import SwiftUI

/// Les icônes de Limbator. Aucun emoji, aucune dépendance : des symboles
/// système pour la navigation, et des dessins vectoriels faits main là où le
/// système n'a rien à proposer — un accent aigu, une plume, une lettre muette.
enum LimbIcon: String, CaseIterable {
    // Navigation
    case home, lessons, ortho, games, stories, profile, settings, close
    case chevronRight, chevronLeft

    // Apprentissage
    case speaker, speakerWaves, ear, mic, micFill, headphones, sparkles
    case flame, star, starFilled, trophy, medal, crown
    case bookOpen, bookmark, layers, brain, target, quill, accent, duel

    // Thèmes de leçon
    case greeting, numbers, family, food, city, shoppingBag, cloudSun, gear
    case heart, briefcase, plane, theatre, clock

    // Jeux
    case puzzlePiece, lightning, fork, wheel, shuffle
    case checkCircle, xCircle

    var systemName: String {
        switch self {
        case .home:          return "house.fill"
        case .lessons:       return "book.closed.fill"
        case .ortho:         return "textformat.abc.dottedunderline"
        case .games:         return "gamecontroller.fill"
        case .stories:       return "books.vertical.fill"
        case .profile:       return "person.crop.circle.fill"
        case .settings:      return "gearshape.fill"
        case .close:         return "xmark"
        case .chevronRight:  return "chevron.right"
        case .chevronLeft:   return "chevron.left"
        case .speaker:       return "speaker.wave.2.fill"
        case .speakerWaves:  return "speaker.wave.3.fill"
        case .ear:           return "ear.fill"
        case .mic:           return "mic"
        case .micFill:       return "mic.fill"
        case .headphones:    return "headphones"
        case .sparkles:      return "sparkles"
        case .flame:         return "flame.fill"
        case .star:          return "star"
        case .starFilled:    return "star.fill"
        case .trophy:        return "trophy.fill"
        case .medal:         return "medal.fill"
        case .crown:         return "crown.fill"
        case .bookOpen:      return "book.fill"
        case .bookmark:      return "bookmark.fill"
        case .layers:        return "square.3.layers.3d.down.right"
        case .brain:         return "brain.head.profile"
        case .target:        return "target"
        case .quill:         return "pencil.and.scribble"
        case .accent:        return "character.textbox"
        case .duel:          return "arrow.triangle.branch"
        case .greeting:      return "hand.wave.fill"
        case .numbers:       return "number.square.fill"
        case .family:        return "figure.2.and.child.holdinghands"
        case .food:          return "fork.knife"
        case .city:          return "building.2.fill"
        case .shoppingBag:   return "bag.fill"
        case .cloudSun:      return "cloud.sun.fill"
        case .gear:          return "function"
        case .heart:         return "heart.fill"
        case .briefcase:     return "briefcase.fill"
        case .plane:         return "airplane"
        case .theatre:       return "theatermasks.fill"
        case .clock:         return "clock.fill"
        case .puzzlePiece:   return "puzzlepiece.extension.fill"
        case .lightning:     return "bolt.fill"
        case .fork:          return "arrow.triangle.branch"
        case .wheel:         return "circle.hexagongrid.fill"
        case .shuffle:       return "shuffle"
        case .checkCircle:   return "checkmark.circle.fill"
        case .xCircle:       return "xmark.circle.fill"
        }
    }
}

/// Une icône avec dégradé et halo. Le halo n'est pas décoratif : il sert à
/// distinguer d'un coup d'œil un élément actif d'un élément au repos.
struct LimbIconView: View {
    let icon: LimbIcon
    var size: CGFloat = 24
    var gradient: LinearGradient = LinearGradient(
        colors: [.white, Color.white.opacity(0.82)], startPoint: .top, endPoint: .bottom)
    var glow: Color? = nil
    var weight: Font.Weight = .semibold

    var body: some View {
        Image(systemName: icon.systemName)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(gradient)
            .modifier(GlowModifier(color: glow, radius: size * 0.4))
    }
}

private struct GlowModifier: ViewModifier {
    let color: Color?
    let radius: CGFloat

    func body(content: Content) -> some View {
        if let color {
            content
                .shadow(color: color.opacity(0.7), radius: radius * 0.5)
                .shadow(color: color.opacity(0.3), radius: radius)
        } else {
            content
        }
    }
}

// =============================================================================
// MARK: - Illustrations vectorielles
// =============================================================================

/// Les illustrations de Limbator, dessinées en SwiftUI plutôt qu'importées.
/// Résolution infinie, animables, et surtout : elles suivent la palette au lieu
/// d'imposer la leur.
enum LimbIllustration: String {
    case accentMark      // L'emblème : un É stylisé, accent détaché
    case atelier         // L'atelier de Brancusi : marbre, lumière, silence
    case gareDuNord      // Une verrière de gare
    case chateau         // Un château de la Loire au bord de l'eau
    case montmartre      // Toits et coupole
    case seine           // Le fleuve et ses ponts
}

struct LimbIllustrationView: View {
    let illustration: LimbIllustration
    var primary: Color = Theme.or
    var secondary: Color = Theme.bleuFrance
    var background: [Color] = [Theme.nuit, Theme.encre]

    var body: some View {
        ZStack {
            LinearGradient(colors: background, startPoint: .topLeading, endPoint: .bottomTrailing)
            switch illustration {
            case .accentMark: AccentEmblem(primary: primary, secondary: secondary)
            case .atelier:    AtelierScene(primary: primary, secondary: secondary)
            case .gareDuNord: StationScene(primary: primary, secondary: secondary)
            case .chateau:    ChateauScene(primary: primary, secondary: secondary)
            case .montmartre: MontmartreScene(primary: primary, secondary: secondary)
            case .seine:      SeineScene(primary: primary, secondary: secondary)
            }
        }
    }
}

// =============================================================================
// MARK: - L'emblème : É
// =============================================================================

/// L'emblème de Limbator : un **É** didone, l'accent détaché.
///
/// Le même dessin que l'icône de l'app — mêmes proportions, même accent taillé
/// en coin. Un logo qui diffère de son icône donne à l'application deux
/// identités et n'en installe aucune.
///
/// Le choix du motif est pédagogique avant d'être graphique : en français
/// l'accent n'est pas un ornement posé sur une lettre, il fait partie du mot.
/// « Eleve » n'est pas « élève » mal écrit, c'est un mot qui n'existe pas.
struct AccentEmblem: View {
    var primary: Color = Theme.or
    var secondary: Color = Theme.bleuFrance
    /// Animation d'entrée : l'accent vient se poser au-dessus de la lettre.
    var animated: Bool = false

    @State private var settled = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)

            ZStack {
                // Halo : détache l'emblème du fond sans lui ajouter de cadre.
                Circle()
                    .fill(RadialGradient(colors: [secondary.opacity(0.42), .clear],
                                         center: .center,
                                         startRadius: side * 0.04,
                                         endRadius: side * 0.52))

                DidoneE()
                    .fill(LinearGradient(colors: [.white, Theme.ivoire.opacity(0.86)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: side * 0.46, height: side * 0.50)
                    .offset(y: side * 0.10)
                    .shadow(color: .black.opacity(0.45), radius: side * 0.02, y: side * 0.012)

                AcuteAccent()
                    .fill(LinearGradient(colors: [Theme.orClair, primary, Color(hex: 0xB88A38)],
                                         startPoint: .topTrailing, endPoint: .bottomLeading))
                    .frame(width: side * 0.20, height: side * 0.11)
                    .shadow(color: primary.opacity(0.8), radius: side * 0.035)
                    .offset(x: side * 0.02,
                            y: side * (settled || !animated ? -0.24 : -0.40))
                    .opacity(settled || !animated ? 1 : 0.15)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                guard animated else { return }
                withAnimation(.spring(response: 0.85, dampingFraction: 0.58).delay(0.28)) {
                    settled = true
                }
            }
        }
    }
}

/// Un E de style didone : hampe pleine, barres en déliés, empattements marqués.
/// Le contraste entre les deux — et non la présence d'empattements — est ce qui
/// fait lire « typographie française ».
struct DidoneE: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let x = rect.minX, y = rect.minY

        let stem = w * 0.205
        let hair = h * 0.058
        let serifW = w * 0.038
        let serifH = h * 0.040
        let topLen = w * 0.800
        let midLen = w * 0.615
        let botLen = w * 0.880
        let midY = y + h * 0.455 - hair * 0.5

        var path = Path()

        // Hampe.
        path.addRect(CGRect(x: x, y: y, width: stem, height: h))

        // Barres légèrement fuselées : plus épaisses contre la hampe.
        func bar(_ top: CGFloat, _ length: CGFloat, _ thickness: CGFloat) {
            let near = thickness * 1.09
            let far = thickness * 0.91
            var arm = Path()
            arm.move(to: CGPoint(x: x, y: top - (near - thickness) / 2))
            arm.addLine(to: CGPoint(x: x + length, y: top + (thickness - far) / 2))
            arm.addLine(to: CGPoint(x: x + length, y: top + thickness - (thickness - far) / 2))
            arm.addLine(to: CGPoint(x: x, y: top + thickness + (near - thickness) / 2))
            arm.closeSubpath()
            path.addPath(arm)
        }
        bar(y, topLen, hair)
        bar(midY, midLen, hair * 0.88)
        bar(y + h - hair, botLen, hair)

        // Empattements aux terminaux des barres.
        path.addRect(CGRect(x: x + topLen - serifW, y: y - serifH,
                            width: serifW, height: hair + serifH * 2))
        path.addRect(CGRect(x: x + midLen - serifW * 0.85, y: midY - serifH * 0.8,
                            width: serifW * 0.85, height: hair + serifH * 1.6))
        path.addRect(CGRect(x: x + botLen - serifW, y: y + h - hair - serifH,
                            width: serifW, height: hair + serifH * 2))

        // Empattements de la hampe.
        path.addRect(CGRect(x: x - serifW * 0.9, y: y - serifH * 0.5,
                            width: stem + serifW * 1.25, height: hair + serifH * 0.5))
        path.addRect(CGRect(x: x - serifW * 0.9, y: y + h - hair,
                            width: stem + serifW * 1.25, height: hair + serifH * 0.5))

        return path
    }
}

/// L'accent aigu : un coin qui **monte vers la droite**, épais en haut.
///
/// Le sens n'est pas une préférence graphique. L'aigu monte (é), le grave
/// descend (è), et les deux notent des sons différents. Les dessiner à
/// l'identique serait afficher une faute dans une application qui corrige.
struct AcuteAccent: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let thin = rect.height * 0.30
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - thin * 0.55))
        path.closeSubpath()
        return path
    }
}

// =============================================================================
// MARK: - Scènes
// =============================================================================

private struct AtelierScene: View {
    let primary: Color
    let secondary: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // Rai de lumière oblique : l'atelier de l'impasse Ronsin en vivait.
                Path { path in
                    path.move(to: CGPoint(x: w * 0.18, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.52, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.86, y: h))
                    path.addLine(to: CGPoint(x: w * 0.40, y: h))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [Color.white.opacity(0.16), .clear],
                                     startPoint: .top, endPoint: .bottom))

                // Colonne sans fin, stylisée : losanges empilés.
                VStack(spacing: -h * 0.012) {
                    ForEach(0..<5, id: \.self) { _ in
                        Diamond()
                            .fill(LinearGradient(colors: [primary, primary.opacity(0.55)],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: w * 0.17, height: h * 0.17)
                    }
                }
                .offset(x: -w * 0.16, y: h * 0.04)
                .shadow(color: primary.opacity(0.45), radius: 14)

                // L'oiseau : une seule courbe, comme la sculpture.
                Path { path in
                    path.move(to: CGPoint(x: w * 0.62, y: h * 0.82))
                    path.addQuadCurve(to: CGPoint(x: w * 0.74, y: h * 0.18),
                                      control: CGPoint(x: w * 0.58, y: h * 0.44))
                }
                .stroke(LinearGradient(colors: [secondary, Theme.orClair],
                                       startPoint: .bottom, endPoint: .top),
                        style: StrokeStyle(lineWidth: w * 0.055, lineCap: .round))
                .shadow(color: secondary.opacity(0.5), radius: 12)
            }
        }
    }
}

private struct StationScene: View {
    let primary: Color
    let secondary: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // Verrière : arcs concentriques.
                ForEach(0..<4, id: \.self) { index in
                    let inset = CGFloat(index) * w * 0.07
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.08 + inset, y: h * 0.86))
                        path.addQuadCurve(to: CGPoint(x: w * 0.92 - inset, y: h * 0.86),
                                          control: CGPoint(x: w * 0.5, y: h * (0.10 + Double(index) * 0.09)))
                    }
                    .stroke(secondary.opacity(0.85 - Double(index) * 0.16),
                            style: StrokeStyle(lineWidth: max(1.5, w * 0.012), lineCap: .round))
                }
                // Rails fuyants.
                ForEach(0..<3, id: \.self) { index in
                    Path { path in
                        let offset = CGFloat(index - 1) * w * 0.14
                        path.move(to: CGPoint(x: w * 0.5 + offset * 0.3, y: h * 0.86))
                        path.addLine(to: CGPoint(x: w * 0.5 + offset, y: h))
                    }
                    .stroke(primary.opacity(0.7), lineWidth: max(1, w * 0.01))
                }
                // Horloge de quai.
                Circle()
                    .stroke(primary, lineWidth: max(1.5, w * 0.014))
                    .frame(width: w * 0.15)
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: w * 0.075, y: w * 0.075))
                            path.addLine(to: CGPoint(x: w * 0.075, y: w * 0.032))
                            path.move(to: CGPoint(x: w * 0.075, y: w * 0.075))
                            path.addLine(to: CGPoint(x: w * 0.110, y: w * 0.075))
                        }
                        .stroke(primary, style: StrokeStyle(lineWidth: max(1, w * 0.009), lineCap: .round))
                    )
                    .position(x: w * 0.5, y: h * 0.30)
                    .shadow(color: primary.opacity(0.6), radius: 10)
            }
        }
    }
}

private struct ChateauScene: View {
    let primary: Color
    let secondary: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // Trois tours coniques.
                ForEach(0..<3, id: \.self) { index in
                    let x = w * (0.28 + Double(index) * 0.22)
                    let towerHeight = h * (index == 1 ? 0.42 : 0.32)
                    Group {
                        Rectangle()
                            .fill(secondary.opacity(0.9))
                            .frame(width: w * 0.11, height: towerHeight)
                        Triangle()
                            .fill(LinearGradient(colors: [primary, primary.opacity(0.6)],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: w * 0.15, height: h * 0.16)
                            .offset(y: -towerHeight / 2 - h * 0.08)
                    }
                    .position(x: x, y: h * 0.60)
                }
                // La Loire : deux ondulations.
                ForEach(0..<2, id: \.self) { index in
                    Path { path in
                        let y = h * (0.80 + Double(index) * 0.07)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addCurve(to: CGPoint(x: w, y: y),
                                      control1: CGPoint(x: w * 0.3, y: y - h * 0.04),
                                      control2: CGPoint(x: w * 0.7, y: y + h * 0.04))
                    }
                    .stroke(Theme.azur.opacity(0.75 - Double(index) * 0.25),
                            style: StrokeStyle(lineWidth: max(1.5, w * 0.014), lineCap: .round))
                }
            }
        }
    }
}

private struct MontmartreScene: View {
    let primary: Color
    let secondary: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // La coupole.
                Path { path in
                    path.move(to: CGPoint(x: w * 0.34, y: h * 0.62))
                    path.addQuadCurve(to: CGPoint(x: w * 0.66, y: h * 0.62),
                                      control: CGPoint(x: w * 0.5, y: h * 0.16))
                }
                .fill(LinearGradient(colors: [Color.white.opacity(0.95), secondary.opacity(0.7)],
                                     startPoint: .top, endPoint: .bottom))
                // Les toits.
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(secondary.opacity(0.35 + Double(index) * 0.09))
                        .frame(width: w * 0.15, height: h * (0.14 + Double(index % 3) * 0.06))
                        .position(x: w * (0.10 + Double(index) * 0.2), y: h * 0.86)
                }
                // Un escalier suggéré par des marches décroissantes.
                ForEach(0..<6, id: \.self) { index in
                    Rectangle()
                        .fill(primary.opacity(0.65))
                        .frame(width: w * 0.06, height: max(1.5, h * 0.012))
                        .position(x: w * (0.78 - Double(index) * 0.025),
                                  y: h * (0.58 + Double(index) * 0.055))
                }
            }
        }
    }
}

private struct SeineScene: View {
    let primary: Color
    let secondary: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Path { path in
                        let y = h * (0.42 + Double(index) * 0.18)
                        path.move(to: CGPoint(x: w * 0.06, y: y))
                        path.addQuadCurve(to: CGPoint(x: w * 0.94, y: y),
                                          control: CGPoint(x: w * 0.5, y: y - h * 0.14))
                    }
                    .stroke(index == 0 ? primary : secondary.opacity(0.8 - Double(index) * 0.2),
                            style: StrokeStyle(lineWidth: max(1.5, w * 0.016), lineCap: .round))
                }
            }
        }
    }
}

// =============================================================================
// MARK: - Formes
// =============================================================================

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// Le drapeau d'un pays, dessiné plutôt qu'importé — pas d'emoji, pas d'atlas
/// d'images, et un rendu identique sur toutes les tailles d'écran.
struct FlagBadge: View {
    let regionCode: String
    var height: CGFloat = 32

    private var width: CGFloat { height * 1.5 }

    var body: some View {
        Group {
            switch regionCode.uppercased() {
            case "RO": vertical([Color(hex: 0x002B7F), Color(hex: 0xFCD116), Color(hex: 0xCE1126)])
            case "FR": vertical([Color(hex: 0x002395), .white, Color(hex: 0xED2939)])
            case "IT": vertical([Color(hex: 0x008C45), .white, Color(hex: 0xCD212A)])
            case "ES": horizontal([Color(hex: 0xAA151B), Color(hex: 0xF1BF00), Color(hex: 0xAA151B)])
            case "PT": vertical([Color(hex: 0x046A38), Color(hex: 0xDA291C)])
            case "DE": horizontal([.black, Color(hex: 0xDD0000), Color(hex: 0xFFCE00)])
            case "PL": horizontal([.white, Color(hex: 0xDC143C)])
            case "HU": horizontal([Color(hex: 0xCE2939), .white, Color(hex: 0x477050)])
            case "BG": horizontal([.white, Color(hex: 0x00966E), Color(hex: 0xD62612)])
            case "UA": horizontal([Color(hex: 0x0057B7), Color(hex: 0xFFD700)])
            case "RU": horizontal([.white, Color(hex: 0x0039A6), Color(hex: 0xD52B1E)])
            case "GR": horizontal([Color(hex: 0x0D5EAF), .white, Color(hex: 0x0D5EAF), .white, Color(hex: 0x0D5EAF)])
            case "TR": solid(Color(hex: 0xE30A17))
            case "AL": solid(Color(hex: 0xE41E20))
            case "RS": horizontal([Color(hex: 0xC6363C), Color(hex: 0x0C4076), .white])
            case "NL": horizontal([Color(hex: 0xAE1C28), .white, Color(hex: 0x21468B)])
            case "SA": solid(Color(hex: 0x006C35))
            case "CN": solid(Color(hex: 0xDE2910))
            case "JP": ZStack { Color.white; Circle().fill(Color(hex: 0xBC002D)).frame(width: height * 0.6) }
            case "VN": solid(Color(hex: 0xDA251D))
            case "GB": ZStack {
                Color(hex: 0x012169)
                Rectangle().fill(.white).frame(height: height * 0.28)
                Rectangle().fill(.white).frame(width: height * 0.28)
                Rectangle().fill(Color(hex: 0xC8102E)).frame(height: height * 0.14)
                Rectangle().fill(Color(hex: 0xC8102E)).frame(width: height * 0.14)
            }
            default: solid(Theme.glass)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: height * 0.16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: height * 0.16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
    }

    private func vertical(_ colors: [Color]) -> some View {
        HStack(spacing: 0) { ForEach(colors.indices, id: \.self) { colors[$0] } }
    }

    private func horizontal(_ colors: [Color]) -> some View {
        VStack(spacing: 0) { ForEach(colors.indices, id: \.self) { colors[$0] } }
    }

    private func solid(_ color: Color) -> some View { color }
}
