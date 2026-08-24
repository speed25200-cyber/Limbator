import SwiftUI

/// Bandeau d'état du modèle, affiché en haut de l'app pendant le téléchargement
/// ou en cas d'échec.
///
/// Il existe pour une raison précise : plusieurs gigaoctets arrivent en
/// arrière-plan au premier lancement, et sans indication visible l'utilisateur
/// conclut que l'application est cassée. Le bandeau montre l'avancée réelle —
/// pourcentage, mégaoctets, débit — et, en cas d'échec, la cause exacte plus un
/// bouton pour réessayer.
struct GemmaStatusBanner: View {
    @EnvironmentObject var gemma: GemmaService
    @ObservedObject private var downloader = MLXModelDownloader.shared

    var body: some View {
        HStack(spacing: 12) {
            if gemma.loadFailed, let error = gemma.lastError {
                failureContent(error)
            } else {
                progressContent
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 18)
    }

    private func failureContent(_ error: String) -> some View {
        Group {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.grenat)

            VStack(alignment: .leading, spacing: 2) {
                Text(L.t("gemma.failed_title"))
                    .font(Theme.Typography.caption.bold())
                    .foregroundStyle(.white)
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                Task { await gemma.retryLoad() }
            } label: {
                Text(L.t("gemma.retry"))
                    .font(Theme.Typography.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Capsule().fill(Theme.bleuFrance))
            }
            .buttonStyle(.plain)
        }
    }

    private var progressContent: some View {
        Group {
            ProgressView(value: max(0.02, gemma.bootProgress))
                .progressViewStyle(.circular)
                .tint(Theme.bleuFrance)

            VStack(alignment: .leading, spacing: 2) {
                Text(gemma.statusMessage)
                    .font(Theme.Typography.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(downloader.bytesTotal > 0 ? transferDetail : L.t("gemma.first_launch"))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text("\(Int(gemma.bootProgress * 100)) %")
                .font(Theme.Typography.caption.bold())
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }

    private var transferDetail: String {
        let done = String(format: "%.0f", Double(downloader.bytesDownloaded) / 1_048_576)
        let total = Units.megabytes(downloader.bytesTotal)
        let speed = downloader.currentSpeedBytesPerSec > 0
            ? " · " + Units.megabytesPerSecond(downloader.currentSpeedBytesPerSec)
            : ""
        return "\(done) / \(total)\(speed)"
    }
}
