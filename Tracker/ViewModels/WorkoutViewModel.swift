import Foundation

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published private(set) var entries: [WorkoutEntry] = []
    @Published private(set) var catalog: [String] = ExerciseCatalog.exercises
    @Published var errorMessage: String?
    private let store: WorkoutStore

    init(store: WorkoutStore = WorkoutStore()) {
        self.store = store
    }

    func loadEntries() {
        Task {
            do {
                let payload = try await store.load()
                entries = payload.entries
                catalog = payload.catalog
            } catch {
                errorMessage = "Failed to load workouts."
            }
        }
    }

    func addEntry(exerciseName: String, reps: Int, sets: Int, weight: Double?) {
        var entry = WorkoutEntry(exerciseName: exerciseName, reps: reps, sets: sets, weight: weight)
        entry.date = Date()
        entries.insert(entry, at: 0)
        if !catalog.contains(where: { $0.caseInsensitiveCompare(exerciseName) == .orderedSame }) {
            catalog.append(exerciseName)
            catalog.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
        persist()
    }

    func updateEntry(_ entry: WorkoutEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        entries.sort { $0.date > $1.date }
        if !catalog.contains(where: { $0.caseInsensitiveCompare(entry.exerciseName) == .orderedSame }) {
            catalog.append(entry.exerciseName)
            catalog.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        }
        persist()
    }

    func deleteEntry(_ entry: WorkoutEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    func deleteEntries(withIDs ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        entries.removeAll { ids.contains($0.id) }
        persist()
    }

    func exportLog(entries: [WorkoutEntry]) async -> URL? {
        do {
            return try await store.export(entries: entries)
        } catch {
            errorMessage = "Failed to export workouts."
            return nil
        }
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

    private func persist() {
        let snapshotEntries = entries
        let snapshotCatalog = catalog
        Task {
            do {
                try await store.save(entries: snapshotEntries, catalog: snapshotCatalog)
            } catch {
                errorMessage = "Failed to save workouts."
            }
        }
    }
}

@MainActor
final class DietViewModel: ObservableObject {
    @Published private(set) var entries: [DietEntry] = []
    @Published private(set) var catalog: [FoodCatalogItem] = []
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
                catalog = payload.catalog.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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

    func deleteEntries(withIDs ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        entries.removeAll { ids.contains($0.id) }
        persist()
    }

    func addCatalogItem(_ item: FoodCatalogItem) {
        let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        if let index = catalog.firstIndex(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            catalog[index] = FoodCatalogItem(
                id: catalog[index].id,
                name: trimmedName,
                portionAmount: item.portionAmount,
                unit: item.unit,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat
            )
        } else {
            catalog.append(FoodCatalogItem(
                name: trimmedName,
                portionAmount: item.portionAmount,
                unit: item.unit,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat
            ))
        }
        catalog.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persist()
    }

    func removeCatalogItem(named name: String) {
        catalog.removeAll { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        persist()
    }

    func catalogItem(named name: String) -> FoodCatalogItem? {
        catalog.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    func exportLog(entries: [DietEntry]) async -> URL? {
        do {
            return try await store.export(entries: entries)
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
