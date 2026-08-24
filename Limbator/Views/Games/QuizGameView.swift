import SwiftUI

/// Le moteur de quiz commun aux jeux à choix multiple : paires, écoute, duel
/// d'homophones, chasse aux accents.
///
/// Un seul écran plutôt que quatre presque identiques. Ce qui change d'un jeu à
/// l'autre — la consigne, la couleur, ce qu'on lit à voix haute, si la cible est
/// visible avant la réponse — tient dans quelques propriétés calculées.
struct QuizGameView: View {
    let kind: GameKind
    var roundCount: Int = 10

    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var repetition: SpacedRepetition
    @EnvironmentObject var tts: TTSService
    @Environment(\.dismiss) private var dismiss

    @State private var rounds: [GameRound] = []
    @State private var index = 0
    @State private var chosen: String?
    @State private var checked = false
    @State private var score = GameScore()
    @State private var finished = false
    @State private var confetti = 0
    /// Incrémenté à chaque « Rejouer » — voir `GameSeed`.
    @State private var attempt = 0
    /// Distingue « pas encore chargé » de « chargé, mais rien d'exploitable ».
    /// Sans cette distinction, un tirage vide était indiscernable d'un tirage
    /// en cours et l'écran tournait sans fin.
    @State private var loaded = false
    /// La lecture différée doit pouvoir être annulée : sans cette poignée, on
    /// quitte l'écran et la voix parle par-dessus la vue suivante.
    @State private var speechTask: Task<Void, Never>?

    private var current: GameRound? {
        rounds.indices.contains(index) ? rounds[index] : nil
    }

    /// En mode écoute, montrer la cible reviendrait à donner la réponse.
    private var hidesTarget: Bool { kind == .listening }

    var body: some View {
        Group {
            if finished {
                GameSummaryView(score: score, tint: kind.color,
                                onReplay: restart, onDismiss: { dismiss() })
            } else if let round = current {
                play(round)
            } else if loaded {
                GameUnavailableView(tint: kind.color, onRetry: restart) { dismiss() }
            } else {
                loading
            }
        }
        .background(Color.clear)
        .navigationTitle(kind.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .overlay { ConfettiView(trigger: confetti).ignoresSafeArea() }
        .onAppear(perform: load)
        .onDisappear {
            speechTask?.cancel()
            speechTask = nil
            tts.cancel()
        }
    }

    private func load() {
        guard !loaded else { return }
        let seed = GameSeed.value(attempt: attempt)
        rounds = ContentGenerator.shared
            .gameRounds(kind: kind, level: progress.profile.level, count: roundCount, seed: seed)
            .filter(\.isQuizPlayable)
        loaded = true
        if kind == .listening, let first = rounds.first {
            speak(first.frenchTarget, after: 500_000_000)
        }
    }

    /// Lit une cible après un court délai, en remplaçant toute lecture déjà
    /// programmée. La tâche est retenue pour qu'un départ de l'écran l'annule.
    private func speak(_ target: String, after delay: UInt64) {
        speechTask?.cancel()
        speechTask = Task {
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            await tts.speak(target)
        }
    }

    private var loading: some View {
        VStack(spacing: 14) {
            ProgressView().tint(kind.color)
            Text(L.t("game.loading"))
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // =========================================================================
    // MARK: - Manche
    // =========================================================================

    private func play(_ round: GameRound) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                GameProgressHeader(index: index, total: rounds.count, score: score, tint: kind.color)

                promptCard(round)

                VStack(spacing: 10) {
                    ForEach(round.options, id: \.self) { option in
                        optionButton(option, round: round)
                    }
                }

                if checked, let explanation = round.explanation, !explanation.isEmpty {
                    Text(explanation)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(15)
                        .glassCard(cornerRadius: 18)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .safeAreaInset(edge: .bottom) {
            if checked {
                PrimaryButton(title: index == rounds.count - 1 ? L.t("game.finish") : L.t("ortho.next"),
                              icon: "arrow.right",
                              gradient: LinearGradient(colors: [kind.color, kind.color.opacity(0.7)],
                                                       startPoint: .leading, endPoint: .trailing),
                              glowColor: kind.color) { advance() }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
            }
        }
    }

    private func promptCard(_ round: GameRound) -> some View {
        VStack(spacing: 14) {
            if hidesTarget && !checked {
                SpeakerButton(text: round.frenchTarget, size: 84, tint: kind.color)
                    .padding(.vertical, 8)
                Text(round.prompt)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Text(round.prompt)
                    .font(kind == .homophoneDuel ? Theme.Typography.ortho : Theme.Typography.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if !hidesTarget {
                    SpeakerButton(text: round.frenchTarget, size: 50, tint: kind.color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .glassCard(cornerRadius: 24)
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(kind.color.opacity(0.32), lineWidth: 1))
    }

    private func optionButton(_ option: String, round: GameRound) -> some View {
        Button {
            guard !checked else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            chosen = option
            check(round)
        } label: {
            HStack(spacing: 12) {
                Text(option)
                    .font(kind == .accentHunt || kind == .homophoneDuel
                          ? Theme.Typography.orthoSmall : Theme.Typography.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if checked {
                    Image(systemName: option == round.correctAnswer
                          ? "checkmark.circle.fill"
                          : (option == chosen ? "xmark.circle.fill" : "circle"))
                        .font(.system(size: 19))
                        .foregroundStyle(option == round.correctAnswer ? Theme.emeraude
                                         : (option == chosen ? Theme.grenat : .white.opacity(0.2)))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(optionBackground(option, round: round)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(optionBorder(option, round: round), lineWidth: chosen == option ? 2 : 1))
        }
        .buttonStyle(.plain)
        .disabled(checked)
    }

    private func optionBackground(_ option: String, round: GameRound) -> Color {
        guard checked else { return Theme.glass }
        if option == round.correctAnswer { return Theme.emeraude.opacity(0.20) }
        if option == chosen { return Theme.grenat.opacity(0.20) }
        return Theme.glass
    }

    private func optionBorder(_ option: String, round: GameRound) -> Color {
        guard checked else { return Theme.glassEdge }
        if option == round.correctAnswer { return Theme.emeraude }
        if option == chosen { return Theme.grenat }
        return Theme.glassEdge
    }

    // =========================================================================
    // MARK: - Logique
    // =========================================================================

    private func check(_ round: GameRound) {
        let correct = chosen == round.correctAnswer
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { checked = true }
        score.register(correct: correct, xp: 10)

        if correct {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            if kind == .homophoneDuel { progress.recordMistake(.homophone) }
            if kind == .accentHunt { progress.recordMistake(.accentMissing) }
        }

        // La forme juste est toujours lue à voix haute après la réponse : c'est
        // elle qui doit rester en mémoire, pas celle qu'on a choisie.
        Task { await tts.speak(round.frenchTarget) }

        // Le duel d'homophones et la chasse aux accents nourrissent la
        // répétition espacée comme le feraient des exercices. La règle visée se
        // déduit de la bonne réponse : la famille d'homophones à laquelle elle
        // appartient, ou le diacritique qu'elle porte réellement — tout attribuer
        // à l'aigu / grave aurait faussé la planification des mots à circonflexe
        // ou à cédille.
        if let ruleId = round.trainedRuleId {
            repetition.record(ruleId: ruleId, score: correct ? 1 : 0.25)
        }
        if kind == .match || kind == .listening || kind == .flashRecall {
            repetition.record(word: round.frenchTarget, score: correct ? 1 : 0.3)
        }
    }

    private func advance() {
        if index == rounds.count - 1 {
            progress.awardXP(score.xpEarned)
            progress.bumpStreak()
            if score.total > 0 && score.correct == score.total {
                progress.unlock("perfect_game")
                confetti += 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { finished = true }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                index += 1
                chosen = nil
                checked = false
            }
            if hidesTarget, let next = current {
                speak(next.frenchTarget, after: 320_000_000)
            }
        }
    }

    private func restart() {
        speechTask?.cancel()
        speechTask = nil
        tts.cancel()
        withAnimation {
            rounds = []
            index = 0
            chosen = nil
            checked = false
            score = GameScore()
            finished = false
        }
        attempt += 1
        loaded = false
        load()
    }
}

// =============================================================================
// MARK: - Éléments partagés
// =============================================================================

struct GameProgressHeader: View {
    let index: Int
    let total: Int
    let score: GameScore
    var tint: Color = Theme.bleuFrance

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L.t("game.round", index + 1, total))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .monospacedDigit()
                Spacer()
                if score.streak >= 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 11))
                        Text("\(score.streak)").monospacedDigit()
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.or)
                }
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.emeraude)
                    Text("\(score.correct)/\(score.total)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .monospacedDigit()
                }
            }
            MasteryBar(value: Double(index) / Double(max(1, total)), tint: tint, height: 5)
        }
    }
}

struct GameSummaryView: View {
    let score: GameScore
    var tint: Color = Theme.bleuFrance
    let onReplay: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                ProgressRing(progress: score.accuracy, lineWidth: 12)
                    .frame(width: 168, height: 168)
                VStack(spacing: 2) {
                    Text("\(score.correct)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    Text("/ \(score.total)")
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.55))
                        .monospacedDigit()
                }
            }

            VStack(spacing: 8) {
                Text(score.correct == score.total && score.total > 0
                     ? L.t("game.perfect")
                     : L.t("game.result", score.correct, score.total))
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(L.t("game.xp_earned", score.xpEarned))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.or)
                if score.bestStreak >= 3 {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                        Text("\(L.t("game.streak")) \(score.bestStreak)").monospacedDigit()
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.grenat)
                }
            }

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: L.t("game.replay"), icon: "arrow.counterclockwise",
                              gradient: LinearGradient(colors: [tint, tint.opacity(0.7)],
                                                       startPoint: .leading, endPoint: .trailing),
                              glowColor: tint,
                              action: onReplay)
                GhostButton(title: L.t("game.finish"), action: onDismiss)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}
