import SwiftUI

/// La lecture d'une histoire, scène par scène.
///
/// Chaque scène propose trois couches, dans cet ordre : le français seul, la
/// traduction si on la demande, et l'arrêt sur mot. Cet ordre compte — montrer
/// la traduction d'emblée dispenserait de lire le français.
struct StoryReaderView: View {
    let story: Story

    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var gemma: GemmaService
    @EnvironmentObject var tts: TTSService
    @Environment(\.dismiss) private var dismiss

    @State private var chapterIndex = 1
    @State private var scenes: [StoryScene] = []
    @State private var sceneIndex = 0
    @State private var showTranslation = false
    @State private var selectedWord: HighlightedWord?
    @State private var chosenBranch: String?

    private var chapter: StoryChapter { story.chapter(chapterIndex) }
    private var scene: StoryScene? {
        scenes.indices.contains(sceneIndex) ? scenes[sceneIndex] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            chapterBar
            if let scene {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        sceneCard(scene)
                        if let highlight = scene.orthoHighlight { orthoStop(highlight) }
                        vocabRail(scene)
                        if let choice = scene.choice { branching(choice) }
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            } else {
                loading
            }
            navigation
        }
        .background(Color.clear)
        .navigationTitle(story.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: chapterIndex) { await loadChapter() }
        .onDisappear { tts.cancel() }
        .sheet(item: $selectedWord) { word in
            WordSheet(word: word)
                .presentationDetents([.height(260)])
                .presentationBackground(.ultraThinMaterial)
        }
    }

    // =========================================================================
    // MARK: - Chargement
    // =========================================================================

    private func loadChapter() async {
        // Les scènes vérifiées s'affichent tout de suite ; Gemma peut ensuite
        // proposer sa version, jamais l'inverse.
        scenes = StorySeeds.scenes(story: story, chapter: chapter)
        sceneIndex = 0
        showTranslation = false
        chosenBranch = nil

        guard gemma.isReady, !gemma.loadFailed else { return }
        let native = progress.profile.nativeLanguage
        let level = progress.profile.level
        let generated = await ContentGenerator.shared.storyScenes(
            story: story, chapter: chapter, native: native, level: level)
        if generated.count >= 3 {
            withAnimation(.easeInOut(duration: 0.4)) { scenes = generated }
        }
    }

    private var loading: some View {
        VStack(spacing: 14) {
            ProgressView().tint(story.orthoFocus.color)
            Text(L.t("story.loading"))
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // =========================================================================
    // MARK: - Chapitre
    // =========================================================================

    private var chapterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(story.chapters) { candidate in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            chapterIndex = candidate.index
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: candidate.iconName).font(.system(size: 11, weight: .bold))
                            Text(candidate.localizedTitleNative)
                                .font(Theme.Typography.caption)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Capsule().fill(chapterIndex == candidate.index
                            ? AnyShapeStyle(LinearGradient(colors: [story.orthoFocus.color,
                                                                    story.orthoFocus.color.opacity(0.6)],
                                                           startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Theme.glass)))
                        .overlay(Capsule().stroke(chapterIndex == candidate.index
                                                  ? .clear : Theme.glassEdge, lineWidth: 1))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    // =========================================================================
    // MARK: - Scène
    // =========================================================================

    private func sceneCard(_ scene: StoryScene) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L.t("story.scene_index", sceneIndex + 1, scenes.count))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .monospacedDigit()
                Spacer()
                SpeakerChip(text: scene.paragraphFrench, label: "")
                SpeakerChip(text: scene.paragraphFrench, label: L.t("component.slow"), delivery: .slow)
            }

            Text(scene.paragraphFrench)
                .font(.system(size: 19, weight: .regular, design: .serif))
                .foregroundStyle(.white)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showTranslation.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showTranslation ? "eye.slash" : "eye")
                        .font(.system(size: 11, weight: .bold))
                    Text(L.t("story.translation")).font(Theme.Typography.caption)
                }
                .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)

            if showTranslation {
                Text(scene.localizedParagraphNative)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 24)
    }

    /// L'arrêt sur mot : la scène s'interrompt un instant pour une remarque
    /// d'orthographe. C'est ce qui fait d'un récit une leçon.
    private func orthoStop(_ highlight: StoryScene.OrthoHighlight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: highlight.module.iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(highlight.module.color)
                .frame(width: 36, height: 36)
                .background(Circle().fill(highlight.module.color.opacity(0.16)))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(highlight.word)
                        .font(Theme.Typography.orthoSmall)
                        .foregroundStyle(.white)
                    SpeakerChip(text: highlight.word, label: "", delivery: .spelled)
                }
                Text(highlight.localizedNote)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(highlight.module.color.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(highlight.module.color.opacity(0.32), lineWidth: 1))
    }

    private func vocabRail(_ scene: StoryScene) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: L.t("story.vocab"))
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(scene.highlightedVocab) { word in
                    Button {
                        selectedWord = word
                    } label: {
                        Text(word.french)
                            .font(Theme.Typography.orthoSmall)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(Theme.glass))
                            .overlay(Capsule().stroke(Theme.or.opacity(0.42), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func branching(_ choice: StoryChoice) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(choice.localizedPrompt)
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(choice.options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        chosenBranch = option
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await tts.speak(option) }
                } label: {
                    HStack {
                        Text(option)
                            .font(Theme.Typography.body)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        if chosenBranch == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(story.orthoFocus.color)
                        }
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(chosenBranch == option
                              ? story.orthoFocus.color.opacity(0.2) : Theme.glass))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(chosenBranch == option ? story.orthoFocus.color : Theme.glassEdge,
                                lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // =========================================================================
    // MARK: - Navigation
    // =========================================================================

    private var navigation: some View {
        HStack(spacing: 12) {
            GhostButton(title: L.t("story.previous"), icon: "chevron.left") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if sceneIndex > 0 {
                        sceneIndex -= 1
                    } else if chapterIndex > 1 {
                        chapterIndex -= 1
                    }
                    showTranslation = false
                }
            }
            .disabled(sceneIndex == 0 && chapterIndex == 1)
            .opacity(sceneIndex == 0 && chapterIndex == 1 ? 0.35 : 1)

            PrimaryButton(title: isLastScene ? L.t("story.finish") : L.t("story.next"),
                          icon: isLastScene ? "checkmark" : "chevron.right",
                          gradient: LinearGradient(colors: [story.orthoFocus.color,
                                                            story.orthoFocus.color.opacity(0.7)],
                                                   startPoint: .leading, endPoint: .trailing),
                          glowColor: story.orthoFocus.color) {
                advance()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var isLastScene: Bool {
        sceneIndex >= scenes.count - 1 && chapterIndex >= story.chapters.count
    }

    private func advance() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if sceneIndex < scenes.count - 1 {
                sceneIndex += 1
                showTranslation = false
            } else if chapterIndex < story.chapters.count {
                chapterIndex += 1
            } else {
                finish()
            }
        }
    }

    private func finish() {
        progress.profile.unlockedStories.insert(story.slug)
        progress.awardXP(80)
        progress.unlock("story_done")
        if story.slug == "brancusi" { progress.unlock("brancusi") }
        progress.bumpStreak()
        dismiss()
    }
}

/// La fiche d'un mot mis en avant : sa graphie, sa prononciation, son sens, et
/// l'épellation à la demande.
struct WordSheet: View {
    let word: HighlightedWord
    @EnvironmentObject var tts: TTSService

    var body: some View {
        VStack(spacing: 18) {
            Text(word.french)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            Text(word.phonetic)
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.6))

            Text(word.localizedTranslation)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.emeraude)
                .multilineTextAlignment(.center)

            HStack(spacing: 14) {
                SpeakerButton(text: word.french, size: 52, tint: Theme.bleuFrance)
                SpeakerButton(text: word.french, size: 46, tint: Theme.or, delivery: .spelled)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}
