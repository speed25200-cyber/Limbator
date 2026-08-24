import Foundation
import CryptoKit
import Combine

/// Télécharge les poids du modèle depuis HuggingFace.
///
/// Plusieurs gigaoctets sur un réseau mobile : un téléchargement séquentiel
/// naïf prendrait un temps décourageant. Chaque gros fichier est donc découpé
/// en seize tranches téléchargées en parallèle (en-têtes `Range`), puis
/// réassemblé. Les fichiers déjà présents et valides sont sautés — une
/// interruption ne fait pas tout recommencer.
@MainActor
final class MLXModelDownloader: ObservableObject {

    static let shared = MLXModelDownloader()

    /// Jeton HuggingFace facultatif (contourne la limitation de débit).
    static var hfToken: String? {
        UserDefaults.standard.string(forKey: "limb.hf_token")?
            .trimmingCharacters(in: .whitespaces).nilIfEmpty
    }

    enum State: Equatable {
        case idle
        case fetchingManifest
        case downloading(filename: String, fileProgress: Double)
        case verifying(filename: String)
        case completed
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var overallProgress: Double = 0
    @Published private(set) var bytesDownloaded: Int64 = 0
    @Published private(set) var bytesTotal: Int64 = 0
    @Published private(set) var currentSpeedBytesPerSec: Int64 = 0

    private var speedSamples: [(time: Date, bytes: Int64)] = []
    private var destination: URL?

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600 * 4
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 16
        return URLSession(configuration: config)
    }()

    private let parallelChunks = 16
    private let chunkThreshold: Int64 = 20 * 1024 * 1024

    private init() {}

    // =========================================================================
    // MARK: - API
    // =========================================================================

    /// Télécharge le dépôt indiqué dans le dossier indiqué et attend la fin.
    /// Ne lève pas : l'état final est `.completed` ou `.error`, et l'appelant
    /// revérifie lui-même l'intégrité du modèle.
    func ensureDownloaded(repo: String, into directory: URL) async {
        destination = directory
        await run(repo: repo, directory: directory)
    }

    func deleteModel(at directory: URL) {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        state = .idle
        bytesDownloaded = 0
        bytesTotal = 0
        overallProgress = 0
    }

    // =========================================================================
    // MARK: - Inventaire du dépôt
    // =========================================================================

    struct RemoteFile: Sendable {
        let name: String
        let size: Int64
        let sha256: String
        let url: String
    }

    private func listFiles(repo: String) async throws -> [RemoteFile] {
        let path = repo.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !path.isEmpty,
              let apiURL = URL(string: "https://huggingface.co/api/models/\(path)?blobs=true")
        else { throw DownloadError.invalidURL }

        var request = URLRequest(url: apiURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let token = Self.hfToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw DownloadError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let info = try JSONDecoder().decode(RepoInfo.self, from: data)

        var files: [RemoteFile] = []
        for sibling in info.siblings {
            let name = sibling.rfilename
            if name.hasSuffix(".md") || name == ".gitattributes" || name.hasPrefix(".") { continue }
            let fileURL = "https://huggingface.co/\(path)/resolve/main/\(name)"
            // `?blobs=true` donne la taille réelle, y compris pour les gros
            // fichiers LFS. Sans elle il faudrait une requête HEAD par fichier,
            // fragile derrière le CDN — et une taille erronée à zéro produirait
            // un fichier de poids vide, donc un plantage au chargement.
            let advertised = sibling.lfs?.size ?? Int64(sibling.size ?? 0)
            let size: Int64 = advertised > 0 ? advertised : (try await contentLength(fileURL) ?? 0)
            if size <= 0 {
                let critical = name.hasSuffix(".safetensors")
                    || name == "config.json" || name == "tokenizer.json"
                if critical { throw DownloadError.httpStatus(0) }
                continue
            }
            files.append(RemoteFile(name: name, size: size,
                                    sha256: sibling.lfs?.sha256 ?? "", url: fileURL))
        }
        return files
    }

    private func contentLength(_ urlString: String) async throws -> Int64? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
        if let token = Self.hfToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...399).contains(http.statusCode) else { return nil }
        // Pour un fichier LFS, `Content-Length` décrit le pointeur, pas le
        // contenu : la vraie taille est dans `X-Linked-Size`.
        if let linked = http.value(forHTTPHeaderField: "x-linked-size")
            ?? http.value(forHTTPHeaderField: "X-Linked-Size"),
           let value = Int64(linked), value > 0 { return value }
        if let length = http.value(forHTTPHeaderField: "Content-Length"),
           let value = Int64(length), value > 0 { return value }
        return nil
    }

    private struct RepoInfo: Decodable { let siblings: [Sibling] }
    private struct Sibling: Decodable { let rfilename: String; let size: Int?; let lfs: LFS? }
    private struct LFS: Decodable { let size: Int64?; let sha256: String? }

    // =========================================================================
    // MARK: - Boucle principale
    // =========================================================================

    private func run(repo: String, directory: URL) async {
        do {
            state = .fetchingManifest
            let files = try await listFiles(repo: repo)
            guard !files.isEmpty else { state = .error(L.t("download.error.empty")); return }

            bytesTotal = files.reduce(0) { $0 + $1.size }

            // Vérifier un fichier veut dire le hacher entièrement. La première
            // version le faisait deux fois par fichier — une fois pour le
            // décompte, une fois pour décider quoi retélécharger — soit cinq
            // gigaoctets de SHA-256 à chaque reprise d'un téléchargement
            // interrompu. On ne le calcule plus qu'une fois.
            var alreadyPresent: [String: Bool] = [:]
            for file in files {
                if Task.isCancelled { return }
                alreadyPresent[file.name] = await isValid(file, in: directory)
            }
            bytesDownloaded = files
                .filter { alreadyPresent[$0.name] == true }
                .reduce(0) { $0 + $1.size }
            overallProgress = Double(bytesDownloaded) / Double(max(bytesTotal, 1))

            for file in files {
                if Task.isCancelled { return }
                if alreadyPresent[file.name] == true { continue }
                try await download(file, into: directory)
                state = .verifying(filename: file.name)
                if !file.sha256.isEmpty {
                    guard await isValid(file, in: directory) else {
                        throw DownloadError.checksumMismatch(file.name)
                    }
                }
            }
            state = .completed
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func isValid(_ file: RemoteFile, in directory: URL) async -> Bool {
        let destination = directory.appendingPathComponent(file.name)
        guard FileManager.default.fileExists(atPath: destination.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: destination.path),
              let size = attributes[.size] as? Int64,
              size > 0, size == file.size else { return false }
        if file.sha256.isEmpty { return true }
        let expected = file.sha256
        return await Task.detached(priority: .utility) {
            MLXModelDownloader.sha256(of: destination) == expected
        }.value
    }

    nonisolated private static func sha256(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: { () -> Bool in
            guard let data = try? handle.read(upToCount: 1024 * 1024), !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    // =========================================================================
    // MARK: - Téléchargement
    // =========================================================================

    private func download(_ file: RemoteFile, into directory: URL) async throws {
        guard file.size > 0 else { throw DownloadError.httpStatus(0) }
        if file.size > chunkThreshold {
            try await downloadInChunks(file, into: directory)
        } else {
            try await downloadWhole(file, into: directory)
        }
    }

    private func downloadWhole(_ file: RemoteFile, into directory: URL) async throws {
        let destination = directory.appendingPathComponent(file.name)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        guard let source = URL(string: file.url) else { throw DownloadError.invalidURL }

        var request = URLRequest(url: source)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let token = Self.hfToken { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let base = bytesDownloaded
        state = .downloading(filename: file.name, fileProgress: 0)
        let (temporary, response) = try await session.download(for: request)
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 206 else {
            throw DownloadError.httpStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporary, to: destination)

        bytesDownloaded = base + file.size
        overallProgress = Double(bytesDownloaded) / Double(max(bytesTotal, 1))
        state = .downloading(filename: file.name, fileProgress: 1.0)
        recordSpeedSample()
    }

    private func downloadInChunks(_ file: RemoteFile, into directory: URL) async throws {
        let destination = directory.appendingPathComponent(file.name)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        guard URL(string: file.url) != nil else { throw DownloadError.invalidURL }

        let base = bytesDownloaded
        state = .downloading(filename: file.name, fileProgress: 0)

        let chunkCount = max(1, parallelChunks)
        let chunkSize = file.size / Int64(chunkCount)
        let scratch = FileManager.default.temporaryDirectory
            .appendingPathComponent("limb_chunks_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }

        let urlString = file.url
        let fileSize = file.size
        let token = Self.hfToken
        let tracker = ChunkTracker()

        let ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                let received = tracker.totalBytesReceived()
                guard let self else { return }
                await MainActor.run {
                    self.bytesDownloaded = base + received
                    self.overallProgress = Double(self.bytesDownloaded) / Double(max(self.bytesTotal, 1))
                    self.state = .downloading(filename: file.name,
                                              fileProgress: Double(received) / Double(max(fileSize, 1)))
                    self.recordSpeedSample()
                }
            }
        }
        defer { ticker.cancel() }

        var chunkPaths = [URL?](repeating: nil, count: chunkCount)
        let sessionRef = session
        try await withThrowingTaskGroup(of: (Int, URL).self) { group in
            for index in 0..<chunkCount {
                let start = Int64(index) * chunkSize
                let end: Int64 = (index == chunkCount - 1) ? fileSize - 1 : start + chunkSize - 1
                let chunkPath = scratch.appendingPathComponent("chunk_\(index)")
                group.addTask {
                    guard let url = URL(string: urlString) else { throw DownloadError.invalidURL }
                    var request = URLRequest(url: url)
                    request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
                    if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
                    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Int, URL), Error>) in
                        let task = sessionRef.downloadTask(with: request) { temporary, response, error in
                            if let error { continuation.resume(throwing: error); return }
                            guard let temporary else {
                                continuation.resume(throwing: DownloadError.invalidURL); return
                            }
                            guard let http = response as? HTTPURLResponse,
                                  http.statusCode == 206 || http.statusCode == 200 else {
                                continuation.resume(throwing: DownloadError.httpStatus(
                                    (response as? HTTPURLResponse)?.statusCode ?? 0))
                                return
                            }
                            do {
                                try? FileManager.default.removeItem(at: chunkPath)
                                try FileManager.default.moveItem(at: temporary, to: chunkPath)
                                continuation.resume(returning: (index, chunkPath))
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                        tracker.add(task)
                        task.resume()
                    }
                }
            }
            for try await (index, path) in group { chunkPaths[index] = path }
        }
        ticker.cancel()

        try? FileManager.default.removeItem(at: destination)
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let writer = try FileHandle(forWritingTo: destination)
        defer { try? writer.close() }
        for index in 0..<chunkCount {
            guard let chunkPath = chunkPaths[index] else {
                throw DownloadError.checksumMismatch(file.name)
            }
            let reader = try FileHandle(forReadingFrom: chunkPath)
            while autoreleasepool(invoking: { () -> Bool in
                guard let data = try? reader.read(upToCount: 1024 * 1024), !data.isEmpty else { return false }
                try? writer.write(contentsOf: data)
                return true
            }) {}
            try? reader.close()
        }

        bytesDownloaded = base + file.size
        overallProgress = Double(bytesDownloaded) / Double(max(bytesTotal, 1))
        state = .downloading(filename: file.name, fileProgress: 1.0)
        recordSpeedSample()
    }

    /// Débit moyen sur les dix dernières secondes — une moyenne glissante, pour
    /// que le chiffre affiché ne saute pas à chaque tranche terminée.
    private func recordSpeedSample() {
        let now = Date()
        speedSamples.append((time: now, bytes: bytesDownloaded))
        speedSamples.removeAll { now.timeIntervalSince($0.time) > 10 }
        if let first = speedSamples.first, speedSamples.count >= 2 {
            let elapsed = now.timeIntervalSince(first.time)
            let delta = bytesDownloaded - first.bytes
            currentSpeedBytesPerSec = elapsed > 0.5 ? Int64(Double(delta) / elapsed) : 0
        }
    }

    enum DownloadError: LocalizedError {
        case invalidURL
        case httpStatus(Int)
        case checksumMismatch(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:               return L.t("download.error.url")
            case .httpStatus(let code):     return L.t("download.error.http", code)
            case .checksumMismatch(let name): return L.t("download.error.checksum", name)
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

/// Boîte thread-safe pour les tâches d'un téléchargement en tranches : les
/// rappels d'URLSession arrivent sur des files quelconques.
final class ChunkTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var tasks: [URLSessionTask] = []

    func add(_ task: URLSessionTask) {
        lock.lock(); defer { lock.unlock() }
        tasks.append(task)
    }

    func totalBytesReceived() -> Int64 {
        lock.lock(); defer { lock.unlock() }
        return tasks.reduce(0) { $0 + $1.countOfBytesReceived }
    }
}
