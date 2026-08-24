import SwiftUI

/// Une leçon : l'introduction, les cartes de vocabulaire, les expressions,
/// l'encadré d'orthographe, et la validation.
struct LessonDetailView: View {
    let topic: LessonTopic

    @EnvironmentObject var gemma: GemmaService
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var repetition: SpacedRepetition
    @Environment(\.dismiss) private var dismiss

    @State private var content: LessonContent?
    @State private var cardIndex = 0
    @State private var isEnriching = false

    private var isDone: Bool { progress.profile.completedLessons.contains(topic.slug) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                heroHeader
                if let content {
                    introduction(content)
                    if let spotlight = content.orthoSpotlight { spotlightCard(spotlight) }
                    vocabularySection(content)
                    phrasesSection(content)
                    notes(content)
                    completeButton
                } else {
                    loadingState
                }
                Spacer(minLength: 60)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color.clear)
        .navigationTitle(topic.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    // =========================================================================
    // MARK: - Chargement
    // =========================================================================

    private func load() async {
        // Le contenu vérifié s'affiche IMMÉDIATEMENT. L'enrichissement par
        // Gemma arrive ensuite, s'il arrive : personne ne doit attendre devant
        // un écran vide pendant qu'un modèle réfléchit.
        guard content == nil else { return }
        content = ContentSeeds.lesson(topic: topic)

        guard gemma.isReady, !gemma.loadFailed else { return }
        isEnriching = true
        defer { isEnriching = false }
        let native = progress.profile.nativeLanguage
        let level = progress.profile.level
        let enriched = try? await ContentGenerator.shared.lesson(topic: topic, native: native, level: level)
        if let enriched {
            withAnimation(.easeInOut(duration: 0.4)) { content = enriched }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView().tint(topic.accent)
            Text(L.t("lesson.loading"))
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // =========================================================================
    // MARK: - Sections
    // =========================================================================

    private var heroHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [topic.accent, topic.accent.opacity(0.5)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 62, height: 62)
                Image(systemName: topic.icon.systemName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(topic.frenchTitle)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Chip(text: topic.difficulty.rawValue, tint: topic.accent)
                    Chip(text: L.t("lessons.minutes", topic.estimatedMinutes),
                         systemImage: "clock", tint: Theme.glassEdge)
                    if isEnriching {
                        Chip(text: "Gemma", systemImage: "sparkles", tint: Theme.lavande)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func introduction(_ content: LessonContent) -> some View {
        Text(content.localizedIntroduction)
            .font(Theme.Typography.body)
            .foregroundStyle(.white.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// L'encadré d'orthographe : la raison d'être de la leçon, placée avant le
    /// vocabulaire pour que l'apprenant lise les mots en sachant quoi observer.
    private func spotlightCard(_ spotlight: LessonContent.OrthoSpotlight) -> some View {
        GlowingCard(tint: spotlight.module.color) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: spotlight.module.iconName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(spotlight.module.color)
                    Text(L.t("lesson.ortho_spotlight"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(spotlight.module.color)
                        .textCase(.uppercase)
                        .tracking(1.2)
                }

                Text(spotlight.localizedTitle)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.white)

                Text(spotlight.localizedRule)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(spotlight.rightWrong) { pair in
                        HStack(spacing: 10) {
                            Text(pair.right)
                                .font(Theme.Typography.orthoSmall)
                                .foregroundStyle(Theme.emeraude)
                            Text(pair.wrong)
                                .font(Theme.Typography.orthoSmall)
                                .strikethrough(true, color: Theme.grenat.opacity(0.75))
                                .foregroundStyle(Theme.grenat.opacity(0.7))
                            Spacer(minLength: 0)
                            SpeakerChip(text: pair.right, label: "")
                        }
                    }
                }

                NavigationLink {
                    OrthoModuleView(module: spotlight.module)
                } label: {
                    HStack(spacing: 6) {
                        Text(L.t("ortho.review_rule")).font(Theme.Typography.caption)
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(spotlight.module.color)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func vocabularySection(_ content: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("lesson.vocabulary")) {
                Text(L.t("lesson.card_index", min(cardIndex + 1, content.cards.count), content.cards.count))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .monospacedDigit()
            }

            if content.cards.isEmpty {
                EmptyView()
            } else {
                TabView(selection: $cardIndex) {
                    ForEach(Array(content.cards.enumerated()), id: \.element.id) { entry in
                        VocabCardView(card: entry.element, accent: topic.accent)
                            .padding(.horizontal, 2)
                            .tag(entry.offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 300)
                .onChange(of: cardIndex) { _, index in
                    // Voir une carte compte comme une répétition faible : elle
                    // entre dans le calendrier sans prétendre être acquise.
                    guard content.cards.indices.contains(index) else { return }
                    repetition.record(word: content.cards[index].french, score: 0.65)
                }
            }
        }
    }

    private func phrasesSection(_ content: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("lesson.phrases"))
            ForEach(content.phrases) { phrase in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 10) {
                        Text(phrase.french)
                            .font(Theme.Typography.orthoSmall)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        SpeakerChip(text: phrase.french, label: "")
                    }
                    Text(phrase.localizedTranslation)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(phrase.localizedContext)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 18)
            }
        }
    }

    private func notes(_ content: LessonContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let tip = content.localizedGrammarTip {
                noteCard(title: L.t("lesson.grammar_tip"), text: tip,
                         icon: "text.book.closed.fill", tint: Theme.bleuFrance)
            }
            if let note = content.localizedCulturalNote {
                noteCard(title: L.t("lesson.cultural_note"), text: note,
                         icon: "globe.europe.africa.fill", tint: Theme.or)
            }
        }
    }

    private func noteCard(title: String, text: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13, weight: .bold))
                Text(title).font(Theme.Typography.caption).textCase(.uppercase).tracking(1.1)
            }
            .foregroundStyle(tint)
            Text(text)
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(tint.opacity(0.28), lineWidth: 1))
    }

    private var completeButton: some View {
        PrimaryButton(title: isDone ? L.t("lesson.completed") : L.t("lesson.mark_complete"),
                      icon: isDone ? "checkmark.seal.fill" : "checkmark",
                      gradient: isDone
                        ? LinearGradient(colors: [Theme.emeraude, Theme.emeraude.opacity(0.7)],
                                         startPoint: .leading, endPoint: .trailing)
                        : Theme.primaryGradient,
                      glowColor: isDone ? Theme.emeraude : Theme.bleuFrance) {
            progress.completeLesson(topic.slug)
        }
    }
}

/// Une carte de vocabulaire, retournable.
///
/// La face avant montre le mot français avec son article — le genre fait partie
/// du mot, l'apprendre séparément c'est l'apprendre faux. La face arrière donne
/// le sens, l'exemple, et la note d'orthographe.
struct VocabCardView: View {
    let card: VocabCard
    var accent: Color = Theme.bleuFrance

    @State private var flipped = false

    var body: some View {
        // La carte entière tourne d'un demi-tour autour de l'axe vertical, ce
        // qui met son contenu en miroir. Le verso porte donc la rotation
        // inverse : sans elle, il s'affichait à l'envers, lettres comprises.
        //
        // Les deux faces coexistent et se croisent en opacité plutôt que de
        // s'échanger d'un coup : l'échange instantané montrait le verso avant
        // même que la carte ait commencé à tourner.
        ZStack {
            front
                .opacity(flipped ? 0 : 1)
                .accessibilityHidden(flipped)
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(flipped ? 1 : 0)
                .accessibilityHidden(!flipped)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 290)
        .glassCard(cornerRadius: 26)
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(accent.opacity(0.35), lineWidth: 1))
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: flipped)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            flipped.toggle()
        }
        // Un `onTapGesture` seul est invisible pour VoiceOver : la carte se
        // lisait, mais personne ne pouvait la retourner à la voix.
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(L.t("lesson.flip"))
        .accessibilityAction { flipped.toggle() }
    }

    private var front: some View {
        VStack(spacing: 14) {
            Spacer()
            Text(card.withArticle)
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.55)
                .lineLimit(2)
            Text(card.phonetic)
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            HStack(spacing: 12) {
                SpeakerButton(text: card.french, size: 52, tint: accent)
                SpeakerButton(text: card.french, size: 44, tint: Theme.or, delivery: .spelled)
            }
            Text(L.t("lesson.flip"))
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.35))
            Spacer(minLength: 6)
        }
        .padding(20)
    }

    private var back: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(card.localizedTranslation)
                .font(Theme.Typography.title)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(Theme.glassEdge)

            VStack(alignment: .leading, spacing: 4) {
                Text(L.t("lesson.example"))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase).tracking(1.1)
                Text(card.exampleSentence)
                    .font(Theme.Typography.orthoSmall)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(card.localizedExampleTranslation)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.66))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let note = card.localizedSpellingNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.or)
                    Text(note)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.orClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.or.opacity(0.10)))
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    }
}
