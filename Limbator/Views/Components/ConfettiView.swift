import SwiftUI

/// Une gerbe de confettis, déclenchée en incrémentant `trigger`.
///
/// Réservée aux vraies réussites — une dictée sans faute, un module maîtrisé.
/// Célébrer chaque bonne réponse dévaluerait la célébration.
struct ConfettiView: View {
    let trigger: Int

    @State private var particles: [Particle] = []
    @State private var canvasSize: CGSize = .zero

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var rotation: Double
        var spin: Double
        var color: Color
        var size: CGFloat
        var birth: Date
    }

    var body: some View {
        GeometryReader { geo in
            // La boucle d'animation ne tourne que s'il y a quelque chose à
            // dessiner. Sans cette garde, chaque écran portant des confettis —
            // quiz, exercices, dictée — redessinait un canevas vide soixante
            // fois par seconde, en permanence.
            Group {
                if particles.isEmpty {
                    Color.clear
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                        Canvas { context, _ in
                            draw(in: &context, at: timeline.date)
                        }
                    }
                }
            }
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { _, size in canvasSize = size }
        }
        .onChange(of: trigger) { _, _ in burst() }
        .allowsHitTesting(false)
    }

    private func draw(in context: inout GraphicsContext, at now: Date) {
        for particle in particles {
            let age = now.timeIntervalSince(particle.birth)
            let life = age / 1.7
            if life > 1 { continue }
            let x = particle.x + particle.vx * CGFloat(age) * 210
            // Le terme quadratique est la gravité : sans lui les confettis
            // flotteraient au lieu de retomber.
            let y = particle.y + particle.vy * CGFloat(age) * 210
                + CGFloat(age * age) * 360
            var layer = context
            layer.translateBy(x: x, y: y)
            layer.rotate(by: .radians(particle.rotation + particle.spin * age))
            layer.opacity = max(0, 1 - life)
            let rect = CGRect(x: -particle.size / 2, y: -particle.size / 4,
                              width: particle.size, height: particle.size / 2)
            layer.fill(Path(rect), with: .color(particle.color))
        }
    }

    private func burst() {
        let palette: [Color] = [Theme.bleuFrance, Theme.or, Theme.emeraude,
                                Theme.lavande, Theme.rose, Theme.orClair]
        let originX = canvasSize.width > 0 ? canvasSize.width / 2 : 200
        let originY = canvasSize.height > 0 ? canvasSize.height * 0.58 : 400

        let fresh = (0..<90).map { _ -> Particle in
            let angle = Double.random(in: -(.pi)...0)
            let speed = Double.random(in: 0.6...1.6)
            return Particle(x: originX, y: originY,
                            vx: CGFloat(cos(angle) * speed),
                            vy: CGFloat(sin(angle) * speed),
                            rotation: .random(in: 0...(.pi * 2)),
                            spin: .random(in: -8...8),
                            color: palette.randomElement() ?? .white,
                            size: .random(in: 8...16),
                            birth: .now)
        }
        particles.append(contentsOf: fresh)

        Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            await MainActor.run {
                particles.removeAll { Date().timeIntervalSince($0.birth) > 1.8 }
            }
        }
    }
}
