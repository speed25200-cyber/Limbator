import SwiftUI

/// Bouton haut-parleur, avec une onde animée pendant la lecture.
struct SpeakerButton: View {
    let text: String
    var size: CGFloat = 56
    var tint: Color = Theme.or
    var delivery: TTSService.Delivery = .natural

    @EnvironmentObject var tts: TTSService
    @State private var animating = false

    /// Ce bouton-ci, et pas un autre haut-parleur de l'écran.
    private var isActive: Bool { tts.isSpeaking(text, delivery: delivery) }

    static func label(for delivery: TTSService.Delivery) -> String {
        switch delivery {
        case .natural:                return L.t("component.listen")
        case .slow:                   return L.t("component.slow")
        case .spelled, .syllables:    return L.t("component.spell")
        case .wordByWord:             return L.t("ortho.word_by_word")
        }
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task { await tts.speak(text, delivery: delivery) }
        } label: {
            ZStack {
                if isActive {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(tint.opacity(0.42), lineWidth: 2)
                            .scaleEffect(animating ? 1.6 + 0.3 * Double(index) : 1)
                            .opacity(animating ? 0 : 0.7)
                            .animation(.easeOut(duration: 1.2)
                                .repeatForever(autoreverses: false)
                                .delay(0.18 * Double(index)),
                                       value: animating)
                    }
                }
                Circle()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.68)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                    .glow(tint, radius: 16)
                Image(systemName: isActive ? "waveform" : "speaker.wave.2.fill")
                    .font(.system(size: size * 0.4, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .onChange(of: isActive) { _, speaking in animating = speaking }
        // L'étiquette suit la manière de dire : un bouton d'épellation
        // annoncé « Écouter » désoriente qui navigue au clavier vocal.
        .accessibilityLabel(SpeakerButton.label(for: delivery))
    }
}

/// Variante en ligne, pour les phrases d'exemple.
struct SpeakerChip: View {
    let text: String
    var label: String? = nil
    var delivery: TTSService.Delivery = .natural
    @EnvironmentObject var tts: TTSService

    var body: some View {
        Button {
            Task { await tts.speak(text, delivery: delivery) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 11, weight: .bold))
                Text(label ?? L.t("component.listen")).font(Theme.Typography.caption)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Theme.glass))
            .overlay(Capsule().stroke(Theme.glassEdge, lineWidth: 1))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

/// La barre d'écoute d'une dictée.
///
/// C'est le contrôle le plus utilisé de l'app, et le seul qui compte vraiment :
/// réécouter, ralentir, isoler chaque mot, épeler. Un apprenant bloqué sur
/// « les lettres que j'ai écrites » a besoin d'entendre les mots séparément —
/// c'est ainsi qu'il découvre que la liaison lui cachait un pluriel.
struct ListenBar: View {
    let text: String
    var showSpelling: Bool = true

    @EnvironmentObject var tts: TTSService

    var body: some View {
        HStack(spacing: 10) {
            control(icon: "arrow.counterclockwise", label: L.t("ortho.replay"),
                    tint: Theme.bleuFrance, delivery: .natural)
            control(icon: "tortoise.fill", label: L.t("ortho.slower"),
                    tint: Theme.azur, delivery: .slow)
            control(icon: "text.word.spacing", label: L.t("ortho.word_by_word"),
                    tint: Theme.lavande, delivery: .wordByWord)
            if showSpelling {
                control(icon: "textformat.abc", label: L.t("ortho.spell_it"),
                        tint: Theme.or, delivery: .spelled)
            }
        }
    }

    private func control(icon: String, label: String, tint: Color,
                         delivery: TTSService.Delivery) -> some View {
        // Quatre boutons, un seul parle. La lecture mot à mot dure plusieurs
        // secondes : sans repère, on ne sait pas ce qu'on écoute ni s'il faut
        // toucher encore.
        let isActive = tts.isSpeaking(text, delivery: delivery)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task { await tts.speak(text, delivery: delivery) }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: isActive ? "waveform" : icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(isActive ? .white : tint)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(tint.opacity(isActive ? 0.85 : 0.16)))
                    .overlay(Circle().stroke(tint.opacity(isActive ? 1 : 0.4),
                                             lineWidth: isActive ? 2 : 1))
                    .animation(.easeInOut(duration: 0.2), value: isActive)
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
