import SwiftUI

/// La graine d'une série de jeu.
///
/// Deux exigences se contredisent. Une série **en cours** ne doit jamais se
/// réordonner sous les doigts : la graine ne peut donc pas dépendre de
/// l'instant présent, sinon le moindre redessin de SwiftUI rebattrait les
/// cartes. Mais « rejouer » doit donner autre chose : elle ne peut pas non plus
/// être constante — la première version dérivait la graine d'un seau de cinq
/// minutes, si bien qu'une seconde partie redonnait mot pour mot la même série.
///
/// Le quart d'heure courant, mêlé au numéro de tentative, satisfait les deux :
/// stable pendant une partie, différent dès qu'on en redemande une.
enum GameSeed {
    static func value(attempt: Int, now: Date = Date()) -> UInt64 {
        let quarterHour = UInt64(abs(Int(now.timeIntervalSince1970) / 900))
        return quarterHour &* 31 &+ UInt64(max(0, attempt))
    }
}

/// L'écran d'un jeu dont le tirage n'a rien donné.
///
/// Sans lui, un tirage vide laissait la vue sur son indicateur de chargement,
/// indéfiniment et sans un mot : `onAppear` ne repasse pas, donc rien ne
/// relançait le tirage et rien n'expliquait l'attente. Le cas ne devrait pas
/// se produire — les tests vérifient que chaque jeu reçoit des manches à tous
/// les niveaux — mais s'il se produit, il doit se voir et se réparer.
struct GameUnavailableView: View {
    var tint: Color = Theme.bleuFrance
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "questionmark.square.dashed")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(tint.opacity(0.8))
            Text(L.t("game.unavailable"))
                .font(Theme.Typography.body)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
            GhostButton(title: L.t("game.retry"), action: onRetry)
            GhostButton(title: L.t("game.finish"), action: onDismiss)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
