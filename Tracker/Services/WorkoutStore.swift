import Foundation

struct WorkoutStorePayload: Codable {
    var entries: [WorkoutEntry]
    var catalog: [String]
}

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

    func load() async throws -> WorkoutStorePayload {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [decoder, fileURL] in
                do {
                    guard FileManager.default.fileExists(atPath: fileURL.path) else {
                        continuation.resume(returning: WorkoutStorePayload(entries: [], catalog: ExerciseCatalog.exercises))
                        return
                    }
                    let data = try Data(contentsOf: fileURL)
                    if let payload = try? decoder.decode(WorkoutStorePayload.self, from: data) {
                        let sortedEntries = payload.entries.sorted { $0.date > $1.date }
                        let normalizedCatalog = payload.catalog.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                        let catalog = normalizedCatalog.isEmpty ? ExerciseCatalog.exercises : normalizedCatalog
                        continuation.resume(returning: WorkoutStorePayload(entries: sortedEntries, catalog: catalog))
                    } else {
                        let entries = try decoder.decode([WorkoutEntry].self, from: data)
                        continuation.resume(returning: WorkoutStorePayload(entries: entries.sorted { $0.date > $1.date }, catalog: ExerciseCatalog.exercises))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func save(entries: [WorkoutEntry], catalog: [String]) async throws {
        let payload = WorkoutStorePayload(entries: entries, catalog: catalog)
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [encoder, fileURL] in
                do {
                    let data = try encoder.encode(payload)
                    try data.write(to: fileURL, options: [.atomic])
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func export(entries: [WorkoutEntry]) async throws -> URL {
        let snapshot = entries
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [encoder] in
                do {
                    let filename = "WorkoutLog-\(Self.exportFilenameFormatter.string(from: Date())).json"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }

                    let data = try encoder.encode(snapshot)
                    try data.write(to: tempURL, options: [.atomic])
                    continuation.resume(returning: tempURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

struct DietStorePayload: Codable {
    var entries: [DietEntry]
    var catalog: [String]
}

final class DietStore {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "DietStore", qos: .userInitiated)

    private static let exportFilenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(filename: String = "diet-log.json") {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = baseURL.appendingPathComponent("Tracker", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        self.fileURL = directoryURL.appendingPathComponent(filename)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() async throws -> DietStorePayload {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [decoder, fileURL] in
                do {
                    guard FileManager.default.fileExists(atPath: fileURL.path) else {
                        continuation.resume(returning: DietStorePayload(entries: [], catalog: ["Banana"]))
                        return
                    }

                    let data = try Data(contentsOf: fileURL)
                    let payload = try decoder.decode(DietStorePayload.self, from: data)
                    let normalizedEntries = payload.entries.sorted { $0.date > $1.date }
                    let sortedCatalog = payload.catalog.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                    continuation.resume(returning: DietStorePayload(entries: normalizedEntries, catalog: sortedCatalog))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func save(entries: [DietEntry], catalog: [String]) async throws {
        let payload = DietStorePayload(entries: entries, catalog: catalog)
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [encoder, fileURL] in
                do {
                    let data = try encoder.encode(payload)
                    try data.write(to: fileURL, options: [.atomic])
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func export(entries: [DietEntry]) async throws -> URL {
        let snapshot = entries
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [encoder] in
                do {
                    let filename = "DietLog-\(Self.exportFilenameFormatter.string(from: Date())).json"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }

                    let data = try encoder.encode(snapshot)
                    try data.write(to: tempURL, options: [.atomic])
                    continuation.resume(returning: tempURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
