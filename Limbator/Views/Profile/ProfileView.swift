import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var repetition: SpacedRepetition
    @EnvironmentObject var gemma: GemmaService
    @EnvironmentObject var tts: TTSService

    @State private var confirmReset = false
    @State private var azureKey = ""
    @State private var azureRegion = ""
    @State private var showAzureFields = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    identityCard
                    statsRow
                    mistakeProfile
                    masterySection
                    badgesSection
                    voiceSection
                    modelSection
                    languageSection
                    dangerZone
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }
            .navigationBarHidden(true)
        }
    }

    // =========================================================================
    // MARK: - Identité
    // =========================================================================

    private var identityCard: some View {
        GlowingCard(tint: Theme.or) {
            VStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: progress.profile.tierProgress, lineWidth: 6)
                        .frame(width: 92, height: 92)
                    Text(initials)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.goldGradient)
                }

                VStack(spacing: 5) {
                    Text(progress.profile.name.isEmpty
                         ? L.t("profile.default_name") : progress.profile.name)
                        .font(Theme.Typography.title)
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        Chip(text: L.t("profile.level_label", progress.profile.levelTier), tint: Theme.or)
                        Chip(text: L.t("profile.xp_label", progress.profile.xp), tint: Theme.bleuFrance)
                        Chip(text: progress.profile.level.rawValue, tint: Theme.lavande)
                    }
                    Text(L.t("profile.xp_to_next", progress.profile.xpToNextTier,
                             progress.profile.levelTier + 1))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var initials: String {
        let name = progress.profile.name.trimmingCharacters(in: .whitespaces)
        guard let first = name.first else { return "L" }
        return String(first).uppercased()
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            stat(value: "\(progress.profile.streakDays)", label: L.t("profile.stat_streak"), tint: Theme.grenat)
            stat(value: "\(progress.profile.completedLessons.count)", label: L.t("profile.stat_lessons"), tint: Theme.bleuFrance)
            stat(value: "\(progress.profile.dictationsDone)", label: L.t("profile.stat_dictations"), tint: Theme.emeraude)
            stat(value: "\(progress.profile.badgesEarned.count)", label: L.t("profile.stat_badges"), tint: Theme.or)
        }
    }

    private func stat(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 18)
    }

    // =========================================================================
    // MARK: - Profil de fautes
    // =========================================================================

    /// Une catégorie de faute et son décompte. Un type nommé plutôt qu'un
    /// tuple : `ForEach` exige un identifiant stable, et le code se lit mieux.
    struct MistakeStat: Identifiable {
        var id: String { kind.rawValue }
        let kind: OrthoErrorKind
        let count: Int
    }

    /// Ce que Limbator sait de plus utile sur son utilisateur : où il se trompe.
    private var mistakeProfile: some View {
        let counts: [MistakeStat] = progress.profile.mistakeCounts
            .compactMap { entry in
                guard let kind = OrthoErrorKind(rawValue: entry.key), entry.value > 0 else { return nil }
                return MistakeStat(kind: kind, count: entry.value)
            }
            .sorted { ($0.count, $0.kind.rawValue) > ($1.count, $1.kind.rawValue) }
        let maximum = counts.first?.count ?? 1

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("profile.mistakes_title"))

            if counts.isEmpty {
                Text(L.t("profile.mistakes_empty"))
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard(cornerRadius: 18)
            } else {
                VStack(spacing: 10) {
                    ForEach(counts.prefix(6)) { stat in
                        NavigationLink {
                            OrthoModuleView(module: stat.kind.module)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(stat.kind.localizedLabel)
                                        .font(Theme.Typography.body)
                                        .foregroundStyle(.white)
                                    MasteryBar(value: Double(stat.count) / Double(maximum),
                                               tint: stat.kind.color, height: 6)
                                }
                                Text("\(stat.count)")
                                    .font(Theme.Typography.caption.bold())
                                    .foregroundStyle(stat.kind.color)
                                    .monospacedDigit()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(14)
                            .glassCard(cornerRadius: 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // =========================================================================
    // MARK: - Maîtrise
    // =========================================================================

    private var masterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("profile.mastery_title"),
                          subtitle: L.t("profile.words_tracked", repetition.trackedWordCount))
            VStack(spacing: 9) {
                ForEach(OrthoModule.allCases) { module in
                    HStack(spacing: 12) {
                        Image(systemName: module.iconName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(module.color)
                            .frame(width: 26)
                        Text(module.localizedTitle)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .frame(width: 118, alignment: .leading)
                        MasteryBar(value: repetition.mastery(of: module), tint: module.color, height: 7)
                    }
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 20)
        }
    }

    // =========================================================================
    // MARK: - Insignes
    // =========================================================================

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("profile.rewards_title"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(Badge.catalog) { badge in
                    let earned = progress.profile.badgesEarned.contains(badge.code)
                    VStack(spacing: 6) {
                        Image(systemName: badge.iconName)
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(earned
                                             ? AnyShapeStyle(Theme.goldGradient)
                                             : AnyShapeStyle(Color.white.opacity(0.16)))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(earned ? Theme.or.opacity(0.14) : Theme.glass))
                            .overlay(Circle().stroke(earned ? Theme.or.opacity(0.45) : Theme.glassEdge,
                                                     lineWidth: 1))
                        Text(badge.title)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(earned ? 0.85 : 0.3))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(height: 24)
                    }
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 20)
        }
    }

    // =========================================================================
    // MARK: - Voix
    // =========================================================================

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("profile.voice_title"), subtitle: tts.engineDiagnostic)

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(TTSService.Gender.allCases) { candidate in
                        Button {
                            tts.gender = candidate
                            tts.settingsChanged()
                            Task { await tts.speak("Bonjour, je suis votre voix française.") }
                        } label: {
                            Text(candidate.localizedLabel)
                                .font(Theme.Typography.body)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(tts.gender == candidate
                                          ? AnyShapeStyle(Theme.primaryGradient)
                                          : AnyShapeStyle(Theme.glass)))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(tts.gender == candidate ? .clear : Theme.glassEdge, lineWidth: 1))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L.t("profile.voice_speed"))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text(String(format: "%.2f×", tts.playbackRate))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                    Slider(value: $tts.playbackRate, in: 0.5...1.5, step: 0.05)
                        .tint(Theme.bleuFrance)
                }

                Toggle(isOn: Binding(
                    get: { tts.preferOnDevice },
                    set: { tts.preferOnDevice = $0; tts.settingsChanged() })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.t("profile.voice_ondevice"))
                            .font(Theme.Typography.body)
                            .foregroundStyle(.white)
                        Text(L.t("profile.voice_ondevice_sub"))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .tint(Theme.emeraude)

                azureControls
            }
            .padding(16)
            .glassCard(cornerRadius: 20)
        }
    }

    private var azureControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    showAzureFields.toggle()
                }
            } label: {
                HStack {
                    Text(L.t("profile.azure_title"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    if AzureTTS.isConfigured {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.emeraude)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .rotationEffect(.degrees(showAzureFields ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if showAzureFields {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L.t("profile.azure_hint"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)

                    SecureField("", text: $azureKey,
                                prompt: Text(L.t("profile.azure_key"))
                                    .foregroundStyle(.white.opacity(0.3)))
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.glass))

                    TextField("", text: $azureRegion,
                              prompt: Text(L.t("profile.azure_region"))
                                .foregroundStyle(.white.opacity(0.3)))
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.glass))

                    HStack(spacing: 10) {
                        Button {
                            AzureTTS.setCredentials(key: azureKey, region: azureRegion)
                            tts.settingsChanged()
                            azureKey = ""
                            Task { await tts.speak("La voix Azure est active.") }
                        } label: {
                            Text(L.t("profile.azure_save"))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(Capsule().fill(Theme.bleuFrance))
                        }
                        .buttonStyle(.plain)
                        .disabled(azureKey.trimmingCharacters(in: .whitespaces).isEmpty)

                        if AzureTTS.isConfigured {
                            Button {
                                AzureTTS.clearCredentials()
                                tts.settingsChanged()
                            } label: {
                                Text(L.t("profile.azure_clear"))
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.grenat)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // =========================================================================
    // MARK: - Modèle
    // =========================================================================

    private var modelSection: some View {
        Button {
            if gemma.loadFailed { Task { await gemma.retryLoad() } }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(gemma.loadFailed ? Theme.grenat : Theme.lavande)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill((gemma.loadFailed ? Theme.grenat : Theme.lavande).opacity(0.15)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(L.t("profile.gemma_title"))
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white)
                    Text(modelStatus)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                if gemma.loadFailed {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.grenat)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private var modelStatus: String {
        if gemma.loadFailed { return L.t("profile.gemma_failed") }
        if gemma.isWarmingUp { return L.t("profile.gemma_loading") }
        if gemma.isReady { return "\(gemma.variant.label) · \(L.t("profile.gemma_ready"))" }
        return L.t("profile.gemma_loading")
    }

    // =========================================================================
    // MARK: - Langue
    // =========================================================================

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("profile.native_language_title"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(NativeLanguage.all) { language in
                        Button {
                            progress.profile.nativeLanguageId = language.id
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            VStack(spacing: 6) {
                                FlagBadge(regionCode: language.regionCode, height: 26)
                                Text(language.displayName)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            .frame(width: 74)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(progress.profile.nativeLanguageId == language.id
                                      ? Theme.bleuFrance.opacity(0.24) : Theme.glass))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(progress.profile.nativeLanguageId == language.id
                                        ? Theme.bleuFrance : Theme.glassEdge, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // =========================================================================
    // MARK: - Réinitialisation
    // =========================================================================

    private var dangerZone: some View {
        VStack(spacing: 10) {
            Button {
                tts.clearAudioCache()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text(L.t("profile.cache_clear", cacheSize))
                        .font(Theme.Typography.caption)
                }
                .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                confirmReset = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L.t("profile.reset_title")).font(Theme.Typography.body)
                        Text(L.t("profile.reset_subtitle"))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .opacity(0.7)
                    }
                    Spacer()
                }
                .foregroundStyle(Theme.grenat)
                .padding(15)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 18)
            }
            .buttonStyle(.plain)
            .confirmationDialog(L.t("profile.reset_confirm"), isPresented: $confirmReset,
                                titleVisibility: .visible) {
                Button(L.t("profile.reset_action"), role: .destructive) {
                    progress.reset()
                    appState.isOnboarded = false
                }
                Button(L.t("profile.cancel"), role: .cancel) {}
            }
        }
    }

    private var cacheSize: String {
        let bytes = tts.audioCacheBytes
        return bytes < 1_048_576 ? "< 1 " + Units.megabyte : Units.megabytes(bytes)
    }
}
