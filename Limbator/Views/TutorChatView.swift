import SwiftUI

/// Le tuteur : une conversation avec Gemma, en flux continu.
///
/// Deux règles de conception. D'abord la langue : le tuteur répond dans la
/// langue de l'apprenant, jamais en français — sauf le mot enseigné, mis en
/// évidence. Ensuite l'honnêteté : quand le modèle n'est pas disponible, on le
/// dit et on explique pourquoi, au lieu de laisser tourner un indicateur.
struct TutorChatView: View {
    @EnvironmentObject var gemma: GemmaService
    @EnvironmentObject var progress: ProgressTracker
    @EnvironmentObject var tts: TTSService
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [Message] = []
    @State private var draft = ""
    @State private var streaming = false
    @State private var task: Task<Void, Never>?
    @FocusState private var inputFocused: Bool

    struct Message: Identifiable, Equatable {
        let id = UUID()
        var text: String
        let isUser: Bool
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground().ignoresSafeArea()

                VStack(spacing: 0) {
                    statusStrip
                    conversation
                    composer
                }
            }
            .navigationTitle(L.t("tutor.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .onAppear(perform: greet)
            .onDisappear {
                task?.cancel()
                gemma.cancel()
            }
        }
    }

    // =========================================================================
    // MARK: - Bandeau d'état
    // =========================================================================

    private var statusStrip: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(gemma.isReady && !gemma.loadFailed ? Theme.emeraude : Theme.or)
                .frame(width: 7, height: 7)
            Text(L.t("tutor.badge"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            if streaming {
                Button {
                    task?.cancel()
                    gemma.cancel()
                    streaming = false
                } label: {
                    Text(L.t("tutor.stop"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.grenat)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // =========================================================================
    // MARK: - Conversation
    // =========================================================================

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        bubble(message).id(message.id)
                    }
                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.last?.text) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    private func bubble(_ message: Message) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // Le français enseigné arrive entre astérisques : on le rend en
                // relief plutôt que d'afficher les astérisques brutes.
                TutorText(raw: message.text, isUser: message.isUser)

                if !message.isUser, let taught = firstTaughtTerm(message.text) {
                    HStack(spacing: 8) {
                        SpeakerChip(text: taught, label: L.t("component.listen"))
                        SpeakerChip(text: taught, label: L.t("component.spell"), delivery: .spelled)
                    }
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(message.isUser
                      ? AnyShapeStyle(Theme.primaryGradient)
                      : AnyShapeStyle(Theme.glass)))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(message.isUser ? .clear : Theme.glassEdge, lineWidth: 1))

            if !message.isUser { Spacer(minLength: 40) }
        }
    }

    /// Le premier terme français enseigné dans la réponse — celui qu'on propose
    /// d'écouter et d'épeler.
    private func firstTaughtTerm(_ text: String) -> String? {
        guard let start = text.firstIndex(of: "*") else { return nil }
        let after = text.index(after: start)
        guard after < text.endIndex, let end = text[after...].firstIndex(of: "*") else { return nil }
        let term = String(text[after..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        return term.isEmpty ? nil : term
    }

    // =========================================================================
    // MARK: - Saisie
    // =========================================================================

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("", text: $draft, axis: .vertical)
                .focused($inputFocused)
                .lineLimit(1...4)
                .font(Theme.Typography.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.glass))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.glassEdge, lineWidth: 1))
                .overlay(alignment: .leading) {
                    if draft.isEmpty {
                        Text(L.t("tutor.placeholder"))
                            .font(Theme.Typography.body)
                            .foregroundStyle(.white.opacity(0.32))
                            .padding(.leading, 15)
                            .allowsHitTesting(false)
                    }
                }

            Button {
                send()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(canSend
                        ? AnyShapeStyle(Theme.primaryGradient)
                        : AnyShapeStyle(Theme.glass)))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !streaming
    }

    // =========================================================================
    // MARK: - Échange
    // =========================================================================

    private func greet() {
        guard messages.isEmpty else { return }
        let language = progress.profile.nativeLanguage.displayName
        messages.append(Message(text: L.t("tutor.greeting", language), isUser: false))
    }

    private func send() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        draft = ""
        inputFocused = false
        messages.append(Message(text: question, isUser: true))

        // Si le modèle n'est pas prêt, on le dit tout de suite et précisément,
        // plutôt que d'ouvrir un flux qui n'aboutira pas.
        guard gemma.isReady, !gemma.loadFailed else {
            messages.append(Message(text: unavailableMessage, isUser: false))
            return
        }

        let placeholder = Message(text: "", isUser: false)
        messages.append(placeholder)
        // La réponse se met à jour par identifiant, jamais « la dernière du
        // fil » : rien ne garantit que la bulle en cours d'écriture soit encore
        // la dernière quand la réponse arrive.
        let replyId = placeholder.id
        streaming = true

        let native = progress.profile.nativeLanguage
        let level = progress.profile.level

        task = Task {
            var accumulated = ""
            do {
                let stream = ContentGenerator.shared.tutorReply(
                    question: question, native: native, level: level)
                for try await chunk in stream {
                    accumulated += chunk
                    await MainActor.run { update(replyId, to: accumulated) }
                }
            } catch {
                // Un arrêt demandé par l'utilisateur n'est pas une panne. La
                // première version affichait « indisponible : cancelled » en
                // réponse à un appui sur « Stop ».
                if !Task.isCancelled {
                    await MainActor.run {
                        update(replyId, to: accumulated.isEmpty
                               ? L.t("tutor.unavailable", error.localizedDescription)
                               : accumulated)
                    }
                }
            }
            let cancelled = Task.isCancelled
            await MainActor.run {
                if accumulated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Rien n'est venu : soit le modèle chauffe encore, soit
                    // l'utilisateur a coupé avant le premier mot — auquel cas
                    // la bulle vide n'a rien à dire et disparaît.
                    if cancelled {
                        messages.removeAll { $0.id == replyId }
                    } else {
                        update(replyId, to: L.t("tutor.warming"))
                    }
                }
                streaming = false
            }
        }
    }

    private func update(_ id: UUID, to text: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text = text
    }

    private var unavailableMessage: String {
        if gemma.isWarmingUp {
            return L.t("tutor.downloading", Int(gemma.bootProgress * 100))
        }
        if let error = gemma.lastError {
            return L.t("tutor.unavailable", error)
        }
        return L.t("tutor.warming")
    }
}

/// Rend le texte du tuteur : le français enseigné, écrit entre astérisques par
/// le modèle, s'affiche en or et en serif — la graphie exacte doit sauter aux
/// yeux, puisque c'est elle qu'on apprend.
struct TutorText: View {
    let raw: String
    var isUser: Bool = false

    var body: some View {
        Text(attributed)
            .font(Theme.Typography.body)
            .foregroundStyle(isUser ? .white : .white.opacity(0.92))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var attributed: AttributedString {
        var output = AttributedString()
        var isFrench = false
        // Le découpage sur « * » alterne : hors astérisques, entre astérisques.
        for (index, part) in raw.components(separatedBy: "*").enumerated() {
            isFrench = index % 2 == 1
            guard !part.isEmpty else { continue }
            var piece = AttributedString(part)
            if isFrench && !isUser {
                piece.foregroundColor = Theme.or
                piece.font = .system(size: 17, weight: .semibold, design: .serif)
            }
            output.append(piece)
        }
        return output
    }
}
