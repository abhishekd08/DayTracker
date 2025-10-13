import Foundation

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published private(set) var entries: [WorkoutEntry] = []
    @Published var errorMessage: String?
    private let store: WorkoutStore

    init(store: WorkoutStore = WorkoutStore()) {
        self.store = store
    }

    func loadEntries() {
        Task {
            do {
                let loadedEntries = try await store.load()
                entries = loadedEntries
            } catch {
                errorMessage = "Failed to load workouts."
            }
        }
    }

    func addEntry(exerciseName: String, reps: Int, sets: Int, weight: Double?) {
        var entry = WorkoutEntry(exerciseName: exerciseName, reps: reps, sets: sets, weight: weight)
        entry.date = Date()
        entries.insert(entry, at: 0)
        persistEntries()
    }

    func updateEntry(_ entry: WorkoutEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        entries.sort { $0.date > $1.date }
        persistEntries()
    }

    func deleteEntry(_ entry: WorkoutEntry) {
        entries.removeAll { $0.id == entry.id }
        persistEntries()
    }

    func exportLog() async -> URL? {
        do {
            return try await store.export(entries)
        } catch {
            errorMessage = "Failed to export workouts."
            return nil
        }
    }

    private func persistEntries() {
        let snapshot = entries
        Task {
            do {
                try await store.save(snapshot)
            } catch {
                errorMessage = "Failed to save workouts."
            }
        }
    }
}
