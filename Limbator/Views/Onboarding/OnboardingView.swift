import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var progress: ProgressTracker

    @State private var step = 0
    @State private var name = ""
    @State private var languageId = OnboardingView.suggestedLanguage()
    @State private var level: ProficiencyLevel = .a1
    @State private var dailyGoal = 10

    private let stepCount = 4

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            TabView(selection: $step) {
                hero.tag(0)
                languagePicker.tag(1)
                levelPicker.tag(2)
                goalPicker.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }

    // =========================================================================
    // MARK: - Étapes
    // =========================================================================

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { index in
                Capsule()
                    .fill(index <= step
                          ? AnyShapeStyle(Theme.primaryGradient)
                          : AnyShapeStyle(Color.white.opacity(0.14)))
                    .frame(height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: step)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var hero: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                Spacer(minLength: 20)

                ZStack {
                    Circle()
                        .fill(Theme.primaryGradient)
                        .frame(width: 230, height: 230)
                        .blur(radius: 70)
                        .opacity(0.55)
                    AccentEmblem(animated: true)
                        .frame(width: 190, height: 190)
                }

                VStack(spacing: 12) {
                    Text("Limbator")
                        .font(Theme.Typography.display)
                        .foregroundStyle(LinearGradient(colors: [.white, Theme.orClair],
                                                        startPoint: .top, endPoint: .bottom))
                    Text(L.t("onboarding.tagline"))
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                HStack(spacing: 10) {
                    badge(icon: .brain, title: L.t("onboarding.badge_gemma"),
                          subtitle: L.t("onboarding.badge_offline"), tint: Theme.lavande)
                    badge(icon: .speakerWaves, title: L.t("onboarding.badge_voice"),
                          subtitle: L.t("onboarding.badge_voice_sub"), tint: Theme.azur)
                    badge(icon: .ortho, title: L.t("onboarding.badge_ortho"),
                          subtitle: L.t("onboarding.badge_ortho_sub"), tint: Theme.or)
                }
                .padding(.horizontal, 22)

                VStack(spacing: 10) {
                    Text(L.t("onboarding.ask_name"))
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.8))
                    TextField("", text: $name,
                              prompt: Text(L.t("onboarding.name_placeholder"))
                                .foregroundStyle(.white.opacity(0.38)))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(Theme.glass)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.glassEdge, lineWidth: 1))
                        .padding(.horizontal, 32)
                }

                Spacer(minLength: 24)
            }
        }
    }

    private var languagePicker: some View {
        VStack(spacing: 16) {
            header(L.t("onboarding.native_language_title"),
                   L.t("onboarding.native_language_subtitle"))

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(NativeLanguage.all) { language in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                languageId = language.id
                            }
                            // L'interface bascule immédiatement : l'utilisateur
                            // voit le résultat de son choix avant de valider.
                            L.lang = language.id
                        } label: {
                            VStack(spacing: 10) {
                                FlagBadge(regionCode: language.regionCode, height: 34)
                                Text(language.displayName)
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(.white)
                                Text(language.englishName)
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(languageId == language.id ? Theme.bleuFrance.opacity(0.24) : Theme.glass))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(languageId == language.id ? Theme.bleuFrance : Theme.glassEdge,
                                        lineWidth: languageId == language.id ? 2 : 1))
                            .scaleEffect(languageId == language.id ? 1.03 : 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var levelPicker: some View {
        VStack(spacing: 16) {
            header(L.t("onboarding.level_title"), L.t("onboarding.level_subtitle"))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(ProficiencyLevel.allCases) { candidate in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                level = candidate
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: candidate.iconName)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(Theme.goldGradient)
                                    .frame(width: 46)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(candidate.localizedTitle)
                                            .font(Theme.Typography.headline)
                                            .foregroundStyle(.white)
                                        Text(candidate.rawValue)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(Capsule().fill(.white.opacity(0.15)))
                                            .foregroundStyle(.white)
                                    }
                                    Text(candidate.localizedSubtitle)
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(.white.opacity(0.62))
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Image(systemName: level == candidate ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 23))
                                    .foregroundStyle(level == candidate ? Theme.emeraude : .white.opacity(0.28))
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(level == candidate ? Theme.emeraude.opacity(0.16) : Theme.glass))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(level == candidate ? Theme.emeraude : Theme.glassEdge,
                                        lineWidth: level == candidate ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var goalPicker: some View {
        VStack(spacing: 24) {
            header(L.t("onboarding.goal_title"), L.t("onboarding.goal_subtitle"))

            ZStack {
                ProgressRing(progress: Double(dailyGoal) / 60.0, lineWidth: 12)
                    .frame(width: 196, height: 196)
                VStack(spacing: 4) {
                    Text("\(dailyGoal)")
                        .font(.system(size: 62, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    Text(L.t("onboarding.minutes_per_day"))
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.68))
                }
            }

            HStack(spacing: 12) {
                ForEach([5, 10, 15, 30, 60], id: \.self) { value in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { dailyGoal = value }
                    } label: {
                        Text("\(value)")
                            .font(Theme.Typography.headline)
                            .monospacedDigit()
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(dailyGoal == value
                                ? AnyShapeStyle(Theme.primaryGradient)
                                : AnyShapeStyle(Theme.glass)))
                            .overlay(Circle().stroke(Theme.glassEdge, lineWidth: 1))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
    }

    // =========================================================================
    // MARK: - Pied de page
    // =========================================================================

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                GhostButton(title: L.t("onboarding.back"), icon: "chevron.left") {
                    withAnimation { step -= 1 }
                }
            }
            PrimaryButton(title: step == stepCount - 1 ? L.t("onboarding.start") : L.t("onboarding.continue"),
                          icon: step == stepCount - 1 ? "sparkles" : "chevron.right") {
                if step < stepCount - 1 {
                    withAnimation { step += 1 }
                } else {
                    finish()
                }
            }
        }
    }

    private func finish() {
        var profile = progress.profile
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.nativeLanguageId = languageId
        profile.level = level
        profile.dailyGoalMinutes = dailyGoal
        progress.profile = profile
        appState.isOnboarded = true
    }

    // =========================================================================
    // MARK: - Outils
    // =========================================================================

    /// La langue du téléphone si Limbator la connaît, le roumain sinon —
    /// puisque c'est le public auquel l'app s'adresse d'abord.
    private static func suggestedLanguage() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "ro"
        return NativeLanguage.all.contains(where: { $0.id == code }) ? code : "ro"
    }

    private func header(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(Theme.Typography.title)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private func badge(icon: LimbIcon, title: String, subtitle: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            LimbIconView(icon: icon, size: 21,
                         gradient: LinearGradient(colors: [tint, tint.opacity(0.62)],
                                                  startPoint: .top, endPoint: .bottom),
                         glow: tint)
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.glass))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Theme.glassEdge, lineWidth: 1))
    }
}
