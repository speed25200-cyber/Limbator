import SwiftUI

struct LessonHubView: View {
    @EnvironmentObject var progress: ProgressTracker

    @State private var levelFilter: ProficiencyLevel?

    private var topics: [LessonTopic] {
        guard let levelFilter else { return LessonTopic.curriculum }
        return LessonTopic.curriculum.filter { $0.difficulty == levelFilter }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    filters
                    ForEach(topics) { topic in
                        NavigationLink {
                            LessonDetailView(topic: topic)
                        } label: {
                            TopicRow(topic: topic,
                                     isDone: progress.profile.completedLessons.contains(topic.slug))
                        }
                        .buttonStyle(.plain)
                    }
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
            Text(L.t("lessons.title"))
                .font(Theme.Typography.display)
                .foregroundStyle(.white)
            Text(L.t("lessons.subtitle"))
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(L.t("lessons.filter_all"), value: nil)
                ForEach(ProficiencyLevel.allCases) { level in
                    if LessonTopic.curriculum.contains(where: { $0.difficulty == level }) {
                        filterChip(level.rawValue, value: level)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(_ title: String, value: ProficiencyLevel?) -> some View {
        let isSelected = levelFilter == value
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { levelFilter = value }
        } label: {
            Text(title)
                .font(Theme.Typography.caption)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(isSelected
                    ? AnyShapeStyle(Theme.primaryGradient)
                    : AnyShapeStyle(Theme.glass)))
                .overlay(Capsule().stroke(isSelected ? .clear : Theme.glassEdge, lineWidth: 1))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

/// Une leçon dans la liste. Le module d'orthographe travaillé est affiché au
/// même rang que le thème : c'est le fil rouge du parcours, pas un détail.
struct TopicRow: View {
    let topic: LessonTopic
    var isDone: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [topic.accent, topic.accent.opacity(0.55)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 54, height: 54)
                Image(systemName: topic.icon.systemName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: topic.accent.opacity(0.4), radius: 10, x: 0, y: 5)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(topic.localizedTitle)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    if isDone {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.emeraude)
                    }
                }
                Text(topic.frenchTitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Chip(text: topic.difficulty.rawValue, tint: topic.accent)
                    Chip(text: topic.orthoFocus.localizedTitle,
                         systemImage: topic.orthoFocus.iconName,
                         tint: topic.orthoFocus.color)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.32))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 20)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(isDone ? Theme.emeraude.opacity(0.4) : Theme.glassEdge, lineWidth: 1))
    }
}
