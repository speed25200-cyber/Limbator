import SwiftUI

@main
struct LimbatorApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var gemma = GemmaService.shared
    @StateObject private var tts = TTSService.shared
    @StateObject private var progress = ProgressTracker.shared
    @StateObject private var repetition = SpacedRepetition.shared

    init() {
        Theme.applyGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(gemma)
                .environmentObject(tts)
                .environmentObject(progress)
                .environmentObject(repetition)
                .preferredColorScheme(.dark)
                .task {
                    // Le modèle et les voix se chargent EN PARALLÈLE : rien ne
                    // lie l'un à l'autre, et les enchaîner ferait attendre
                    // plusieurs minutes au premier lancement pour rien.
                    async let model: Void = gemma.warmUp()
                    async let voices: Void = tts.preloadVoice()
                    _ = await (model, voices)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var gemma: GemmaService
    @EnvironmentObject var progress: ProgressTracker

    var body: some View {
        ZStack {
            AuroraBackground().ignoresSafeArea()

            Group {
                if appState.isOnboarded {
                    // Entrée IMMÉDIATE dans l'app. Tout le contenu pédagogique
                    // est embarqué : rien ne justifierait de faire patienter
                    // devant un écran de chargement pendant que le modèle se
                    // télécharge en arrière-plan.
                    MainTabView()
                        // `L.t` est une fonction statique : changer de langue
                        // ne prévient personne. Les écrans qui observent le
                        // profil se redessinent, mais pas la barre d'onglets
                        // ni les accueils qui n'en dépendent pas — leurs
                        // libellés restaient dans l'ancienne langue jusqu'au
                        // relancement. Rattacher l'identité de la vue à la
                        // langue reconstruit tout le moment venu ; l'onglet
                        // courant, lui, vit dans `AppState` et survit.
                        .id(progress.profile.nativeLanguageId)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    OnboardingView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.04)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))))
                }
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.85), value: appState.isOnboarded)

            // Bandeau non bloquant : sans lui, un utilisateur dont le modèle se
            // télécharge croit l'app cassée. Il montre l'avancée réelle et,
            // en cas d'échec, la cause exacte plus un bouton pour réessayer.
            if appState.isOnboarded,
               gemma.isWarmingUp || (gemma.loadFailed && gemma.lastError != nil) {
                VStack {
                    GemmaStatusBanner()
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // La célébration d'un badge passe par-dessus tout le reste.
            if let badge = progress.freshBadge {
                BadgeCelebration(badge: badge) { progress.clearFreshBadge() }
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gemma.isWarmingUp)
        .animation(.easeInOut(duration: 0.3), value: gemma.loadFailed)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress.freshBadge)
    }
}
