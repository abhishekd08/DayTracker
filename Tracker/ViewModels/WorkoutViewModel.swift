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

@MainActor
final class DietViewModel: ObservableObject {
    @Published private(set) var entries: [DietEntry] = []
    @Published private(set) var catalog: [String] = []
    @Published var errorMessage: String?

    private let store: DietStore

    init(store: DietStore = DietStore()) {
        self.store = store
    }

    func load() {
        Task {
            do {
                let payload = try await store.load()
                entries = payload.entries
                catalog = payload.catalog
            } catch {
                errorMessage = "Failed to load meals."
            }
        }
    }

    func addEntry(mealType: MealType, items: [DietItemEntry]) {
        var entry = DietEntry(mealType: mealType, items: items)
        entry.date = Date()
        entries.insert(entry, at: 0)
        persist()
    }

    func updateEntry(_ entry: DietEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        entries.sort { $0.date > $1.date }
        persist()
    }

    func deleteEntry(_ entry: DietEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    func addCatalogItem(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !catalog.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        catalog.append(trimmed)
        catalog.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        persist()
    }

    func removeCatalogItem(named name: String) {
        catalog.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
        persist()
    }

    func exportLog() async -> URL? {
        do {
            return try await store.export(entries: entries, catalog: catalog)
        } catch {
            errorMessage = "Failed to export meals."
            return nil
        }
    }

    private func persist() {
        let snapshotEntries = entries
        let snapshotCatalog = catalog
        Task {
            do {
                try await store.save(entries: snapshotEntries, catalog: snapshotCatalog)
            } catch {
                errorMessage = "Failed to save meals."
            }
        }
    }
}
