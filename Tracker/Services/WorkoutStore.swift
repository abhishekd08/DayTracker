import Foundation

final class WorkoutStore {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "WorkoutStore", qos: .userInitiated)

    private static let exportFilenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(filename: String = "workout-log.json") {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = baseURL.appendingPathComponent("Tracker", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        self.fileURL = directoryURL.appendingPathComponent(filename)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() async throws -> [WorkoutEntry] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [decoder, fileURL] in
                do {
                    guard FileManager.default.fileExists(atPath: fileURL.path) else {
                        continuation.resume(returning: [])
                        return
                    }
                    let data = try Data(contentsOf: fileURL)
                    let entries = try decoder.decode([WorkoutEntry].self, from: data)
                    continuation.resume(returning: entries.sorted { $0.date > $1.date })
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func save(_ entries: [WorkoutEntry]) async throws {
        let snapshot = entries
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [encoder, fileURL] in
                do {
                    let data = try encoder.encode(snapshot)
                    try data.write(to: fileURL, options: [.atomic])
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func export(_ entries: [WorkoutEntry]) async throws -> URL {
        let snapshot = entries
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [encoder, fileURL] in
                do {
                    let data = try encoder.encode(snapshot)
                    try data.write(to: fileURL, options: [.atomic])

                    let filename = "WorkoutLog-\(Self.exportFilenameFormatter.string(from: Date())).json"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }

                    try FileManager.default.copyItem(at: fileURL, to: tempURL)
                    continuation.resume(returning: tempURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
