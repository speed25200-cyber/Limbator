import SwiftUI

/// La dictée.
///
/// Trois états se succèdent : écoute, saisie, correction. La séparation est
/// stricte — on ne montre jamais le texte avant la correction, sinon
/// l'exercice n'en est plus un.
struct DictationView: View {
    let item: DictationItem

    @EnvironmentObject var tts: TTSService
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var repetition: SpacedRepetition
    @Environment(\.dismiss) private var dismiss

    @State private var written = ""
    @State private var verdict: OrthoVerdict?
    @State private var showTranslation = false
    @State private var showHint = false
    @State private var confetti = 0
    /// Le point d'insertion dans la copie. Il vient de UIKit, donc en unités
    /// UTF-16 : c'est lui qui permet à la rangée d'accents d'écrire là où se
    /// trouve le curseur plutôt qu'à la fin du texte.
    @State private var selection = NSRange(location: 0, length: 0)
    @State private var editing = false
    /// La relecture différée après « recommencer » : retenue pour être annulée
    /// si l'écran disparaît entre-temps.
    @State private var speechTask: Task<Void, Never>?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                if let verdict {
                    correction(verdict)
                } else {
                    listeningStage
                    writingStage
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Color.clear)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(L.t("ortho.dictation"))
        .navigationBarTitleDisplayMode(.inline)
        .overlay { ConfettiView(trigger: confetti).ignoresSafeArea() }
        .task {
            // Première écoute automatique : l'utilisateur a choisi une dictée,
            // il n'a pas besoin d'un second appui pour l'entendre.
            try? await Task.sleep(nanoseconds: 400_000_000)
            // `try?` avale l'annulation : sans cette garde, quitter l'écran
            // pendant l'attente laissait la phrase se lire par-dessus la vue
            // suivante — `onDisappear` a déjà coupé la voix à ce moment-là.
            guard !Task.isCancelled else { return }
            await tts.speak(item.text)
        }
        .onDisappear {
            speechTask?.cancel()
            speechTask = nil
            tts.cancel()
        }
    }

    // =========================================================================
    // MARK: - Écoute
    // =========================================================================

    private var listeningStage: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Theme.primaryGradient)
                    .frame(width: 150, height: 150)
                    .blur(radius: 45)
                    .opacity(tts.isSpeaking ? 0.75 : 0.35)
                    .animation(.easeInOut(duration: 0.5), value: tts.isSpeaking)
                SpeakerButton(text: item.text, size: 96, tint: Theme.bleuFrance)
            }
            .frame(height: 160)

            ListenBar(text: item.text)

            HStack(spacing: 10) {
                Chip(text: item.level.rawValue, tint: Theme.lavande)
                Chip(text: L.t("lessons.minutes", max(1, item.wordCount / 6)),
                     systemImage: "clock", tint: Theme.glassEdge)
                if item.localizedHint != nil {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showHint.toggle() }
                    } label: {
                        Chip(text: L.t("ortho.hint"), systemImage: "lightbulb.fill", tint: Theme.or)
                    }
                    .buttonStyle(.plain)
                }
            }

            if showHint, let hint = item.localizedHint {
                Text(hint)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.or)
                    .multilineTextAlignment(.center)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.or.opacity(0.12)))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // =========================================================================
    // MARK: - Saisie
    // =========================================================================

    private var writingStage: some View {
        VStack(alignment: .leading, spacing: 14) {
            // La saisie doit rester brute : la correction automatique d'iOS
            // remplacerait les fautes que l'exercice cherche justement à
            // révéler, et la majuscule automatique fausserait le résultat.
            OrthoTextEditor(text: $written, selection: $selection, isEditing: $editing)
                .frame(minHeight: 130)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(editing ? Theme.bleuFrance : Theme.glassEdge,
                            lineWidth: editing ? 1.6 : 1))
                .overlay(alignment: .topLeading) {
                    if written.isEmpty {
                        Text(L.t("ortho.type_here"))
                            .font(Theme.Typography.orthoSmall)
                            .foregroundStyle(.white.opacity(0.32))
                            .padding(.horizontal, 17)
                            .padding(.vertical, 17)
                            .allowsHitTesting(false)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: editing)

            AccentKeyboardRow { character in insert(character) }

            PrimaryButton(title: L.t("ortho.submit"), icon: "checkmark",
                          isEnabled: !written.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                submit()
            }

            Button {
                withAnimation { showTranslation.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showTranslation ? "eye.slash" : "eye")
                        .font(.system(size: 11, weight: .bold))
                    Text(L.t("ortho.show_translation")).font(Theme.Typography.caption)
                }
                .foregroundStyle(.white.opacity(0.55))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            if showTranslation {
                Text(item.localizedTranslation)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.glass))
                    .transition(.opacity)
            }
        }
    }

    /// Écrit un caractère accentué **au point d'insertion**, pas à la fin.
    ///
    /// Corriger « etait » en « était » se fait ainsi en posant le curseur après
    /// le « e » et en touchant « é » ; la version précédente ajoutait à la fin
    /// et obligeait à réécrire le mot.
    private func insert(_ character: String) {
        let result = written.inserting(character, at: selection)
        written = result.text
        selection = result.caret
        // Toucher un accent avant d'avoir touché le champ doit aussi ouvrir le
        // clavier : sinon la lettre part au début du texte sans que rien ne
        // signale où elle vient d'atterrir.
        editing = true
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func submit() {
        editing = false
        tts.cancel()
        let result = OrthographyEngine.evaluate(expected: item.text, written: written)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { verdict = result }

        progress.recordDictation(result)

        // Chaque règle visée est replanifiée. Une règle sur laquelle
        // l'apprenant a effectivement fauté redescend à demain ; les autres
        // s'espacent.
        for ruleId in item.targetRules {
            let failed = result.mistakes.contains { $0.ruleId == ruleId }
            repetition.record(ruleId: ruleId, score: failed ? 0.3 : result.score)
        }
        // Les règles fautives non prévues par la dictée comptent aussi.
        for mistake in result.mistakes {
            guard let ruleId = mistake.ruleId, !item.targetRules.contains(ruleId) else { continue }
            repetition.record(ruleId: ruleId, score: 0.3)
        }

        if result.isPerfect {
            confetti += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    // =========================================================================
    // MARK: - Correction
    // =========================================================================

    private func correction(_ verdict: OrthoVerdict) -> some View {
        VStack(spacing: 22) {
            ScoreBadge(verdict: verdict)
                .padding(.top, 8)

            if verdict.isPerfect {
                Text(L.t("ortho.perfect"))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.or)
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: L.t("ortho.expected"))
                OrthoDiffView(verdict: verdict)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 20)
                OrthoDiffLegend()
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: L.t("ortho.your_answer"))
                Text(verdict.written.isEmpty ? "—" : verdict.written)
                    .font(Theme.Typography.orthoSmall)
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.glass))
            }

            ListenBar(text: item.text)

            if !verdict.mistakes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: L.t("ortho.mistakes_title"),
                                  subtitle: L.t("profile.mistakes_count", verdict.mistakes.count))
                    ForEach(verdict.mistakes) { mistake in
                        MistakeCard(mistake: mistake)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: L.t("story.translation"))
                Text(item.localizedTranslation)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 10) {
                PrimaryButton(title: L.t("ortho.again"), icon: "arrow.counterclockwise") {
                    restart()
                }
                GhostButton(title: L.t("ortho.finish")) { dismiss() }
            }
        }
    }

    private func restart() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            verdict = nil
            written = ""
            showTranslation = false
            showHint = false
            selection = NSRange(location: 0, length: 0)
        }
        speechTask?.cancel()
        speechTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await tts.speak(item.text)
        }
    }
}

// =============================================================================
// MARK: - Rangée de caractères accentués
// =============================================================================

/// Les caractères que le clavier roumain n'offre pas au premier niveau.
///
/// Sans cette rangée, écrire « é » demande un appui long, ce qui décourage
/// exactement le geste que l'app veut installer. Les accents doivent être aussi
/// faciles à taper que les lettres.
struct AccentKeyboardRow: View {
    let insert: (String) -> Void

    private let characters = ["é", "è", "ê", "à", "â", "î", "ô", "û", "ë", "ï", "ç", "œ", "'", "«", "»"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(characters, id: \.self) { character in
                    Button {
                        insert(character)
                    } label: {
                        Text(character)
                            .font(.system(size: 19, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.glass))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.glassEdge, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
