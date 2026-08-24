import SwiftUI

/// L'écran d'orthographe : huit modules, leur maîtrise, et la dictée.
///
/// La maîtrise affichée n'est pas un pourcentage d'exercices faits mais la
/// **force de mémoire** calculée par la répétition espacée. C'est une nuance
/// décisive : on peut avoir tout réussi hier et n'avoir rien retenu.
struct OrthoHubView: View {
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var repetition: SpacedRepetition

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    dictationCard
                    modulesGrid
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.t("ortho.title"))
                .font(Theme.Typography.display)
                .foregroundStyle(.white)
            Text(L.t("ortho.subtitle"))
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // =========================================================================
    // MARK: - Dictée
    // =========================================================================

    private var dictationCard: some View {
        NavigationLink {
            DictationPickerView()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.primaryGradient)
                        .frame(width: 58, height: 58)
                    Image(systemName: "pencil.and.scribble")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                }
                .glow(Theme.bleuFrance, radius: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L.t("ortho.dictation"))
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                    Text(L.t("ortho.dictation_sub"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.66))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                if progress.profile.dictationsDone > 0 {
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", progress.profile.dictationAverage))
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.or)
                            .monospacedDigit()
                        Text("/ 20")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 24)
            .goldRim(cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }

    // =========================================================================
    // MARK: - Modules
    // =========================================================================

    private var modulesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("ortho.modules"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(OrthoModule.allCases) { module in
                    NavigationLink {
                        OrthoModuleView(module: module)
                    } label: {
                        ModuleTile(module: module,
                                   mastery: repetition.mastery(of: module),
                                   isLocked: module.entryLevel > progress.profile.level)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// La tuile d'un module. Le verrouillage est **indicatif, jamais bloquant** :
/// un module au-dessus du niveau déclaré s'ouvre quand même. Personne ne
/// devrait être empêché d'apprendre par un réglage fait au premier lancement.
struct ModuleTile: View {
    let module: OrthoModule
    let mastery: Double
    var isLocked: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: module.iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(module.color)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(module.color.opacity(0.16)))
                Spacer()
                if mastery >= 0.8 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.goldGradient)
                } else if isLocked {
                    Chip(text: module.entryLevel.rawValue, tint: Theme.glassEdge)
                }
            }

            Text(module.localizedTitle)
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(module.localizedSubtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 5) {
                MasteryBar(value: mastery, tint: module.color)
                Text(masteryLabel)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 186)
        .padding(15)
        .glassCard(cornerRadius: 22)
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(module.color.opacity(mastery >= 0.8 ? 0.55 : 0.28), lineWidth: 1))
    }

    private var masteryLabel: String {
        if mastery <= 0 { return L.t("ortho.not_started") }
        if mastery >= 0.8 { return L.t("ortho.mastered") }
        return "\(Int(mastery * 100)) % · \(L.t("ortho.mastery"))"
    }
}
