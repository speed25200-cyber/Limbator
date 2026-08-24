import SwiftUI

struct StoryHubView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                ForEach(Story.builtIn) { story in
                    NavigationLink {
                        StoryReaderView(story: story)
                    } label: {
                        StoryRow(story: story)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color.clear)
        .navigationTitle(L.t("stories.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Text(L.t("stories.subtitle"))
            .font(Theme.Typography.body)
            .foregroundStyle(.white.opacity(0.7))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// La couverture d'une histoire — illustration vectorielle, titre français,
/// titre traduit.
struct StoryCoverCard: View {
    let story: Story
    var width: CGFloat = 200
    var height: CGFloat = 148

    private var illustration: LimbIllustration {
        LimbIllustration(rawValue: story.illustrationKey) ?? .seine
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LimbIllustrationView(illustration: illustration,
                                 primary: story.orthoFocus.color,
                                 secondary: Theme.bleuFrance)
                .frame(width: width, height: height)

            LinearGradient(colors: [.clear, Theme.encre.opacity(0.92)],
                           startPoint: .center, endPoint: .bottom)
                .frame(width: width, height: height)

            VStack(alignment: .leading, spacing: 3) {
                Text(story.localizedTitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(story.frenchTitle)
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: width, alignment: .leading)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Theme.glassEdge, lineWidth: 1))
        .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)
    }
}

struct StoryRow: View {
    let story: Story

    var body: some View {
        HStack(spacing: 14) {
            StoryCoverCard(story: story, width: 108, height: 108)

            VStack(alignment: .leading, spacing: 7) {
                Text(story.localizedTitle)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(story.localizedSynopsis)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Chip(text: story.difficulty.rawValue, tint: story.orthoFocus.color)
                    Chip(text: L.t("stories.chapters", story.chapters.count),
                         systemImage: "book", tint: Theme.glassEdge)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 22)
    }
}
