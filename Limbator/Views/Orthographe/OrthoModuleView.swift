import SwiftUI

/// Un module d'orthographe : ses règles, sa maîtrise, et l'entrée vers les
/// exercices.
struct OrthoModuleView: View {
    let module: OrthoModule

    @EnvironmentObject var repetition: SpacedRepetition
    @EnvironmentObject var progress: ProgressTracker

    private var rules: [OrthoRule] { OrthoRules.rules(for: module) }
    private var drillCount: Int { OrthoDrills.handwritten(for: module).count }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                summary
                trainButton
                rulesSection
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color.clear)
        .navigationTitle(module.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: module.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(module.color)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(module.color.opacity(0.16)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(module.localizedSubtitle)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Chip(text: L.t("ortho.rules_count", rules.count), tint: module.color)
                        Chip(text: L.t("ortho.drills_count", drillCount), tint: Theme.glassEdge)
                    }
                }
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
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 24)
    }

    private var trainButton: some View {
        NavigationLink {
            OrthoDrillView(module: module)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text(L.t("ortho.train")).font(Theme.Typography.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [module.color, module.color.opacity(0.65)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1))
            .shadow(color: module.color.opacity(0.42), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(drillCount == 0)
        .opacity(drillCount == 0 ? 0.4 : 1)
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L.t("ortho.rules"))
            ForEach(rules) { rule in
                RuleCard(rule: rule, strength: repetition.strength(ruleId: rule.id))
            }
        }
    }
}

/// Une règle, dépliable. Repliée elle tient en une ligne ; dépliée elle donne
/// l'énoncé, les exemples, les exceptions et le moyen mnémotechnique.
struct RuleCard: View {
    let rule: OrthoRule
    var strength: Double = 0

    @EnvironmentObject var tts: TTSService
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(rule.localizedTitle)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            Chip(text: rule.level.rawValue, tint: rule.module.color)
                            if strength > 0 {
                                MasteryBar(value: strength, tint: rule.module.color, height: 5)
                                    .frame(width: 56)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 14) {
                    Text(rule.localizedStatement)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)

                    if !rule.examples.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L.t("ortho.rule_examples"))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.white.opacity(0.55))
                                .textCase(.uppercase)
                                .tracking(1.1)
                            ForEach(rule.examples) { example in
                                ExampleRow(example: example)
                            }
                        }
                    }

                    if !rule.exceptions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L.t("ortho.rule_exceptions"))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.grenat)
                                .textCase(.uppercase)
                                .tracking(1.1)
                            FlowLayout(spacing: 6, lineSpacing: 6) {
                                ForEach(rule.exceptions, id: \.self) { exception in
                                    Text(exception)
                                        .font(Theme.Typography.caption)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Capsule().fill(Theme.grenat.opacity(0.15)))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                            }
                        }
                    }

                    if let mnemonic = rule.localizedMnemonic {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.or)
                            Text(mnemonic)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.orClair)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.or.opacity(0.10)))
                    }

                    NavigationLink {
                        OrthoDrillView(module: rule.module, focusRuleId: rule.id)
                    } label: {
                        HStack(spacing: 6) {
                            Text(L.t("ortho.train")).font(Theme.Typography.caption)
                            Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(rule.module.color)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(rule.module.color.opacity(expanded ? 0.4 : 0.18), lineWidth: 1))
    }
}

/// Un exemple : la forme juste, la forme fautive barrée, et le sens.
struct ExampleRow: View {
    let example: OrthoExample
    @EnvironmentObject var tts: TTSService

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(example.correct)
                        .font(Theme.Typography.orthoSmall)
                        .foregroundStyle(Theme.emeraude)
                    if let wrong = example.wrong {
                        Text(wrong)
                            .font(Theme.Typography.orthoSmall)
                            .strikethrough(true, color: Theme.grenat.opacity(0.8))
                            .foregroundStyle(Theme.grenat.opacity(0.75))
                    }
                }
                Text(ContentL10n.s(example.gloss))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            SpeakerChip(text: example.correct, label: "")
        }
        .padding(.vertical, 4)
    }
}
