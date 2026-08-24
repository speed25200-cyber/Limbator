import SwiftUI
import AVFoundation

/// Le studio vocal : écouter le modèle, enregistrer, comparer.
///
/// La note affichée est **présentée comme approximative**, parce qu'elle l'est :
/// une vraie évaluation acoustique demande un encodeur audio embarqué que
/// Limbator n'a pas encore. Afficher un chiffre en le faisant passer pour une
/// mesure serait mentir à l'apprenant sur ce que l'app sait faire.
struct SpeakingGameView: View {
    var roundCount: Int = 8

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var tts: TTSService
    @Environment(\.dismiss) private var dismiss

    @StateObject private var recorder = VoiceRecorder()

    @State private var rounds: [GameRound] = []
    @State private var index = 0
    @State private var lastScore: Double?
    @State private var score = GameScore()
    @State private var finished = false

    private var current: GameRound? {
        rounds.indices.contains(index) ? rounds[index] : nil
    }

    var body: some View {
        Group {
            if finished {
                GameSummaryView(score: score, tint: GameKind.speaking.color,
                                onReplay: restart, onDismiss: { dismiss() })
            } else if let round = current {
                content(round)
            } else {
                ProgressView().tint(GameKind.speaking.color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.clear)
        .navigationTitle(GameKind.speaking.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .onDisappear {
            recorder.stop()
            tts.cancel()
        }
    }

    private func load() {
        guard rounds.isEmpty else { return }
        let seed = UInt64(abs(Int(Date().timeIntervalSince1970) / 300))
        rounds = ContentGenerator.shared.gameRounds(
            kind: .speaking, level: progress.profile.level, count: roundCount, seed: seed)
    }

    private func content(_ round: GameRound) -> some View {
        VStack(spacing: 22) {
            GameProgressHeader(index: index, total: rounds.count, score: score,
                               tint: GameKind.speaking.color)
                .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 12) {
                Text(round.frenchTarget)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, 24)
                if let phonetic = round.explanation {
                    Text(phonetic)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Text(round.prompt)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white.opacity(0.7))
            }

            HStack(spacing: 14) {
                SpeakerButton(text: round.frenchTarget, size: 56, tint: Theme.azur)
                SpeakerButton(text: round.frenchTarget, size: 48, tint: Theme.or, delivery: .spelled)
                SpeakerButton(text: round.frenchTarget, size: 48, tint: Theme.lavande, delivery: .slow)
            }

            Spacer()

            if let value = lastScore {
                scoreCard(value)
            }

            recordButton(round)

            if !recorder.isAuthorized {
                Text(L.t("game.mic_denied"))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.grenat)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            if lastScore != nil {
                PrimaryButton(title: index == rounds.count - 1 ? L.t("game.finish") : L.t("ortho.next"),
                              icon: "arrow.right",
                              gradient: LinearGradient(colors: [GameKind.speaking.color,
                                                                GameKind.speaking.color.opacity(0.7)],
                                                       startPoint: .leading, endPoint: .trailing),
                              glowColor: GameKind.speaking.color) { advance() }
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 20)
        }
    }

    private func scoreCard(_ value: Double) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { star in
                    Image(systemName: Double(star) < value * 5 ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.or)
                }
            }
            // La réserve est écrite, pas sous-entendue.
            Text(approximateNotice)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)
        }
    }

    private var approximateNotice: String {
        switch L.lang {
        case "fr": return "Estimation approximative, fondée sur le rythme — pas encore sur les sons."
        case "en": return "Rough estimate, based on rhythm — not yet on the sounds themselves."
        default:   return "Estimare aproximativă, bazată pe ritm — încă nu pe sunete."
        }
    }

    private func recordButton(_ round: GameRound) -> some View {
        Button {
            Task { await toggleRecording(round) }
        } label: {
            ZStack {
                Circle()
                    .fill(recorder.isRecording
                          ? AnyShapeStyle(Theme.grenat)
                          : AnyShapeStyle(Theme.primaryGradient))
                    .frame(width: 88, height: 88)
                    .glow(recorder.isRecording ? Theme.grenat : Theme.bleuFrance, radius: 22)
                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                if recorder.isRecording {
                    Circle()
                        .stroke(Theme.grenat.opacity(0.5), lineWidth: 3)
                        .frame(width: 118, height: 118)
                        .scaleEffect(1 + CGFloat(recorder.level) * 0.35)
                        .animation(.easeOut(duration: 0.15), value: recorder.level)
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Text(recorder.isRecording ? L.t("game.listening") : L.t("game.hold_record"))
                .font(Theme.Typography.caption)
                .foregroundStyle(.white.opacity(0.55))
                .offset(y: 30)
        }
    }

    private func toggleRecording(_ round: GameRound) async {
        if recorder.isRecording {
            guard let url = recorder.stop() else { return }
            let value = await tts.approximateSpeechScore(french: round.frenchTarget, recordingURL: url)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { lastScore = value }
            score.register(correct: value >= 0.6, xp: 12)
            UINotificationFeedbackGenerator().notificationOccurred(value >= 0.6 ? .success : .warning)
        } else {
            lastScore = nil
            await recorder.start()
            appState.micGranted = recorder.isAuthorized
        }
    }

    private func advance() {
        if index == rounds.count - 1 {
            progress.awardXP(score.xpEarned)
            progress.bumpStreak()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { finished = true }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                index += 1
                lastScore = nil
            }
        }
    }

    private func restart() {
        withAnimation {
            rounds = []
            index = 0
            lastScore = nil
            score = GameScore()
            finished = false
        }
        load()
    }
}

// =============================================================================
// MARK: - Enregistreur
// =============================================================================

/// Enregistrement audio minimal. Conçu pour ne jamais faire tomber l'app :
/// chaque échec — permission refusée, session audio indisponible, écriture
/// impossible — se solde par un état inactif, pas par une exception.
@MainActor
final class VoiceRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isAuthorized = true
    /// Niveau sonore lissé, entre 0 et 1 — sert à animer le bouton.
    @Published private(set) var level: Float = 0

    private var recorder: AVAudioRecorder?
    private var meterTask: Task<Void, Never>?

    func start() async {
        let granted = await requestPermission()
        isAuthorized = granted
        guard granted else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .measurement,
                                 options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true, options: [])

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("limb_speech_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        guard let recorder = try? AVAudioRecorder(url: url, settings: settings) else { return }
        recorder.isMeteringEnabled = true
        guard recorder.record() else { return }
        self.recorder = recorder
        isRecording = true
        startMetering()
    }

    @discardableResult
    func stop() -> URL? {
        meterTask?.cancel()
        meterTask = nil
        level = 0
        guard let recorder, isRecording else {
            isRecording = false
            return nil
        }
        let url = recorder.url
        recorder.stop()
        self.recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        return url
    }

    private func startMetering() {
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 80_000_000)
                guard let self, let recorder = self.recorder else { return }
                recorder.updateMeters()
                // Les décibels vont de -160 à 0 : on ramène la plage utile
                // (-45 à 0) sur 0…1, sinon l'animation ne bouge jamais.
                let decibels = recorder.averagePower(forChannel: 0)
                let normalized = max(0, min(1, (decibels + 45) / 45))
                self.level = normalized
            }
        }
    }

    /// La cible de déploiement est iOS 17 : `AVAudioApplication` est toujours
    /// disponible, inutile de traîner l'API dépréciée en second recours.
    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
