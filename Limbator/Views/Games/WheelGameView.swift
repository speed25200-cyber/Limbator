import SwiftUI

/// La roue de Paris : le hasard choisit le module à travailler.
///
/// Sa vraie fonction est d'ôter la décision. Un apprenant laissé libre revient
/// toujours à ce qu'il maîtrise déjà ; la roue l'envoie là où il ne serait pas
/// allé — y compris sur les accords.
struct WheelGameView: View {
    @EnvironmentObject var progress: ProgressTracker
    @Environment(\.dismiss) private var dismiss

    @State private var angle: Double = 0
    @State private var spinning = false
    @State private var landed: OrthoModule?

    private let modules = OrthoModule.allCases
    private var slice: Double { 360.0 / Double(modules.count) }

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            ZStack {
                wheel
                    .rotationEffect(.degrees(angle))
                    .frame(width: 290, height: 290)

                // Le repère, en haut, fixe.
                Triangle()
                    .fill(Theme.goldGradient)
                    .frame(width: 22, height: 26)
                    .rotationEffect(.degrees(180))
                    .offset(y: -160)
                    .shadow(color: Theme.or.opacity(0.7), radius: 8)

                Circle()
                    .fill(Theme.encre)
                    .frame(width: 66, height: 66)
                    .overlay(Circle().stroke(Theme.goldGradient, lineWidth: 2))
                    .overlay(
                        Image(systemName: "textformat.abc")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Theme.goldGradient))
            }

            if let landed {
                VStack(spacing: 12) {
                    Text(landed.localizedTitle)
                        .font(Theme.Typography.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(landed.localizedSubtitle)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    NavigationLink {
                        OrthoDrillView(module: landed)
                    } label: {
                        HStack(spacing: 8) {
                            Text(L.t("ortho.train")).font(Theme.Typography.headline)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28).padding(.vertical, 15)
                        .background(Capsule().fill(LinearGradient(
                            colors: [landed.color, landed.color.opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing)))
                        .shadow(color: landed.color.opacity(0.45), radius: 14, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            Spacer()

            PrimaryButton(title: L.t("game.spin"), icon: "arrow.triangle.2.circlepath",
                          gradient: Theme.goldGradient, glowColor: Theme.or,
                          isEnabled: !spinning) {
                spin()
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 24)
        }
        .background(Color.clear)
        .navigationTitle(GameKind.wheelOfFortune.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var wheel: some View {
        ZStack {
            ForEach(Array(modules.enumerated()), id: \.element) { entry in
                let start = Angle.degrees(Double(entry.offset) * slice - 90)
                let end = Angle.degrees(Double(entry.offset + 1) * slice - 90)

                WheelSlice(startAngle: start, endAngle: end)
                    .fill(LinearGradient(colors: [entry.element.color,
                                                  entry.element.color.opacity(0.55)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(WheelSlice(startAngle: start, endAngle: end)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1))

                Image(systemName: entry.element.iconName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(entry.offset) * slice + slice / 2))
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.goldGradient, lineWidth: 3))
        .shadow(color: .black.opacity(0.55), radius: 22, x: 0, y: 12)
    }

    private func spin() {
        spinning = true
        landed = nil
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // On tire d'abord le résultat, puis on calcule l'angle qui l'affiche.
        // L'inverse — laisser l'angle décider — donnerait un tirage biaisé par
        // les arrondis de l'animation.
        let target = Int.random(in: 0..<modules.count)
        let turns = Double(Int.random(in: 4...6)) * 360
        // Le repère est en haut : il faut amener le centre de la part choisie
        // à cette position, donc tourner en sens inverse de son index.
        let destination = turns - (Double(target) * slice + slice / 2)

        withAnimation(.timingCurve(0.15, 0.85, 0.2, 1.0, duration: 3.2)) {
            angle += destination
        }

        Task {
            try? await Task.sleep(nanoseconds: 3_250_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    landed = modules[target]
                }
                spinning = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

/// Une part de la roue.
struct WheelSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}
