import SwiftUI

struct GamesHubView: View {
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(GameKind.allCases) { kind in
                            NavigationLink(value: kind) { GameTile(kind: kind) }
                                .buttonStyle(.plain)
                        }
                    }
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: GameKind.self) { kind in
                destination(for: kind)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.t("games.title"))
                .font(Theme.Typography.display)
                .foregroundStyle(.white)
            Text(L.t("games.subtitle"))
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func destination(for kind: GameKind) -> some View {
        switch kind {
        case .dictation:      DictationPickerView()
        case .speaking:       SpeakingGameView()
        case .flashRecall:    FlashRecallGameView()
        case .wordPuzzle:     WordPuzzleGameView()
        case .wheelOfFortune: WheelGameView()
        case .storyChoice:    StoryHubView()
        default:              QuizGameView(kind: kind)
        }
    }
}

struct GameTile: View {
    let kind: GameKind
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                LimbIconView(icon: kind.icon, size: 30,
                             gradient: LinearGradient(colors: [.white, Color.white.opacity(0.85)],
                                                      startPoint: .top, endPoint: .bottom),
                             glow: .white)
                    .padding(10)
                    .background(Circle().fill(.white.opacity(0.18)))
                Spacer()
                if kind.isOrthographic {
                    // Les trois jeux d'orthographe portent un liseré doré : ce
                    // sont eux qui font progresser, pas seulement réviser.
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(6)
                        .background(Circle().fill(.white.opacity(0.18)))
                }
            }
            Spacer(minLength: 0)
            Text(kind.localizedTitle)
                .font(Theme.Typography.headline)
                .foregroundStyle(.white)
                .lineLimit(2).minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
            Text(kind.localizedSubtitle)
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 168)
        .background(LinearGradient(colors: [kind.color, kind.color.opacity(0.45)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(kind.isOrthographic ? AnyShapeStyle(Theme.goldGradient)
                                        : AnyShapeStyle(Color.white.opacity(0.2)),
                    lineWidth: kind.isOrthographic ? 1.4 : 1))
        .shadow(color: kind.color.opacity(0.42), radius: 14, x: 0, y: 8)
        .scaleEffect(pulse ? 1.015 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse.toggle()
            }
        }
    }
}
