import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label(L.t("tab.home"), systemImage: LimbIcon.home.systemName) }
                .tag(AppState.MainTab.home)

            LessonHubView()
                .tabItem { Label(L.t("tab.lessons"), systemImage: LimbIcon.lessons.systemName) }
                .tag(AppState.MainTab.lessons)

            // L'orthographe occupe le centre de la barre. Ce n'est pas une
            // section parmi d'autres : c'est ce que l'application fait.
            OrthoHubView()
                .tabItem { Label(L.t("tab.ortho"), systemImage: LimbIcon.ortho.systemName) }
                .tag(AppState.MainTab.orthographe)

            GamesHubView()
                .tabItem { Label(L.t("tab.games"), systemImage: LimbIcon.games.systemName) }
                .tag(AppState.MainTab.games)

            ProfileView()
                .tabItem { Label(L.t("tab.profile"), systemImage: LimbIcon.profile.systemName) }
                .tag(AppState.MainTab.profile)
        }
        .tint(Theme.or)
        .sheet(isPresented: $appState.presentedTutor) {
            TutorChatView()
        }
    }
}

/// Célébration d'un badge : rare, brève, et jamais bloquante.
struct BadgeCelebration: View {
    let badge: Badge
    let dismiss: () -> Void

    @State private var confetti = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Theme.goldGradient)
                        .frame(width: 108, height: 108)
                        .blur(radius: 26)
                        .opacity(0.7)
                    Image(systemName: badge.iconName)
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(Theme.goldGradient)
                }

                VStack(spacing: 8) {
                    Text(L.t("component.new_badge"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.or)
                        .textCase(.uppercase)
                        .tracking(1.6)
                    Text(badge.title)
                        .font(Theme.Typography.title)
                        .foregroundStyle(.white)
                    Text(badge.localizedDetail)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(title: L.t("component.continue"),
                              gradient: Theme.goldGradient,
                              glowColor: Theme.or) { dismiss() }
                    .frame(maxWidth: 240)
            }
            .padding(30)
            .frame(maxWidth: 340)
            .glassCard(cornerRadius: 30)
            .goldRim(cornerRadius: 30, lineWidth: 1.4)

            ConfettiView(trigger: confetti).ignoresSafeArea()
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            confetti += 1
        }
    }
}
