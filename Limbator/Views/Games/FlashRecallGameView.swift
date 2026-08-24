import SwiftUI

/// Flash mémoire : une carte, trois secondes, un verdict.
///
/// Le minuteur n'est pas là pour stresser mais pour empêcher la reconstruction.
/// Un mot qu'on retrouve en cinq secondes n'est pas su ; celui qui vient en
/// trois l'est.
struct FlashRecallGameView: View {
    var roundCount: Int = 12
    var secondsPerCard: Double = 3

    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var repetition: SpacedRepetition
    @EnvironmentObject var tts: TTSService
    @Environment(\.dismiss) private var dismiss

    @State private var cards: [VocabCard] = []
    @State private var index = 0
    @State private var revealed = false
    @State private var remaining: Double = 3
    @State private var score = GameScore()
    @State private var finished = false
    @State private var started = false
    @State private var ticker: Task<Void, Never>?

    private var current: VocabCard? {
        cards.indices.contains(index) ? cards[index] : nil
    }

    var body: some View {
        Group {
            if finished {
                GameSummaryView(score: score, tint: GameKind.flashRecall.color,
                                onReplay: restart, onDismiss: { dismiss() })
            } else if !started {
                startScreen
            } else if let card = current {
                play(card)
            } else {
                ProgressView().tint(GameKind.flashRecall.color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.clear)
        .navigationTitle(GameKind.flashRecall.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .onDisappear {
            ticker?.cancel()
            tts.cancel()
        }
    }

    private func load() {
        guard cards.isEmpty else { return }
        let seed = UInt64(abs(Int(Date().timeIntervalSince1970) / 300))
        cards = GameSeeds.sample(GameSeeds.vocabPool, count: roundCount, seed: seed) { $0.french }
    }

    private var startScreen: some View {
        VStack(spacing: 22) {
            Spacer()
            LimbIconView(icon: .lightning, size: 52,
                         gradient: LinearGradient(colors: [GameKind.flashRecall.color, Theme.or],
                                                  startPoint: .top, endPoint: .bottom),
                         glow: GameKind.flashRecall.color)
            Text(GameKind.flashRecall.localizedSubtitle)
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: L.t("game.tap_start"), icon: "play.fill",
                          gradient: LinearGradient(colors: [GameKind.flashRecall.color, Theme.or],
                                                   startPoint: .leading, endPoint: .trailing),
                          glowColor: GameKind.flashRecall.color) {
                started = true
                beginCard()
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 30)
        }
    }

    private func play(_ card: VocabCard) -> some View {
        VStack(spacing: 20) {
            GameProgressHeader(index: index, total: cards.count, score: score,
                               tint: GameKind.flashRecall.color)
                .padding(.horizontal, 20)

            // Le sablier : il tourne pendant qu'on cherche, et disparaît dès
            // que la réponse est visible.
            if !revealed {
                ZStack {
                    ProgressRing(progress: remaining / secondsPerCard, lineWidth: 6,
                                 gradient: AngularGradient(colors: [GameKind.flashRecall.color, Theme.or],
                                                           center: .center))
                        .frame(width: 56, height: 56)
                    Text("\(Int(ceil(remaining)))")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Text(card.withArticle)
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 24)

                if revealed {
                    VStack(spacing: 10) {
                        Text(card.localizedTranslation)
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.emeraude)
                            .multilineTextAlignment(.center)
                        if let note = card.localizedSpellingNote {
                            Text(note)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.orClair)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 26)
                        }
                        SpeakerButton(text: card.french, size: 46, tint: GameKind.flashRecall.color)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }
            }

            Spacer()

            if revealed {
                // L'auto-évaluation est la seule mesure honnête ici : l'app ne
                // peut pas savoir ce que l'apprenant avait en tête.
                HStack(spacing: 12) {
                    verdictButton(title: L.t("lesson.wrong"), icon: "xmark",
                                  tint: Theme.grenat, correct: false, card: card)
                    verdictButton(title: L.t("lesson.right"), icon: "checkmark",
                                  tint: Theme.emeraude, correct: true, card: card)
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 24)
        }
    }

    private func verdictButton(title: String, icon: String, tint: Color,
                               correct: Bool, card: VocabCard) -> some View {
        Button {
            register(correct: correct, card: card)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 15, weight: .heavy))
                Text(title).font(Theme.Typography.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.85)))
            .shadow(color: tint.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // =========================================================================
    // MARK: - Minuterie
    // =========================================================================

    private func beginCard() {
        revealed = false
        remaining = secondsPerCard
        ticker?.cancel()
        ticker = Task {
            while remaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                await MainActor.run { remaining = max(0, remaining - 0.1) }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { revealed = true }
                if let card = current { Task { await tts.speak(card.french) } }
            }
        }
    }

    private func register(correct: Bool, card: VocabCard) {
        score.register(correct: correct, xp: 8)
        repetition.record(word: card.french, score: correct ? 1 : 0.25)
        UIImpactFeedbackGenerator(style: correct ? .rigid : .soft).impactOccurred()

        if index == cards.count - 1 {
            ticker?.cancel()
            progress.awardXP(score.xpEarned)
            progress.bumpStreak()
            if score.total > 0 && score.correct == score.total { progress.unlock("perfect_game") }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { finished = true }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { index += 1 }
            beginCard()
        }
    }

    private func restart() {
        ticker?.cancel()
        withAnimation {
            cards = []
            index = 0
            revealed = false
            score = GameScore()
            finished = false
            started = false
        }
        load()
    }
}
