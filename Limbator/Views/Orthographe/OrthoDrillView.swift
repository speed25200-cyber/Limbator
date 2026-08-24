import SwiftUI

/// La série d'exercices d'un module.
///
/// Le retour après réponse est immédiat et **toujours explicatif** : une bonne
/// réponse validée sans explication n'apprend rien de plus qu'une mauvaise.
/// L'explication s'affiche dans les deux cas.
struct OrthoDrillView: View {
    let module: OrthoModule
    var focusRuleId: String? = nil
    var drillCount: Int = 8

    @EnvironmentObject var repetition: SpacedRepetition
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var tts: TTSService
    @EnvironmentObject var gemma: GemmaService
    @Environment(\.dismiss) private var dismiss

    @State private var drills: [OrthoDrill] = []
    @State private var index = 0
    @State private var chosen: String?
    @State private var typed = ""
    @State private var checked = false
    @State private var score = GameScore()
    @State private var finished = false
    @State private var confetti = 0
    @State private var isGenerating = false
    /// Change à chaque nouvelle série : c'est lui qui relance le chargement et
    /// la génération après un « encore une série ».
    @State private var sessionId = UUID()
    /// Le point d'insertion dans la saisie libre, en unités UTF-16 comme le
    /// veut UIKit : c'est lui qui permet d'écrire un accent au milieu d'un mot.
    @State private var selection = NSRange(location: 0, length: 0)
    @State private var fieldFocused = false

    private var current: OrthoDrill? {
        drills.indices.contains(index) ? drills[index] : nil
    }

    var body: some View {
        Group {
            if finished {
                summary
            } else if let drill = current {
                exercise(drill)
            } else {
                emptyState
            }
        }
        .background(Color.clear)
        .navigationTitle(module.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .overlay { ConfettiView(trigger: confetti).ignoresSafeArea() }
        .task(id: sessionId) {
            // Le chargement et la génération partagent la même tâche : ainsi
            // la seconde ne peut pas démarrer avant que la série existe, et un
            // « encore une série » relance les deux.
            loadDrills()
            await topUpWithGeneratedDrills()
        }
    }

    // =========================================================================
    // MARK: - Chargement
    // =========================================================================

    private func loadDrills() {
        guard drills.isEmpty else { return }
        // Une graine dérivée de l'heure : deux séances du même module ne
        // proposent pas la même série, mais une série en cours ne se réordonne
        // jamais sous les doigts de l'utilisateur.
        let seed = UInt64(abs(Int(Date().timeIntervalSince1970) / 600))

        if let focusRuleId {
            // Les exercices de la règle visée d'abord, complétés par ceux du
            // module : cinq questions sur une seule règle lasseraient.
            let focused = OrthoDrills.drills(ruleId: focusRuleId, count: 5)
            let rest = OrthoDrills.drills(module: module, count: drillCount, seed: seed)
                .filter { $0.ruleId != focusRuleId }
            drills = focused + rest.prefix(max(0, drillCount - focused.count))
        } else {
            drills = OrthoDrills.drills(module: module, count: drillCount, seed: seed)
        }
    }

    /// Remplace les derniers exercices de la série par des exercices écrits
    /// par Gemma, quand il est disponible.
    ///
    /// Deux décisions de conception. D'abord **le nombre d'exercices ne
    /// bouge pas** : un dénominateur qui grandit en cours de série (« 3 / 8 »
    /// devenant « 3 / 11 ») donne l'impression qu'on n'avance pas. Ensuite on
    /// ne remplace que des exercices **pas encore atteints** : voir une
    /// question changer sous les yeux serait déroutant.
    ///
    /// Si Gemma est absent ou si sa phrase ne passe pas les contrôles, la série
    /// vérifiée reste telle quelle. L'écran ne dépend jamais du modèle.
    private func topUpWithGeneratedDrills() async {
        guard gemma.isReady, !gemma.loadFailed, !drills.isEmpty else { return }

        // Les règles éligibles : celles du module, la règle visée en premier.
        var candidates = OrthoRules.rules(for: module)
        if let focusRuleId, let focused = OrthoRules.rule(id: focusRuleId) {
            candidates.removeAll { $0.id == focused.id }
            candidates.insert(focused, at: 0)
        }
        guard !candidates.isEmpty else { return }

        isGenerating = true
        defer { isGenerating = false }

        let native = progress.profile.nativeLanguage
        let level = progress.profile.level
        let replaceable = min(3, max(0, drills.count - 1))

        for offset in 0..<replaceable {
            let slot = drills.count - 1 - offset
            // L'utilisateur a rattrapé le créneau visé : on s'arrête là.
            guard slot > index else { break }
            guard candidates.indices.contains(offset % candidates.count) else { break }
            let rule = candidates[offset % candidates.count]
            guard let generated = await ContentGenerator.shared.drill(
                for: rule, native: native, level: level) else { continue }
            guard slot > index, drills.indices.contains(slot) else { break }
            drills[slot] = generated
        }
    }

    // =========================================================================
    // MARK: - Exercice
    // =========================================================================

    private func exercise(_ drill: OrthoDrill) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                progressHeader

                Text(drill.localizedInstruction)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                sentenceView(drill)

                if drill.kind == .choice || drill.kind == .accent {
                    optionsView(drill)
                } else {
                    freeInputView(drill)
                }

                if checked { feedback(drill) }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { bottomBar(drill) }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(L.t("game.round", index + 1, drills.count))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .monospacedDigit()
                if current?.isGenerated == true {
                    Chip(text: L.t("ortho.generated"), systemImage: "sparkles", tint: Theme.lavande)
                }
                Spacer()
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
            MasteryBar(value: Double(index) / Double(max(1, drills.count)),
                       tint: module.color, height: 5)

            // Le travail du modèle se dit en toutes lettres, sur sa propre
            // ligne : une simple étincelle à côté du compteur n'apprenait rien
            // à personne, et la mettre dans la même rangée que le score la
            // ferait tronquer sur un petit écran.
            if isGenerating {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text(L.t("ortho.generating"))
                        .font(Theme.Typography.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Theme.lavande.opacity(0.85))
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isGenerating)
    }

    /// La phrase, trou compris. Le trou est un trait souligné dans la couleur du
    /// module : il doit se repérer instantanément, y compris au milieu d'une
    /// phrase longue.
    private func sentenceView(_ drill: OrthoDrill) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(displaySentence(drill))
                .font(Theme.Typography.ortho)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if checked || drill.kind == .correction {
                SpeakerButton(text: drill.solvedSentence, size: 44, tint: module.color)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(module.color.opacity(0.3), lineWidth: 1))
    }

    private func displaySentence(_ drill: OrthoDrill) -> String {
        guard checked else { return drill.sentence.replacingOccurrences(of: "___", with: "_____") }
        return drill.solvedSentence
    }

    private func optionsView(_ drill: OrthoDrill) -> some View {
        VStack(spacing: 10) {
            ForEach(drill.shuffledOptions, id: \.self) { option in
                Button {
                    guard !checked else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    chosen = option
                } label: {
                    HStack(spacing: 12) {
                        Text(option)
                            .font(Theme.Typography.orthoSmall)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        if checked {
                            Image(systemName: option == drill.answer
                                  ? "checkmark.circle.fill" : (option == chosen ? "xmark.circle.fill" : "circle"))
                                .font(.system(size: 19))
                                .foregroundStyle(option == drill.answer ? Theme.emeraude
                                                 : (option == chosen ? Theme.grenat : .white.opacity(0.2)))
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(background(for: option, drill: drill)))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(border(for: option, drill: drill), lineWidth: chosen == option ? 2 : 1))
                }
                .buttonStyle(.plain)
                .disabled(checked)
            }
        }
    }

    private func background(for option: String, drill: OrthoDrill) -> Color {
        guard checked else { return chosen == option ? module.color.opacity(0.22) : Theme.glass }
        if option == drill.answer { return Theme.emeraude.opacity(0.20) }
        if option == chosen { return Theme.grenat.opacity(0.20) }
        return Theme.glass
    }

    private func border(for option: String, drill: OrthoDrill) -> Color {
        guard checked else { return chosen == option ? module.color : Theme.glassEdge }
        if option == drill.answer { return Theme.emeraude }
        if option == chosen { return Theme.grenat }
        return Theme.glassEdge
    }

    private func freeInputView(_ drill: OrthoDrill) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            OrthoTextField(text: $typed, selection: $selection, isEditing: $fieldFocused,
                           placeholder: drill.kind == .correction
                               ? String(drill.answer.prefix(1)) + "…" : "…",
                           tint: module.color,
                           onSubmit: { check(drill) })
                .frame(height: 34)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(checked
                            ? (isTypedCorrect(drill) ? Theme.emeraude : Theme.grenat)
                            : (fieldFocused ? module.color : Theme.glassEdge),
                            lineWidth: fieldFocused || checked ? 1.8 : 1))
                .disabled(checked)

            if !checked {
                // Au point d'insertion, pas à la fin : corriger « eleve »
                // demande un accent en deuxième lettre puis en quatrième.
                AccentKeyboardRow { character in
                    let result = typed.inserting(character, at: selection)
                    typed = result.text
                    selection = result.caret
                    fieldFocused = true
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
        }
    }

    /// Le retour après réponse. Il montre la forme attendue lettre par lettre
    /// quand la saisie était libre : voir *où* la graphie diverge vaut mieux
    /// que lire deux mots côte à côte.
    private func feedback(_ drill: OrthoDrill) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: wasCorrect(drill) ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 19))
                    .foregroundStyle(wasCorrect(drill) ? Theme.emeraude : Theme.grenat)
                Text(wasCorrect(drill) ? L.t("ortho.correct") : L.t("ortho.incorrect"))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(wasCorrect(drill) ? Theme.emeraude : Theme.grenat)
            }

            if !wasCorrect(drill), drill.kind != .choice, drill.kind != .accent {
                let verdict = OrthographyEngine.evaluate(expected: drill.answer, written: typed)
                OrthoDiffView(verdict: verdict, font: Theme.Typography.orthoSmall)
            }

            Text(drill.localizedExplanation)
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            if let rule = OrthoRules.rule(id: drill.ruleId), let mnemonic = rule.localizedMnemonic {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.or)
                    Text(mnemonic)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.orClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke((wasCorrect(drill) ? Theme.emeraude : Theme.grenat).opacity(0.4), lineWidth: 1))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func bottomBar(_ drill: OrthoDrill) -> some View {
        VStack(spacing: 0) {
            if checked {
                PrimaryButton(title: index == drills.count - 1 ? L.t("ortho.finish") : L.t("ortho.next"),
                              icon: "arrow.right",
                              gradient: LinearGradient(colors: [module.color, module.color.opacity(0.7)],
                                                       startPoint: .leading, endPoint: .trailing),
                              glowColor: module.color) {
                    advance()
                }
            } else {
                PrimaryButton(title: L.t("ortho.check"), icon: "checkmark",
                              gradient: LinearGradient(colors: [module.color, module.color.opacity(0.7)],
                                                       startPoint: .leading, endPoint: .trailing),
                              glowColor: module.color,
                              isEnabled: hasAnswer(drill)) {
                    check(drill)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // =========================================================================
    // MARK: - Logique
    // =========================================================================

    private func hasAnswer(_ drill: OrthoDrill) -> Bool {
        (drill.kind == .choice || drill.kind == .accent)
            ? chosen != nil
            : !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isTypedCorrect(_ drill: OrthoDrill) -> Bool {
        // Tolérance sur la casse et la ponctuation finale, jamais sur les
        // accents : les accepter viderait l'exercice de son objet.
        OrthographyEngine.isAcceptable(expected: drill.answer, written: typed)
    }

    private func wasCorrect(_ drill: OrthoDrill) -> Bool {
        (drill.kind == .choice || drill.kind == .accent)
            ? chosen == drill.answer
            : isTypedCorrect(drill)
    }

    private func check(_ drill: OrthoDrill) {
        fieldFocused = false
        let correct = wasCorrect(drill)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { checked = true }

        score.register(correct: correct, xp: 12)
        repetition.record(ruleId: drill.ruleId, score: correct ? 1.0 : 0.25)

        if correct {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            Task { await tts.speak(drill.solvedSentence) }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            // Une faute de saisie libre est classée et comptée : c'est elle qui
            // alimente le profil de fautes du profil.
            if drill.kind == .fill || drill.kind == .correction {
                let kind = OrthographyEngine.classify(expected: drill.answer, written: typed)
                progress.recordMistake(kind)
            }
        }
    }

    private func advance() {
        if index == drills.count - 1 {
            complete()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                index += 1
                chosen = nil
                typed = ""
                selection = NSRange(location: 0, length: 0)
                checked = false
            }
        }
    }

    private func complete() {
        progress.awardXP(score.xpEarned)
        progress.bumpStreak()
        let mastery = repetition.mastery(of: module)
        progress.checkModuleMastery(module, mastery: mastery)
        if score.total > 0 && score.correct == score.total {
            progress.unlock("perfect_game")
            confetti += 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { finished = true }
    }

    // =========================================================================
    // MARK: - Fin de série
    // =========================================================================

    private var summary: some View {
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
                Text(L.t("ortho.session_done"))
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                Text(score.correct == score.total
                     ? L.t("game.perfect")
                     : "\(L.t("ortho.accuracy")) \(Int(score.accuracy * 100)) %")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.7))
                Text(L.t("game.xp_earned", score.xpEarned))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.or)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L.t("ortho.mastery"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text("\(Int(repetition.mastery(of: module) * 100)) %")
                        .font(Theme.Typography.caption.bold())
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                MasteryBar(value: repetition.mastery(of: module), tint: module.color, height: 10)
            }
            .padding(.horizontal, 4)

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: L.t("ortho.again"), icon: "arrow.counterclockwise",
                              gradient: LinearGradient(colors: [module.color, module.color.opacity(0.7)],
                                                       startPoint: .leading, endPoint: .trailing),
                              glowColor: module.color) {
                    restart()
                }
                GhostButton(title: L.t("ortho.finish")) { dismiss() }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func restart() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            drills = []
            index = 0
            chosen = nil
            typed = ""
            selection = NSRange(location: 0, length: 0)
            checked = false
            score = GameScore()
            finished = false
        }
        // Relance la tâche : nouvelle série, et de nouveaux exercices écrits
        // par Gemma s'il est disponible.
        sessionId = UUID()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: module.iconName)
                .font(.system(size: 40))
                .foregroundStyle(module.color.opacity(0.6))
            Text(L.t("ortho.no_drills"))
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            GhostButton(title: L.t("ortho.finish")) { dismiss() }
                .frame(maxWidth: 200)
        }
        .padding(30)
    }
}
