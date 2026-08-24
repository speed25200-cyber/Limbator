import SwiftUI

/// Carte en verre dépoli avec un liseré coloré et une légère parallaxe.
/// L'inclinaison suit le doigt puis revient : elle donne de la matière sans
/// jamais déplacer une cible tactile.
struct GlowingCard<Content: View>: View {
    let tint: Color
    var cornerRadius: CGFloat = 24
    @ViewBuilder var content: () -> Content

    @State private var pitch: Double = 0
    @State private var yaw: Double = 0

    var body: some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LinearGradient(colors: [tint.opacity(0.75), tint.opacity(0)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.4))
            .shadow(color: tint.opacity(0.32), radius: 22, x: 0, y: 14)
            .rotation3DEffect(.degrees(pitch), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.easeOut(duration: 0.1)) {
                            yaw = Double(value.translation.width / 26).clamped(to: -7...7)
                            pitch = Double(-value.translation.height / 26).clamped(to: -7...7)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            yaw = 0; pitch = 0
                        }
                    })
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

/// Bouton principal : dégradé, halo, et une compression au toucher accompagnée
/// d'un retour haptique. Le retour haptique n'est pas cosmétique — il confirme
/// l'appui avant même que l'écran n'ait changé.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var gradient: LinearGradient = Theme.primaryGradient
    var glowColor: Color = Theme.bleuFrance
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            guard isEnabled, !isLoading else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let icon {
                    Image(systemName: icon).font(.system(size: 18, weight: .heavy))
                }
                Text(title).font(Theme.Typography.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(gradient)
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                })
            .scaleEffect(pressed ? 0.965 : 1)
            .opacity(isEnabled ? 1 : 0.45)
            .shadow(color: glowColor.opacity(isEnabled ? 0.4 : 0), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = true } }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { pressed = false }
                })
    }
}

struct GhostButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { Image(systemName: icon) }
                Text(title).font(Theme.Typography.body)
            }
            .foregroundStyle(.white.opacity(0.92))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Anneau de progression. Sert partout : objectif du jour, maîtrise d'un
/// module, avancée d'une série d'exercices.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var gradient: AngularGradient = AngularGradient(
        colors: [Theme.bleuFrance, Theme.lavande, Theme.or, Theme.emeraude, Theme.bleuFrance],
        center: .center)

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progress)
        }
    }
}

/// Barre de maîtrise horizontale, avec un liseré doré quand l'objectif est
/// atteint — la seule récompense visuelle de l'écran d'orthographe.
struct MasteryBar: View {
    let value: Double
    var tint: Color = Theme.emeraude
    var height: CGFloat = 8

    private var isMastered: Bool { value >= 0.8 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))
                Capsule()
                    .fill(isMastered
                          ? AnyShapeStyle(Theme.goldGradient)
                          : AnyShapeStyle(LinearGradient(colors: [tint, tint.opacity(0.6)],
                                                         startPoint: .leading, endPoint: .trailing)))
                    .frame(width: max(0, min(1, value)) * geo.size.width)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: height)
    }
}

/// Étiquette compacte : une icône, un mot. Sert aux catégories de fautes et aux
/// niveaux.
struct Chip: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = Theme.bleuFrance

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 11, weight: .bold))
            }
            Text(text).font(Theme.Typography.caption)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(tint.opacity(0.20)))
        .overlay(Capsule().stroke(tint.opacity(0.45), lineWidth: 1))
        .foregroundStyle(.white)
    }
}

/// En-tête de section : un titre, éventuellement une action à droite.
struct SectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Typography.headline).foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            Spacer()
            trailing()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}
