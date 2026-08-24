import SwiftUI

/// Affiche une correction.
///
/// C'est l'écran qui justifie l'application. Une note seule n'apprend rien ;
/// une phrase barrée en rouge non plus. Ce que l'apprenant doit voir, c'est
/// **exactement** quelles lettres ont manqué, lesquelles étaient en trop, et
/// pourquoi — mot par mot, lettre par lettre.
///
/// Le code couleur est constant dans toute l'app :
///   blanc — juste · rouge — faux · or barré — oublié · violet — en trop
struct OrthoDiffView: View {
    let verdict: OrthoVerdict
    var font: Font = Theme.Typography.ortho

    var body: some View {
        // `WrappingHStack` maison : les segments doivent aller à la ligne comme
        // du texte, or un HStack ne le fait pas et un Text concaténé ne permet
        // pas le soulignement par segment.
        FlowLayout(spacing: 0, lineSpacing: 8) {
            ForEach(verdict.segments) { segment in
                segmentView(segment)
            }
        }
    }

    @ViewBuilder
    private func segmentView(_ segment: OrthoVerdict.DiffSegment) -> some View {
        switch segment.state {
        case .correct:
            Text(segment.text)
                .font(font)
                .foregroundStyle(.white)
        case .wrong:
            Text(segment.text)
                .font(font)
                .foregroundStyle(Theme.grenat)
                .padding(.horizontal, 1)
                .background(Theme.grenat.opacity(0.18).clipShape(RoundedRectangle(cornerRadius: 4)))
        case .missing:
            Text(segment.text)
                .font(font)
                .foregroundStyle(Theme.or)
                .background(alignment: .center) {
                    // Un soulignement plutôt qu'un barré : la lettre manquante
                    // doit rester parfaitement lisible, c'est elle qu'il faut
                    // retenir.
                    VStack { Spacer(); Rectangle().fill(Theme.or).frame(height: 2) }
                }
        case .extra:
            Text(segment.text)
                .font(font)
                .foregroundStyle(Theme.lavande)
                .strikethrough(true, color: Theme.lavande)
        }
    }
}

/// La légende du code couleur. Affichée une fois par correction : sans elle,
/// le rouge et l'or se confondent.
struct OrthoDiffLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            item(color: .white, label: L.t("ortho.correct"))
            item(color: Theme.grenat, label: L.t("ortho.incorrect"))
            item(color: Theme.or, label: L.t("ortho.expected"))
        }
        .font(.system(size: 10, weight: .semibold, design: .rounded))
        .foregroundStyle(.white.opacity(0.55))
    }

    private func item(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
        }
    }
}

// =============================================================================
// MARK: - Carte de faute
// =============================================================================

/// Une faute, expliquée. La catégorie donne le nom du phénomène, l'explication
/// donne le raisonnement, et le bouton renvoie vers la règle complète.
struct MistakeCard: View {
    let mistake: OrthoMistake
    var onReviewRule: ((String) -> Void)? = nil

    @EnvironmentObject var tts: TTSService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Chip(text: mistake.kind.localizedLabel,
                     systemImage: iconName,
                     tint: mistake.kind.color)
                Spacer()
                if !mistake.expected.isEmpty {
                    Button {
                        Task { await tts.speak(mistake.expected, delivery: .spelled) }
                    } label: {
                        Image(systemName: "textformat.abc")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.or)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Theme.or.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.t("component.spell"))
                }
            }

            if !mistake.written.isEmpty || !mistake.expected.isEmpty {
                HStack(spacing: 10) {
                    if !mistake.written.isEmpty {
                        wordPill(mistake.written, color: Theme.grenat, strike: true)
                    }
                    if !mistake.written.isEmpty && !mistake.expected.isEmpty {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    if !mistake.expected.isEmpty {
                        wordPill(mistake.expected, color: Theme.emeraude, strike: false)
                    }
                }
            }

            Text(mistake.explanation)
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)

            if let ruleId = mistake.ruleId, let onReviewRule {
                Button {
                    onReviewRule(ruleId)
                } label: {
                    HStack(spacing: 6) {
                        Text(L.t("ortho.review_rule")).font(Theme.Typography.caption)
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Theme.bleuFrance)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(mistake.kind.color.opacity(0.35), lineWidth: 1))
    }

    private var iconName: String {
        switch mistake.kind {
        case .accentMissing, .accentWrong, .accentExtra: return "character.textbox"
        case .cedillaMissing, .cedillaExtra:             return "c.circle"
        case .tremaMissing:                              return "ellipsis"
        case .doubleConsonant:                           return "square.on.square"
        case .silentLetter:                              return "speaker.slash.fill"
        case .homophone:                                 return "arrow.triangle.branch"
        case .verbEnding:                                return "text.append"
        case .agreement:                                 return "link"
        case .romanianInterference:                      return "exclamationmark.triangle.fill"
        case .missingWord:                               return "text.badge.plus"
        case .extraWord:                                 return "text.badge.minus"
        default:                                         return "pencil"
        }
    }

    private func wordPill(_ text: String, color: Color, strike: Bool) -> some View {
        Text(text)
            .font(Theme.Typography.orthoSmall)
            .strikethrough(strike, color: color.opacity(0.7))
            .foregroundStyle(color)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.14)))
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

// =============================================================================
// MARK: - Note sur 20
// =============================================================================

/// La note d'une dictée, présentée comme un professeur français la donnerait :
/// sur vingt, en gros, avec le nombre de fautes en dessous.
struct ScoreBadge: View {
    let verdict: OrthoVerdict
    var size: CGFloat = 132

    private var tint: Color {
        switch verdict.outOfTwenty {
        case 18...:  return Theme.or
        case 14..<18: return Theme.emeraude
        case 10..<14: return Theme.azur
        default:      return Theme.grenat
        }
    }

    var body: some View {
        ZStack {
            ProgressRing(progress: verdict.score, lineWidth: 10,
                         gradient: AngularGradient(colors: [tint, tint.opacity(0.5), tint],
                                                   center: .center))
                .frame(width: size, height: size)
            VStack(spacing: 2) {
                Text(formatted)
                    .font(.system(size: size * 0.30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("/ 20")
                    .font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .glow(tint, radius: 20)
    }

    /// « 20 » plutôt que « 20,0 » : une note ronde s'écrit sans décimale.
    private var formatted: String {
        let value = verdict.outOfTwenty
        return value == value.rounded()
            ? String(Int(value))
            : String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }
}

// =============================================================================
// MARK: - Disposition en flot
// =============================================================================

/// Dispose ses enfants comme du texte : de gauche à droite, puis à la ligne.
///
/// SwiftUI n'offre rien de tel avant iOS 16, et `Text` concaténé ne permet ni
/// le soulignement par segment ni les fonds arrondis. Cette disposition est
/// donc écrite à la main — c'est elle qui rend la correction lisible.
struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                widest = max(widest, x - spacing)
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        widest = max(widest, x - spacing)
        return CGSize(width: min(widest, maxWidth), height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                          proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
