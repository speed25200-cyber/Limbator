import SwiftUI

/// Le fond animé de l'app : des masses colorées qui dérivent lentement derrière
/// le contenu.
///
/// Deux décisions de performance ont façonné ce composant. D'abord la cadence :
/// quinze images par seconde suffisent à un mouvement aussi lent, et divisent
/// par quatre le coût d'un flou plein écran — ce qui laisse le GPU disponible
/// pour l'inférence de Gemma pendant qu'il génère. Ensuite l'arithmétique :
/// les expressions trigonométriques sont sorties du corps du Canvas, sans quoi
/// le vérificateur de types de SwiftUI renonce.
struct AuroraBackground: View {

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let background = Path(CGRect(origin: .zero, size: size))
                context.fill(background, with: .linearGradient(
                    Gradient(colors: [Color(hex: 0x04050C),
                                      Color(hex: 0x0A0F22),
                                      Color(hex: 0x140A28)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)))

                let width = size.width, height = size.height
                let blobs: [(x: CGFloat, y: CGFloat, r: CGFloat, color: Color)] = [
                    Self.blob(width: width, height: height,
                              fx: 0.24 + 0.14 * sin(time * 0.28),
                              fy: 0.26 + 0.11 * cos(time * 0.23),
                              fr: 0.54, color: Theme.bleuFrance.opacity(0.50)),
                    Self.blob(width: width, height: height,
                              fx: 0.76 + 0.14 * cos(time * 0.37),
                              fy: 0.54 + 0.10 * sin(time * 0.31),
                              fr: 0.50, color: Theme.lavande.opacity(0.42)),
                    Self.blob(width: width, height: height,
                              fx: 0.52 + 0.10 * sin(time * 0.46),
                              fy: 0.88 + 0.07 * cos(time * 0.41),
                              fr: 0.58, color: Theme.or.opacity(0.26))
                ]

                for blob in blobs {
                    let rect = CGRect(x: blob.x - blob.r, y: blob.y - blob.r,
                                      width: blob.r * 2, height: blob.r * 2)
                    context.addFilter(.blur(radius: 80))
                    context.fill(Path(ellipseIn: rect), with: .color(blob.color))
                }
            }
            .ignoresSafeArea()
        }
    }

    /// Convertit des fractions d'écran en coordonnées. Garder la trigonométrie
    /// en `Double` puis convertir une seule fois évite l'explosion combinatoire
    /// du vérificateur de types dans le corps du Canvas.
    private static func blob(width: CGFloat, height: CGFloat,
                             fx: Double, fy: Double, fr: Double,
                             color: Color) -> (x: CGFloat, y: CGFloat, r: CGFloat, color: Color) {
        (x: width * CGFloat(fx), y: height * CGFloat(fy), r: width * CGFloat(fr), color: color)
    }
}

/// Une pluie d'étoiles discrète — réservée aux moments de célébration.
struct StarFieldView: View {
    let count: Int
    @State private var stars: [Star] = []

    struct Star: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var twinkle: Double
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for star in stars {
                    let alpha = 0.4 + 0.6 * (0.5 + 0.5 * sin(time * star.twinkle))
                    let rect = CGRect(x: star.x * size.width - star.size / 2,
                                      y: star.y * size.height - star.size / 2,
                                      width: star.size, height: star.size)
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(.white.opacity(alpha * star.opacity)))
                }
            }
        }
        .onAppear {
            stars = (0..<count).map { _ in
                Star(x: .random(in: 0...1), y: .random(in: 0...1),
                     size: .random(in: 1.2...3.4),
                     opacity: .random(in: 0.35...1.0),
                     twinkle: .random(in: 1.4...3.8))
            }
        }
        .allowsHitTesting(false)
    }
}
