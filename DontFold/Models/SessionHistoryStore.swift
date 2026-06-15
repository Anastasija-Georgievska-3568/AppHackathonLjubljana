import Foundation

/// Append-only log of completed sessions, persisted as JSON in Application
/// Support. v1 doesn't display this anywhere; it's here so the v2 web app's
/// "past conversations" feature has data to sync from day one.
@Observable
@MainActor
final class SessionHistoryStore {
    private let filename = "session_history.json"

    private(set) var entries: [SessionResult] = []

    init() { load() }

    func append(_ result: SessionResult) {
        entries.append(result)
        save()
    }

    func reset() {
        entries = []
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
    }

    // MARK: - File I/O

    private var fileURL: URL? {
        guard let dir = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return dir.appendingPathComponent(filename)
    }

    private func load() {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return }
        entries = (try? JSONDecoder.iso.decode([SessionResult].self, from: data)) ?? []
    }

    private func save() {
        guard let url = fileURL else { return }
        guard let data = try? JSONEncoder.iso.encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
