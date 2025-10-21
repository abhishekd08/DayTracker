
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let spacing: CGFloat = 24
                let verticalPadding: CGFloat = 32
                let availableHeight = max(proxy.size.height - (verticalPadding * 2) - spacing, 0)
                let cardHeight = availableHeight > 0 ? availableHeight / 2 : proxy.size.height / 2

                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()

                    VStack(spacing: spacing) {
                        NavigationLink {
                            WorkoutLogView()
                        } label: {
                            selectionCard(title: "Workout", subtitle: "Log sets, reps, and weights", systemImage: "dumbbell.fill")
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .frame(height: cardHeight)

                        NavigationLink {
                            DietLogView()
                        } label: {
                            selectionCard(title: "Diet", subtitle: "Track meals and portions", systemImage: "fork.knife")
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .frame(height: cardHeight)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, verticalPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .navigationTitle("GoodDay - Life Logger")
        }
    }

    private func selectionCard(title: String, subtitle: String, systemImage: String) -> some View {
        let baseColor: Color
        switch systemImage {
        case "dumbbell.fill":
            baseColor = .indigo
        case "fork.knife":
            baseColor = .mint
        default:
            baseColor = .accentColor
        }

        return VStack(alignment: .leading, spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(baseColor)

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(baseColor.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct WorkoutLogView: View {
    @StateObject private var viewModel = WorkoutViewModel()

    @State private var exerciseQuery = ""
    @State private var selectedExercise: String?
    @State private var repsText = ""
    @State private var setsText = ""
    @State private var weightText = ""
    @State private var activeSheet: ActiveSheet?
    @State private var filterRange: DateRange?
    @State private var isSelectingEntries = false
    @State private var selectedEntryIDs: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @FocusState private var focusedField: Field?
    @FocusState private var isExerciseSearchFocused: Bool

    private enum Field: Hashable {
        case reps, sets, weight
    }

    private enum ActiveSheet: Identifiable {
        case edit(WorkoutEntry)
        case filter
        case share(ExportedFile)

        var id: String {
            switch self {
            case .edit(let entry):
                return entry.id.uuidString
            case .filter:
                return "filter"
            case .share(let file):
                return file.id.uuidString
            }
        }
    }

    private struct ExportedFile: Identifiable {
        let id = UUID()
        let url: URL
    }

    private static let filterFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var displayedEntries: [WorkoutEntry] {
        guard let range = filterRange else { return viewModel.entries }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: range.start)
        let endOfDayStart = calendar.startOfDay(for: range.end)
        let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: endOfDayStart) ?? endOfDayStart
        return viewModel.entries.filter { entry in
            (entry.date >= startOfDay) && (entry.date <= endOfDay)
        }
    }

    private var filterDescription: String? {
        guard let range = filterRange else { return nil }
        let formatter = Self.filterFormatter
        let calendar = Calendar.current
        let endDisplay = calendar.startOfDay(for: range.end)
        if calendar.isDate(range.start, inSameDayAs: endDisplay) {
            return formatter.string(from: range.start)
        }
        return "\(formatter.string(from: range.start)) – \(formatter.string(from: endDisplay))"
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var canAddEntry: Bool {
        guard let selectedExercise else { return false }
        guard Int(repsText) ?? 0 > 0 else { return false }
        guard Int(setsText) ?? 0 > 0 else { return false }
        if weightText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        return Double(weightText) != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                addExerciseCard
                historySection
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workout Log")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isSelectingEntries && !selectedEntryIDs.isEmpty {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Delete selected workouts")
                }

                if !viewModel.entries.isEmpty || isSelectingEntries {
                    Button {
                        toggleWorkoutSelectionMode()
                    } label: {
                        Image(systemName: isSelectingEntries ? "xmark.circle" : "checkmark.circle")
                            .imageScale(.large)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel(isSelectingEntries ? "Cancel selection" : "Select workouts")
                }

                Button {
                    exportLog()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(!canExportEntries)
                .accessibilityLabel("Export workouts JSON")
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                    isExerciseSearchFocused = false
                }
            }
        }
        .sheet(item: $activeSheet) { destination in
            switch destination {
            case .edit(let entry):
                EditWorkoutEntryView(entry: entry, catalog: viewModel.catalog) { updatedEntry in
                    viewModel.updateEntry(updatedEntry)
                } onDelete: { entryToDelete in
                    viewModel.deleteEntry(entryToDelete)
                }
            case .filter:
                DateRangeFilterSheet(selectedRange: $filterRange)
            case .share(let file):
                ShareSheet(activityItems: [file.url]) {
                    Task { @MainActor in
                        try? FileManager.default.removeItem(at: file.url)
                        activeSheet = nil
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete selected workouts?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedWorkouts()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(selectedEntryIDs.count) workout\(selectedEntryIDs.count == 1 ? "" : "s").")
        }
        .alert("Error", isPresented: errorAlertBinding, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .task {
            viewModel.loadEntries()
        }
    }

    private var addExerciseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Exercise")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                let trimmedQuery = exerciseQuery.trimmingCharacters(in: .whitespacesAndNewlines)

                exerciseSearchField()

                if !trimmedQuery.isEmpty && !filteredExercises.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredExercises, id: \.self) { name in
                                Button {
                                    selectedExercise = name
                                    exerciseQuery = name
                                } label: {
                                    HStack {
                                        Text(name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedExercise == name {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.accentColor)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.removeCatalogItem(named: name)
                                        if selectedExercise == name {
                                            selectedExercise = nil
                                        }
                                        if exerciseQuery.caseInsensitiveCompare(name) == .orderedSame {
                                            exerciseQuery = ""
                                        }
                                    } label: {
                                        Label("Remove exercise", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 140)
                }

                if !trimmedQuery.isEmpty && !viewModel.catalog.contains(where: { $0.caseInsensitiveCompare(trimmedQuery) == .orderedSame }) {
                    Button {
                        viewModel.addCatalogItem(named: trimmedQuery)
                        selectedExercise = trimmedQuery
                        exerciseQuery = trimmedQuery
                    } label: {
                        Label("Add \(trimmedQuery) to exercises", systemImage: "plus")
                            .font(.subheadline)
                    }
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .reps)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                TextField("0", text: $setsText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .sets)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Weight (kg)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                TextField("Optional", text: $weightText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .weight)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Button(action: addEntry) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Exercise")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAddEntry)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var historySection: some View {
        if viewModel.entries.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No workouts logged yet")
                    .font(.headline)
                Text("Add your first exercise above to start tracking.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("History")
                        .font(.headline)
                    Spacer()
                    filterButton
                }

                if let filterDescription {
                    Text("Showing entries for \(filterDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if displayedEntries.isEmpty {
                    VStack(spacing: 8) {
                        Text("No workouts match this range")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Clear Filter") {
                            filterRange = nil
                        }
                        .buttonStyle(.borderless)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(displayedEntries) { entry in
                        workoutHistoryRow(for: entry)
                    }
                }
            }
        }
    }

    private func workoutHistoryRow(for entry: WorkoutEntry) -> some View {
        let isSelected = selectedEntryIDs.contains(entry.id)
        return WorkoutEntryCard(entry: entry)
            .overlay {
                if isSelectingEntries && isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.7), lineWidth: 2)
                }
            }
            .padding(.leading, isSelectingEntries ? 36 : 0)
            .overlay(alignment: .leading) {
                if isSelectingEntries {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .padding(.leading, 4)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleWorkoutEntryTap(entry)
            }
    }

    private var filterButton: some View {
        Button {
            activeSheet = .filter
        } label: {
            Image(systemName: filterRange == nil ? "calendar" : "calendar.circle.fill")
                .imageScale(.medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(filterRange == nil ? Color.primary : Color.accentColor)
        }
        .accessibilityLabel(filterRange == nil ? "Filter history" : "Change date filter")
        .buttonStyle(.plain)
    }

    private func handleWorkoutEntryTap(_ entry: WorkoutEntry) {
        if isSelectingEntries {
            toggleWorkoutSelection(for: entry)
        } else {
            activeSheet = .edit(entry)
        }
    }

    private func toggleWorkoutSelection(for entry: WorkoutEntry) {
        if selectedEntryIDs.contains(entry.id) {
            selectedEntryIDs.remove(entry.id)
        } else {
            selectedEntryIDs.insert(entry.id)
        }
    }

    private func toggleWorkoutSelectionMode() {
        if isSelectingEntries {
            resetWorkoutSelection()
        } else {
            selectedEntryIDs.removeAll()
            isSelectingEntries = true
        }
    }

    private func resetWorkoutSelection() {
        selectedEntryIDs.removeAll()
        isSelectingEntries = false
    }

    private func deleteSelectedWorkouts() {
        viewModel.deleteEntries(withIDs: selectedEntryIDs)
        resetWorkoutSelection()
    }

    @ViewBuilder
    private func exerciseSearchField() -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)

            TextField("Search exercise", text: $exerciseQuery)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .focused($isExerciseSearchFocused)
                .onChange(of: exerciseQuery, initial: false) { _, newValue in
                    let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let match = viewModel.catalog.first(where: { $0.caseInsensitiveCompare(trimmedValue) == .orderedSame }) {
                        selectedExercise = match
                    } else {
                        selectedExercise = nil
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            isExerciseSearchFocused = true
        }
    }

    private func exportLog() {
        Task {
            let entriesToExport = entriesForExport
            guard !entriesToExport.isEmpty else { return }
            if let url = await viewModel.exportLog(entries: entriesToExport) {
                await MainActor.run {
                    activeSheet = .share(ExportedFile(url: url))
                }
            }
        }
    }

    private var filteredExercises: [String] {
        let trimmed = exerciseQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return viewModel.catalog }
        return viewModel.catalog.filter { $0.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    private func addEntry() {
        guard let selectedExercise else { return }
        let reps = Int(repsText) ?? 0
        let sets = Int(setsText) ?? 0
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        let weight = trimmedWeight.isEmpty ? nil : Double(trimmedWeight)

        viewModel.addEntry(exerciseName: selectedExercise, reps: reps, sets: sets, weight: weight)
        resetForm()
    }

    private func resetForm() {
        selectedExercise = nil
        exerciseQuery = ""
        repsText = ""
        setsText = ""
        weightText = ""
        focusedField = nil
        isExerciseSearchFocused = false
    }

    private var entriesForExport: [WorkoutEntry] {
        if filterRange == nil {
            return viewModel.entries
        }
        return displayedEntries
    }

    private var canExportEntries: Bool {
        !entriesForExport.isEmpty
    }
}

private struct DietLogView: View {
    @StateObject private var viewModel = DietViewModel()

    @State private var mealType: MealType = DietLogView.defaultMealType(for: Date())
    @State private var itemQuery = ""
    @State private var selectedItem: String?
    @State private var quantityText = ""
    @State private var mealItems: [MealItemDraft] = []
    @State private var activeSheet: ActiveSheet?
    @State private var filterRange: DateRange?
    @State private var filterMealType: MealType?
    @State private var catalogForm: CatalogForm?
    @State private var isSelectingEntries = false
    @State private var selectedEntryIDs: Set<UUID> = []
    @State private var showDeleteConfirmation = false
    @State private var showMissingMacrosAlert = false
    @State private var missingMacrosFoods: [String] = []
    @State private var pendingMealItems: [DietItemEntry]?
    @FocusState private var isMealInputFocused: Bool

    private enum ActiveSheet: Identifiable {
        case edit(DietEntry)
        case filter
        case share(ExportedFile)

        var id: String {
            switch self {
            case .edit(let entry):
                return entry.id.uuidString
            case .filter:
                return "filter"
            case .share(let file):
                return file.id.uuidString
            }
        }
    }

    private struct ExportedFile: Identifiable {
        let id = UUID()
        let url: URL
    }

    private struct MealItemDraft: Identifiable, Equatable {
        let id: UUID
        var name: String
        var amount: Double
        var unit: FoodCatalogItem.PortionUnit
        var calories: Int?
        var protein: Int?
        var carbs: Int?
        var fat: Int?
        var hasCatalogEntry: Bool

        init(
            id: UUID = UUID(),
            name: String,
            amount: Double,
            unit: FoodCatalogItem.PortionUnit,
            calories: Int? = nil,
            protein: Int? = nil,
            carbs: Int? = nil,
            fat: Int? = nil,
            hasCatalogEntry: Bool = false
        ) {
            self.id = id
            self.name = name
            self.amount = amount
            self.unit = unit
            self.calories = calories
            self.protein = protein
            self.carbs = carbs
            self.fat = fat
            self.hasCatalogEntry = hasCatalogEntry
        }
    }

    private struct CatalogForm: Identifiable {
        let id = UUID()
        var name: String
        var portionAmount: String = "100"
        var unit: FoodCatalogItem.PortionUnit = .grams
        var calories: String = ""
        var protein: String = ""
        var carbs: String = ""
        var fat: String = ""
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static func defaultMealType(for date: Date) -> MealType {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        switch minutes {
        case 420..<495: // 7:00 - 8:15
            return .preWorkout
        case 495..<600: // 8:15 - 10:00
            return .postWorkout
        case 720..<840: // 12:00 - 14:00
            return .lunch
        case 990..<1080: // 16:30 - 18:00
            return .eveningMeal
        case 1200..<1320: // 20:00 - 22:00
            return .dinner
        default:
            return .extras
        }
    }

    private var filteredCatalog: [FoodCatalogItem] {
        let trimmed = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return viewModel.catalog }
        return viewModel.catalog.filter { $0.name.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    private var displayedEntries: [DietEntry] {
        viewModel.entries.filter { entry in
            let matchesRange: Bool
            if let range = filterRange {
                let startOfDay = Calendar.current.startOfDay(for: range.start)
                let endOfDayStart = Calendar.current.startOfDay(for: range.end)
                let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: endOfDayStart) ?? endOfDayStart
                matchesRange = (entry.date >= startOfDay) && (entry.date <= endOfDay)
            } else {
                matchesRange = true
            }
            let matchesMeal = filterMealType.map { entry.mealType == $0 } ?? true
            return matchesRange && matchesMeal
        }
    }

    private var filterDescription: String {
        var components: [String] = []
        if let range = filterRange {
            let formatter = Self.dateFormatter
            let calendar = Calendar.current
            let endDisplay = calendar.startOfDay(for: range.end)
            if calendar.isDate(range.start, inSameDayAs: endDisplay) {
                components.append(formatter.string(from: range.start))
            } else {
                components.append("\(formatter.string(from: range.start)) – \(formatter.string(from: endDisplay))")
            }
        }
        if let filterMealType {
            components.append(filterMealType.displayName)
        }
        return components.joined(separator: " • ")
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var canAddItem: Bool {
        guard let amount = Double(quantityText.trimmingCharacters(in: .whitespacesAndNewlines)), amount > 0 else {
            return false
        }

        let name: String
        if let selectedItem {
            name = selectedItem
        } else {
            let trimmedQuery = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedQuery.isEmpty else { return false }
            name = trimmedQuery
        }

        return !mealItems.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    private var canSaveMeal: Bool {
        !mealItems.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                addMealCard
                historySection
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Diet Log")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if isSelectingEntries && !selectedEntryIDs.isEmpty {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Delete selected meals")
                }

                if !viewModel.entries.isEmpty || isSelectingEntries {
                    Button {
                        toggleDietSelectionMode()
                    } label: {
                        Image(systemName: isSelectingEntries ? "xmark.circle" : "checkmark.circle")
                            .imageScale(.large)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel(isSelectingEntries ? "Cancel selection" : "Select meals")
                }

                Button {
                    exportLog()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(!canExportEntries)
                .accessibilityLabel("Export meals JSON")
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isMealInputFocused = false
                }
            }
        }
        .sheet(item: $activeSheet) { destination in
            switch destination {
            case .edit(let entry):
                EditDietEntryView(entry: entry) { updated in
                    viewModel.updateEntry(updated)
                } onDelete: { toDelete in
                    viewModel.deleteEntry(toDelete)
                }
            case .filter:
                DietFilterSheet(selectedRange: $filterRange, selectedMealType: $filterMealType)
            case .share(let file):
                ShareSheet(activityItems: [file.url]) {
                    Task { @MainActor in
                        try? FileManager.default.removeItem(at: file.url)
                        activeSheet = nil
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete selected meals?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedMeals()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(selectedEntryIDs.count) meal\(selectedEntryIDs.count == 1 ? "" : "s").")
        }
        .sheet(item: $catalogForm) { form in
            CatalogItemSheet(form: form) { updatedForm in
                handleCatalogSave(updatedForm)
                catalogForm = nil
            }
        }
        .alert("Error", isPresented: errorAlertBinding, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert("Missing macros", isPresented: $showMissingMacrosAlert) {
            Button("Save Anyway") {
                if let items = pendingMealItems {
                    finalizeMealSave(with: items)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingMealItems = nil
            }
        } message: {
            if missingMacrosFoods.isEmpty {
                Text("Some foods are missing macro information.")
            } else {
                Text("Add macros in the catalog for: \(missingMacrosFoods.joined(separator: ", ")) to calculate nutrition automatically.")
            }
        }
        .task {
            viewModel.load()
        }
        .onAppear {
            mealType = Self.defaultMealType(for: Date())
        }
    }

    private struct CatalogItemSheet: View {
        @Environment(\.dismiss) private var dismiss
        @State private var form: CatalogForm
        let onSave: (CatalogForm) -> Void
        @FocusState private var isFieldFocused: Bool

        init(form: CatalogForm, onSave: @escaping (CatalogForm) -> Void) {
            _form = State(initialValue: form)
            self.onSave = onSave
        }

        var body: some View {
            NavigationStack {
                Form {
                    Section("Food") {
                        Text(form.name)
                            .font(.headline)
                    }

                    Section("Standard Portion") {
                        TextField("Amount", text: $form.portionAmount)
                            .keyboardType(.decimalPad)
                            .focused($isFieldFocused)
                        Picker("Unit", selection: $form.unit) {
                            ForEach(FoodCatalogItem.PortionUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                    }

                    Section("Macros per portion (optional)") {
                        TextField("Calories", text: $form.calories)
                            .keyboardType(.decimalPad)
                            .focused($isFieldFocused)
                        TextField("Protein (g)", text: $form.protein)
                            .keyboardType(.decimalPad)
                            .focused($isFieldFocused)
                        TextField("Carbs (g)", text: $form.carbs)
                            .keyboardType(.decimalPad)
                            .focused($isFieldFocused)
                        TextField("Fat (g)", text: $form.fat)
                            .keyboardType(.decimalPad)
                            .focused($isFieldFocused)
                    }
                }
                .navigationTitle("Add to Catalog")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(form)
                            dismiss()
                        }
                    }

                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFieldFocused = false
                        }
                    }
                }
            }
        }
    }

    private var addMealCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Meal")
                .font(.headline)

            Picker("Meal Type", selection: $mealType) {
                ForEach(MealType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: 8) {
                let trimmedQuery = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)

                dietSearchField()

                if !trimmedQuery.isEmpty && !filteredCatalog.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredCatalog) { item in
                                Button {
                                    selectedItem = item.name
                                    itemQuery = item.name
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .foregroundStyle(.primary)
                                            Text("Standard: \(formatNumber(Double(item.portionAmount))) \(item.unit.symbol)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if let selectedItem, selectedItem.caseInsensitiveCompare(item.name) == .orderedSame {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.accentColor)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.removeCatalogItem(named: item.name)
                                        if let currentSelection = selectedItem, currentSelection.caseInsensitiveCompare(item.name) == .orderedSame {
                                            selectedItem = nil
                                            itemQuery = ""
                                        }
                                    } label: {
                                        Label("Remove from catalog", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 140)
                }

                if !trimmedQuery.isEmpty && !catalogContains(trimmedQuery) {
                    Button {
                        let defaultPortion = quantityText.trimmingCharacters(in: .whitespacesAndNewlines)
                        catalogForm = CatalogForm(
                            name: trimmedQuery,
                            portionAmount: defaultPortion.isEmpty ? "100" : defaultPortion,
                            unit: currentPortionUnit
                        )
                    } label: {
                        Label("Add \(trimmedQuery) to catalog", systemImage: "plus")
                            .font(.subheadline)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(amountPlaceholder, text: $quantityText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($isMealInputFocused)
            }

            Button {
                addItemToMeal()
            } label: {
                Label("Add Item", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canAddItem)

            if !mealItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Items in this meal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    ForEach(mealItems) { draft in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(draft.name)
                                .font(.body)
                            Text(formattedAmount(for: draft))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            let macroInfo = macrosSummary(for: draft)
                            if let summary = macroInfo.text {
                                Text(summary)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else if let warning = macroInfo.warning {
                                Text(warning)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                            Spacer()
                            Button(role: .destructive) {
                                mealItems.removeAll { $0.id == draft.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            Button {
                addMeal()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Meal")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSaveMeal)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var historySection: some View {
        if viewModel.entries.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "leaf")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No meals logged yet")
                    .font(.headline)
                Text("Add your first meal above to start tracking.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Meals")
                        .font(.headline)
                    Spacer()
                    filterButton
                }

                if !filterDescription.isEmpty {
                    Text("Showing \(filterDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if displayedEntries.isEmpty {
                    VStack(spacing: 8) {
                        Text("No meals match the filter")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Clear Filters") {
                            filterRange = nil
                            filterMealType = nil
                        }
                        .buttonStyle(.borderless)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(displayedEntries) { entry in
                        dietHistoryRow(for: entry)
                    }
                }
            }
        }
    }

    private func dietHistoryRow(for entry: DietEntry) -> some View {
        let isSelected = selectedEntryIDs.contains(entry.id)
        return DietEntryCard(entry: entry)
            .overlay {
                if isSelectingEntries && isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.7), lineWidth: 2)
                }
            }
            .padding(.leading, isSelectingEntries ? 36 : 0)
            .overlay(alignment: .leading) {
                if isSelectingEntries {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                        .padding(.leading, 4)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleDietEntryTap(entry)
            }
    }

    private var filterButton: some View {
        let filterActive = filterRange != nil || filterMealType != nil
        return Button {
            activeSheet = .filter
        } label: {
            Image(systemName: filterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .imageScale(.medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(filterActive ? Color.accentColor : Color.primary)
        }
        .accessibilityLabel(filterActive ? "Change meal filters" : "Filter meals")
        .buttonStyle(.plain)
    }

    private func handleDietEntryTap(_ entry: DietEntry) {
        if isSelectingEntries {
            toggleDietSelection(for: entry)
        } else {
            activeSheet = .edit(entry)
        }
    }

    private func toggleDietSelection(for entry: DietEntry) {
        if selectedEntryIDs.contains(entry.id) {
            selectedEntryIDs.remove(entry.id)
        } else {
            selectedEntryIDs.insert(entry.id)
        }
    }

    private func toggleDietSelectionMode() {
        if isSelectingEntries {
            resetDietSelection()
        } else {
            selectedEntryIDs.removeAll()
            isSelectingEntries = true
        }
    }

    private func resetDietSelection() {
        selectedEntryIDs.removeAll()
        isSelectingEntries = false
    }

    private func deleteSelectedMeals() {
        viewModel.deleteEntries(withIDs: selectedEntryIDs)
        resetDietSelection()
    }

    @ViewBuilder
    private func dietSearchField() -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.quaternaryLabel), lineWidth: 1)

            TextField("Search or add food", text: $itemQuery)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .focused($isMealInputFocused)
                .onChange(of: itemQuery, initial: false) { _, newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let match = viewModel.catalogItem(named: trimmed) {
                        selectedItem = match.name
                    } else {
                        selectedItem = nil
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            isMealInputFocused = true
        }
    }

    private func addItemToMeal() {
        let trimmedAmount = quantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Double(trimmedAmount), amount > 0 else { return }

        let name: String
        if let selectedItem {
            name = selectedItem
        } else {
            name = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !name.isEmpty else { return }

        let catalogItem = viewModel.catalogItem(named: name)
        let unit = catalogItem?.unit ?? .grams
        let scaledMacros = catalogItem?.scaledMacros(for: amount)

        mealItems.append(
            MealItemDraft(
                name: name,
                amount: amount,
                unit: unit,
                calories: scaledMacros?.calories,
                protein: scaledMacros?.protein,
                carbs: scaledMacros?.carbs,
                fat: scaledMacros?.fat,
                hasCatalogEntry: catalogItem != nil
            )
        )
        itemQuery = ""
        selectedItem = nil
        quantityText = ""
    }

    private func addMeal() {
        guard canSaveMeal else { return }
        let items = buildMealItems()
        let foodsMissingMacros = Set(mealItems.compactMap { draft -> String? in
            let info = macrosSummary(for: draft)
            return info.warning != nil ? draft.name : nil
        })

        if !foodsMissingMacros.isEmpty {
            missingMacrosFoods = foodsMissingMacros.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            pendingMealItems = items
            showMissingMacrosAlert = true
            return
        }

        finalizeMealSave(with: items)
    }

    private func finalizeMealSave(with items: [DietItemEntry]) {
        viewModel.addEntry(mealType: mealType, items: items)
        mealItems = []
        quantityText = ""
        itemQuery = ""
        selectedItem = nil
        mealType = Self.defaultMealType(for: Date())
        pendingMealItems = nil
        missingMacrosFoods = []
        showMissingMacrosAlert = false
    }

    private func exportLog() {
        Task {
            let entriesToExport = entriesForExport
            guard !entriesToExport.isEmpty else { return }
            if let url = await viewModel.exportLog(entries: entriesToExport) {
                await MainActor.run {
                    activeSheet = .share(ExportedFile(url: url))
                }
            }
        }
    }

    private var entriesForExport: [DietEntry] {
        if filterRange == nil && filterMealType == nil {
            return viewModel.entries
        }
        return displayedEntries
    }

    private var canExportEntries: Bool {
        !entriesForExport.isEmpty
    }

    private func formattedAmount(for draft: MealItemDraft) -> String {
        "\(formatNumber(draft.amount)) \(draft.unit.symbol)"
    }

    private func buildMealItems() -> [DietItemEntry] {
        mealItems.map { draft in
            let quantityString = formattedAmount(for: draft)
            let macros = draftMacros(from: draft)
            return DietItemEntry(
                name: draft.name,
                quantity: quantityString,
                calories: macros.calories,
                protein: macros.protein,
                carbs: macros.carbs,
                fat: macros.fat
            )
        }
    }

    private func macrosSummary(for draft: MealItemDraft) -> (text: String?, warning: String?) {
        if !draft.hasCatalogEntry {
            return (nil, "Add this food to the catalog to calculate macros")
        }
        let macros = draftMacros(from: draft)
        if let summary = formattedMacros(calories: macros.calories, protein: macros.protein, carbs: macros.carbs, fat: macros.fat) {
            return (summary, nil)
        }
        if !(viewModel.catalogItem(named: draft.name)?.hasMacros ?? false) {
            return (nil, "Macros not set for this food")
        }
        return (nil, nil)
    }

    private func draftMacros(from draft: MealItemDraft) -> (calories: Int?, protein: Int?, carbs: Int?, fat: Int?) {
        if draft.calories != nil || draft.protein != nil || draft.carbs != nil || draft.fat != nil {
            return (draft.calories, draft.protein, draft.carbs, draft.fat)
        }
        if let item = viewModel.catalogItem(named: draft.name) {
            return item.scaledMacros(for: draft.amount)
        }
        return (nil, nil, nil, nil)
    }

    private func formattedMacros(calories: Int?, protein: Int?, carbs: Int?, fat: Int?) -> String? {
        var parts: [String] = []
        if let calories { parts.append("\(calories) kcal") }
        if let protein { parts.append("P \(protein) g") }
        if let carbs { parts.append("C \(carbs) g") }
        if let fat { parts.append("F \(fat) g") }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    private func catalogContains(_ name: String) -> Bool {
        viewModel.catalog.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    private var currentPortionUnit: FoodCatalogItem.PortionUnit {
        if let selectedItem, let item = viewModel.catalogItem(named: selectedItem) {
            return item.unit
        }
        let trimmedQuery = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if let item = viewModel.catalogItem(named: trimmedQuery) {
            return item.unit
        }
        return .grams
    }

    private var amountPlaceholder: String {
        "Amount (\(currentPortionUnit.symbol))"
    }

    private func handleCatalogSave(_ form: CatalogForm) {
        let trimmedName = form.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let rawPortion = Double(form.portionAmount.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 100
        let clampedPortion = rawPortion > 0 ? rawPortion : 100
        let portion = Int(ceil(clampedPortion))
        let item = FoodCatalogItem(
            name: trimmedName,
            portionAmount: portion,
            unit: form.unit,
            calories: Self.parseInt(form.calories),
            protein: Self.parseInt(form.protein),
            carbs: Self.parseInt(form.carbs),
            fat: Self.parseInt(form.fat)
        )
        viewModel.addCatalogItem(item)
        mealItems = mealItems.map { draft in
            guard draft.name.caseInsensitiveCompare(item.name) == .orderedSame else { return draft }
            let scaled = item.scaledMacros(for: draft.amount)
            return MealItemDraft(
                id: draft.id,
                name: draft.name,
                amount: draft.amount,
                unit: item.unit,
                calories: scaled.calories,
                protein: scaled.protein,
                carbs: scaled.carbs,
                fat: scaled.fat,
                hasCatalogEntry: true
            )
        }
        selectedItem = item.name
        itemQuery = item.name
    }

    private func formatNumber(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.1f", rounded)
    }

    private static func parseInt(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = Double(trimmed) else { return nil }
        return Int(ceil(value))
    }
}

#Preview {
    ContentView()
}
