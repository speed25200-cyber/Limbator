import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var repetition: SpacedRepetition
    @EnvironmentObject var tts: TTSService

    @State private var greeting = "Bonjour"

    /// La dictée du jour : la même toute la journée, une autre demain.
    /// Une graine dérivée du quantième garantit les deux.
    private var dailyDictation: DictationItem {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return DictationBank.pick(level: progress.profile.level, seed: UInt64(day))
    }

    private var dueRules: [OrthoRule] { repetition.dueRules(limit: 6) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    stats
                    dailyDictationCard
                    if !dueRules.isEmpty { reviewSection }
                    weaknessCard
                    quickActions
                    storiesRail
                    Spacer(minLength: 72)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .background(Color.clear)
            .navigationBarHidden(true)
            .overlay(alignment: .bottomTrailing) { tutorButton.padding(20) }
            .onAppear { updateGreeting() }
        }
    }

    // =========================================================================
    // MARK: - En-tête
    // =========================================================================

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting),")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.white.opacity(0.68))
                Text(progress.profile.name.isEmpty ? L.t("home.default_name") : progress.profile.name)
                    .font(Theme.Typography.display)
                    .foregroundStyle(.white)
                    .lineLimit(1).minimumScaleFactor(0.65)
            }
            Spacer()
            SpeakerButton(text: greeting, size: 48, tint: Theme.or)
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statTile(icon: .flame, value: "\(progress.profile.streakDays)",
                     label: L.t("home.stat_days"), tint: Theme.grenat)
            statTile(icon: .starFilled, value: "\(progress.profile.xp)",
                     label: L.t("home.stat_xp"), tint: Theme.or)
            statTile(icon: .quill,
                     value: progress.profile.dictationsDone > 0
                        ? String(format: "%.0f", progress.profile.dictationAverage)
                        : "—",
                     label: L.t("home.stat_average"), tint: Theme.emeraude)
        }
    }

    private func statTile(icon: LimbIcon, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            LimbIconView(icon: icon, size: 22,
                         gradient: LinearGradient(colors: [tint, tint.opacity(0.6)],
                                                  startPoint: .top, endPoint: .bottom),
                         glow: tint)
            Text(value)
                .font(Theme.Typography.title)
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .glassCard(cornerRadius: 20)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(tint.opacity(0.32), lineWidth: 1))
    }

    // =========================================================================
    // MARK: - Dictée du jour
    // =========================================================================

    private var dailyDictationCard: some View {
        let dictation = dailyDictation
        return GlowingCard(tint: Theme.bleuFrance) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Chip(text: L.t("home.dictation_title"),
                         systemImage: "pencil.and.scribble", tint: Theme.bleuFrance)
                    Spacer()
                    Text(L.t("home.dictation_badge"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.or)
                }

                // Le texte de la dictée n'est PAS montré : ce serait donner la
                // réponse. On annonce le niveau et le thème, rien de plus.
                HStack(spacing: 10) {
                    Chip(text: dictation.level.rawValue, tint: Theme.lavande)
                    Chip(text: L.t("lessons.minutes", max(1, dictation.wordCount / 6)),
                         systemImage: "clock", tint: Theme.glassEdge)
                }

                Text(L.t("home.dictation_cta"))
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)

                NavigationLink {
                    DictationView(item: dictation)
                } label: {
                    HStack(spacing: 8) {
                        Text(L.t("home.start")).font(Theme.Typography.headline)
                        Image(systemName: "arrow.right")
                    }
                    .padding(.horizontal, 24).padding(.vertical, 13)
                    .background(Capsule().fill(Theme.primaryGradient))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // =========================================================================
    // MARK: - Révisions du jour
    // =========================================================================

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("home.review_title"),
                          subtitle: L.t("home.review_subtitle", dueRules.count))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dueRules) { rule in
                        NavigationLink {
                            OrthoDrillView(module: rule.module, focusRuleId: rule.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: rule.module.iconName)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(rule.module.color)
                                Text(rule.localizedTitle)
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                                Chip(text: L.t("ortho.due_now"), tint: rule.module.color)
                            }
                            .frame(width: 154, height: 130, alignment: .leading)
                            .padding(14)
                            .glassCard(cornerRadius: 18)
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(rule.module.color.opacity(0.35), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // =========================================================================
    // MARK: - Point faible
    // =========================================================================

    private var weaknessCard: some View {
        let weaknesses = progress.profile.topWeaknesses
        return GlowingCard(tint: weaknesses.first?.color ?? Theme.lavande) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: L.t("home.weakness_title"))

                if weaknesses.isEmpty {
                    Text(L.t("home.weakness_none"))
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(weaknesses, id: \.self) { kind in
                            Chip(text: kind.localizedLabel, tint: kind.color)
                        }
                    }
                    NavigationLink {
                        OrthoDrillView(module: progress.priorityModule)
                    } label: {
                        HStack(spacing: 6) {
                            Text(L.t("ortho.train")).font(Theme.Typography.caption)
                            Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Theme.bleuFrance)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // =========================================================================
    // MARK: - Accès rapides
    // =========================================================================

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("home.quick_title"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                tile(icon: .quill, title: L.t("home.tile_dictation"),
                     subtitle: L.t("home.tile_dictation_sub"),
                     colors: [Theme.bleuFrance, Theme.indigo]) {
                    AnyView(DictationView(item: dailyDictation))
                }
                tile(icon: .duel, title: L.t("home.tile_homophone"),
                     subtitle: L.t("home.tile_homophone_sub"),
                     colors: [Theme.lavande, Theme.rose]) {
                    AnyView(QuizGameView(kind: .homophoneDuel))
                }
                actionTile(icon: .sparkles, title: L.t("home.tile_tutor"),
                           subtitle: L.t("home.tile_tutor_sub"),
                           colors: [Theme.emeraude, Theme.azur],
                           action: { appState.presentedTutor = true })
                tile(icon: .stories, title: L.t("home.tile_story"),
                     subtitle: L.t("home.tile_story_sub"),
                     colors: [Theme.or, Theme.grenat]) {
                    AnyView(StoryHubView())
                }
            }
        }
    }

    private func tile(icon: LimbIcon, title: String, subtitle: String,
                      colors: [Color], destination: @escaping () -> AnyView) -> some View {
        NavigationLink {
            destination()
        } label: {
            tileLabel(icon: icon, title: title, subtitle: subtitle, colors: colors)
        }
        .buttonStyle(.plain)
    }

    /// Même tuile, mais qui déclenche une action au lieu d'empiler une vue.
    ///
    /// Le tuteur en a besoin : il possède sa propre pile de navigation, et
    /// l'empiler dans celle de l'accueil superposait deux barres de navigation
    /// avec deux boutons de retour. Il s'ouvre donc en feuille, comme depuis
    /// la barre d'onglets.
    private func actionTile(icon: LimbIcon, title: String, subtitle: String,
                            colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            tileLabel(icon: icon, title: title, subtitle: subtitle, colors: colors)
        }
        .buttonStyle(.plain)
    }

    private func tileLabel(icon: LimbIcon, title: String, subtitle: String,
                           colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            LimbIconView(icon: icon, size: 27,
                         gradient: LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom),
                         glow: .white)
                .padding(8)
                .background(Circle().fill(.white.opacity(0.18)))
            Spacer(minLength: 0)
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.75)
            Text(subtitle)
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 152)
        .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: (colors.first ?? Theme.bleuFrance).opacity(0.38), radius: 14, x: 0, y: 8)
    }

    // =========================================================================
    // MARK: - Histoires
    // =========================================================================

    private var storiesRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("home.stories_title")) {
                NavigationLink {
                    StoryHubView()
                } label: {
                    Text(L.t("home.stories_all"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.bleuFrance)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Story.builtIn) { story in
                        NavigationLink {
                            StoryReaderView(story: story)
                        } label: {
                            StoryCoverCard(story: story, width: 200, height: 148)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var tutorButton: some View {
        Button {
            appState.presentedTutor = true
        } label: {
            HStack(spacing: 8) {
                LimbIconView(icon: .sparkles, size: 14,
                             gradient: LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom))
                Text(L.t("tutor.title")).font(Theme.Typography.body)
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(Capsule().fill(Theme.primaryGradient))
            .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
            .foregroundStyle(.white)
            .shadow(color: Theme.bleuFrance.opacity(0.5), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    /// La salutation suit l'heure — et elle est en français, parce qu'elle est
    /// aussi la première leçon de la journée.
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        greeting = hour < 12 ? L.t("home.greeting_morning")
            : (hour < 18 ? L.t("home.greeting_afternoon") : L.t("home.greeting_evening"))
    }
}
