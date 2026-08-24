import SwiftUI

/// Le choix d'une dictée : par niveau, et par règle travaillée.
///
/// Les dictées d'un niveau supérieur restent visibles et accessibles. Un
/// apprenant curieux a le droit d'essayer trop difficile — c'est même souvent
/// ainsi qu'il découvre ce qui lui manque.
struct DictationPickerView: View {
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var repetition: SpacedRepetition

    /// Le niveau du profil n'est proposé qu'à la première apparition.
    @State private var didApplyDefaultLevel = false

    @State private var selectedLevel: ProficiencyLevel?

    private var levels: [ProficiencyLevel] {
        ProficiencyLevel.allCases.filter { !DictationBank.dictations(for: $0).isEmpty }
    }

    private var visible: [DictationItem] {
        guard let selectedLevel else { return DictationBank.all }
        return DictationBank.dictations(for: selectedLevel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                levelFilter

                ForEach(visible) { item in
                    NavigationLink {
                        DictationView(item: item)
                    } label: {
                        DictationRow(item: item, repetition: repetition)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Color.clear)
        .navigationTitle(L.t("ortho.dictation"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Une seule fois. `nil` veut aussi dire « tous les niveaux » : sans
            // ce drapeau, revenir d'une dictée effaçait ce choix et replaçait
            // le filtre sur le niveau du profil.
            guard !didApplyDefaultLevel else { return }
            didApplyDefaultLevel = true
            selectedLevel = progress.profile.level
        }
    }

    private var levelFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: L.t("lessons.filter_all"), level: nil)
                ForEach(levels) { level in
                    filterChip(title: level.rawValue, level: level)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(title: String, level: ProficiencyLevel?) -> some View {
        let isSelected = selectedLevel == level
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedLevel = level }
        } label: {
            Text(title)
                .font(Theme.Typography.caption)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(isSelected
                    ? AnyShapeStyle(Theme.primaryGradient)
                    : AnyShapeStyle(Theme.glass)))
                .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.glassEdge, lineWidth: 1))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

/// Une dictée dans la liste.
///
/// Le texte français n'apparaît **jamais** ici : ce serait donner la réponse
/// avant l'exercice. On montre le niveau, les règles travaillées, la longueur —
/// tout ce qui aide à choisir, rien de ce qui aide à tricher.
struct DictationRow: View {
    let item: DictationItem
    let repetition: SpacedRepetition

    private var rules: [OrthoRule] {
        item.targetRules.compactMap { OrthoRules.rule(id: $0) }
    }

    /// Une dictée est « à revoir » si l'une de ses règles est due aujourd'hui.
    private var isDue: Bool {
        item.targetRules.contains { ruleId in
            repetition.mastery(key: SpacedRepetition.ruleKey(ruleId))?.isDue() ?? false
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.18))
                    .frame(width: 50, height: 50)
                Text(item.level.rawValue)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.localizedTranslation)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if !rules.isEmpty {
                    FlowLayout(spacing: 6, lineSpacing: 6) {
                        ForEach(rules.prefix(3)) { rule in
                            Chip(text: rule.module.localizedTitle, tint: rule.module.color)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                if isDue {
                    Circle().fill(Theme.or).frame(width: 8, height: 8)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 20)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(isDue ? Theme.or.opacity(0.5) : Theme.glassEdge, lineWidth: 1))
    }

    private var accent: Color {
        rules.first?.module.color ?? Theme.bleuFrance
    }
}
