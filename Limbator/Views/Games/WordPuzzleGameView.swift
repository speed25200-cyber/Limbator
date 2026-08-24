import SwiftUI

/// Construis la phrase : les mots d'une phrase française, mélangés, à remettre
/// dans l'ordre.
///
/// Exercice de syntaxe autant que d'orthographe — l'ordre des mots français
/// (place de l'adjectif, du pronom, de la négation) est l'autre grande
/// difficulté d'un roumanophone, dont la langue est bien plus libre.
struct WordPuzzleGameView: View {
    var roundCount: Int = 8

    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var tts: TTSService
    @Environment(\.dismiss) private var dismiss

    @State private var rounds: [GameRound] = []
    @State private var index = 0
    @State private var pool: [Token] = []
    @State private var built: [Token] = []
    @State private var checked = false
    @State private var score = GameScore()
    @State private var finished = false
    /// Numéro de partie et drapeau de tirage — voir `GameSeed` et
    /// `GameUnavailableView`.
    @State private var attempt = 0
    @State private var loaded = false

    /// Un mot du puzzle. L'identité est portée par un jeton, pas par la chaîne :
    /// une phrase peut contenir deux fois « la », et deux vues identifiées par
    /// la même chaîne se marcheraient dessus.
    struct Token: Identifiable, Hashable {
        let id = UUID()
        let text: String
    }

    private var current: GameRound? {
        rounds.indices.contains(index) ? rounds[index] : nil
    }

    private var attempt: String { built.map(\.text).joined(separator: " ") }

    var body: some View {
        Group {
            if finished {
                GameSummaryView(score: score, tint: GameKind.wordPuzzle.color,
                                onReplay: restart, onDismiss: { dismiss() })
            } else if let round = current {
                play(round)
            } else if loaded {
                GameUnavailableView(tint: GameKind.wordPuzzle.color, onRetry: restart) { dismiss() }
            } else {
                ProgressView().tint(GameKind.wordPuzzle.color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.clear)
        .navigationTitle(GameKind.wordPuzzle.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .onDisappear { tts.cancel() }
    }

    private func load() {
        guard !loaded else { return }
        rounds = ContentGenerator.shared.gameRounds(
            kind: .wordPuzzle, level: progress.profile.level, count: roundCount,
            seed: GameSeed.value(attempt: attempt))
        loaded = true
        prepare()
    }

    private func prepare() {
        guard let round = current else { return }
        let words = round.frenchTarget.split(separator: " ").map(String.init)
        // Mélange déterministe : la disposition initiale ne doit pas changer
        // sous les doigts au premier redessin de SwiftUI.
        let seed = UInt64(index + 1) &* 2_654_435_761
        pool = GameSeeds.shuffled(words, seed: seed).map { Token(text: $0) }
        built = []
        checked = false
    }

    private func play(_ round: GameRound) -> some View {
        VStack(spacing: 18) {
            GameProgressHeader(index: index, total: rounds.count, score: score,
                               tint: GameKind.wordPuzzle.color)
                .padding(.horizontal, 20)

            Text(round.prompt)
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .fixedSize(horizontal: false, vertical: true)

            // Zone de construction.
            VStack(alignment: .leading, spacing: 8) {
                if built.isEmpty {
                    Text(L.t("game.build_sentence"))
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.3))
                } else {
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(built) { token in
                            wordChip(token, in: .built)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(checked
                        ? (isCorrect ? Theme.emeraude : Theme.grenat)
                        : Theme.glassEdge, lineWidth: checked ? 1.8 : 1))
            .padding(.horizontal, 20)

            // Réserve de mots.
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(pool) { token in
                    wordChip(token, in: .pool)
                }
            }
            .padding(.horizontal, 20)

            if checked {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(isCorrect ? Theme.emeraude : Theme.grenat)
                        Text(isCorrect ? L.t("game.correct") : L.t("game.wrong"))
                            .font(Theme.Typography.headline)
                            .foregroundStyle(isCorrect ? Theme.emeraude : Theme.grenat)
                    }
                    if !isCorrect {
                        Text(round.frenchTarget)
                            .font(Theme.Typography.orthoSmall)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    SpeakerButton(text: round.frenchTarget, size: 46, tint: GameKind.wordPuzzle.color)
                }
                .transition(.opacity)
            }

            Spacer(minLength: 10)
        }
        .safeAreaInset(edge: .bottom) { bottomBar(round) }
    }

    private enum Zone { case pool, built }

    private func wordChip(_ token: Token, in zone: Zone) -> some View {
        Button {
            guard !checked else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                switch zone {
                case .pool:
                    pool.removeAll { $0.id == token.id }
                    built.append(token)
                case .built:
                    built.removeAll { $0.id == token.id }
                    pool.append(token)
                }
            }
        } label: {
            Text(token.text)
                .font(Theme.Typography.orthoSmall)
                .foregroundStyle(.white)
                .padding(.horizontal, 13).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(zone == .built ? GameKind.wordPuzzle.color.opacity(0.32) : Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(zone == .built ? GameKind.wordPuzzle.color.opacity(0.6) : Theme.glassEdge,
                            lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(checked)
    }

    private func bottomBar(_ round: GameRound) -> some View {
        HStack(spacing: 10) {
            if !checked && !built.isEmpty {
                GhostButton(title: L.t("game.reset"), icon: "arrow.uturn.backward") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        pool.append(contentsOf: built)
                        built = []
                    }
                }
                .frame(width: 130)
            }
            PrimaryButton(title: checked
                          ? (index == rounds.count - 1 ? L.t("game.finish") : L.t("ortho.next"))
                          : L.t("ortho.check"),
                          icon: checked ? "arrow.right" : "checkmark",
                          gradient: LinearGradient(colors: [GameKind.wordPuzzle.color,
                                                            GameKind.wordPuzzle.color.opacity(0.7)],
                                                   startPoint: .leading, endPoint: .trailing),
                          glowColor: GameKind.wordPuzzle.color,
                          isEnabled: checked || !built.isEmpty) {
                if checked { advance() } else { check(round) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var isCorrect: Bool {
        guard let round = current else { return false }
        return OrthographyEngine.isExactlyCorrect(expected: round.frenchTarget, written: attempt)
    }

    private func check(_ round: GameRound) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { checked = true }
        let correct = isCorrect
        score.register(correct: correct, xp: 12)
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .warning)
        Task { await tts.speak(round.frenchTarget) }
    }

    private func advance() {
        if index == rounds.count - 1 {
            progress.awardXP(score.xpEarned)
            progress.bumpStreak()
            if score.total > 0 && score.correct == score.total { progress.unlock("perfect_game") }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { finished = true }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { index += 1 }
            prepare()
        }
    }

    private func restart() {
        withAnimation {
            rounds = []
            index = 0
            score = GameScore()
            finished = false
        }
        attempt += 1
        loaded = false
        load()
    }
}
