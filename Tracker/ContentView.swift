
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                NavigationLink {
                    WorkoutLogView()
                } label: {
                    selectionCard(title: "Workout", subtitle: "Log sets, reps, and weights", systemImage: "dumbbell.fill")
                }

                NavigationLink {
                    DietLogView()
                } label: {
                    selectionCard(title: "Diet", subtitle: "Track meals and portions", systemImage: "fork.knife")
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Day Tracker")
            .background(Color(.systemGroupedBackground))
        }
    }

    private func selectionCard(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
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
    @State private var filterDate: Date?
    @FocusState private var focusedField: Field?

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

    private var filteredExercises: [String] {
        ExerciseCatalog.matching(exerciseQuery)
    }

    private var displayedEntries: [WorkoutEntry] {
        guard let filterDate else { return viewModel.entries }
        return viewModel.entries.filter { Calendar.current.isDate($0.date, inSameDayAs: filterDate) }
    }

    private var filterDescription: String? {
        guard let filterDate else { return nil }
        return Self.filterFormatter.string(from: filterDate)
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
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportLog()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.entries.isEmpty)
                .accessibilityLabel("Export workouts JSON")
            }
        }
        .sheet(item: $activeSheet) { destination in
            switch destination {
            case .edit(let entry):
                EditWorkoutEntryView(entry: entry) { updatedEntry in
                    viewModel.updateEntry(updatedEntry)
                } onDelete: { entryToDelete in
                    viewModel.deleteEntry(entryToDelete)
                }
            case .filter:
                DateFilterSheet(selectedDate: $filterDate)
            case .share(let file):
                ShareSheet(activityItems: [file.url]) {
                    Task { @MainActor in
                        try? FileManager.default.removeItem(at: file.url)
                        activeSheet = nil
                    }
                }
            }
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
                TextField("Search exercise", text: $exerciseQuery)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: exerciseQuery, initial: false) { _, newValue in
                        if ExerciseCatalog.exercises.contains(where: { $0.caseInsensitiveCompare(newValue) == .orderedSame }) {
                            selectedExercise = ExerciseCatalog.exercises.first { $0.caseInsensitiveCompare(newValue) == .orderedSame }
                        } else {
                            selectedExercise = nil
                        }
                    }

                if !filteredExercises.isEmpty {
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
                            }
                        }
                    }
                    .frame(maxHeight: 140)
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
                        Text("No workouts match this date")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Clear Filter") {
                            filterDate = nil
                        }
                        .buttonStyle(.borderless)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(displayedEntries) { entry in
                        Button {
                            activeSheet = .edit(entry)
                        } label: {
                            WorkoutEntryCard(entry: entry)
                        }
                    }
                }
            }
        }
    }

    private var filterButton: some View {
        Button {
            activeSheet = .filter
        } label: {
            Image(systemName: filterDate == nil ? "calendar" : "calendar.circle.fill")
                .imageScale(.medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(filterDate == nil ? Color.primary : Color.accentColor)
        }
        .accessibilityLabel(filterDate == nil ? "Filter history" : "Change date filter")
        .buttonStyle(.plain)
    }

    private func exportLog() {
        Task {
            if let url = await viewModel.exportLog() {
                await MainActor.run {
                    activeSheet = .share(ExportedFile(url: url))
                }
            }
        }
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
    }
}

private struct DietLogView: View {
    @StateObject private var viewModel = DietViewModel()

    @State private var mealType: MealType = .lunch
    @State private var itemQuery = ""
    @State private var selectedItem: String?
    @State private var quantityText = ""
    @State private var mealItems: [MealItemDraft] = []
    @State private var activeSheet: ActiveSheet?
    @State private var filterDate: Date?
    @State private var filterMealType: MealType?

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
        var quantity: String

        init(id: UUID = UUID(), name: String, quantity: String) {
            self.id = id
            self.name = name
            self.quantity = quantity
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var filteredCatalog: [String] {
        let trimmed = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return viewModel.catalog }
        return viewModel.catalog.filter { $0.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    private var displayedEntries: [DietEntry] {
        viewModel.entries.filter { entry in
            let matchesDate = filterDate.map { Calendar.current.isDate(entry.date, inSameDayAs: $0) } ?? true
            let matchesMeal = filterMealType.map { entry.mealType == $0 } ?? true
            return matchesDate && matchesMeal
        }
    }

    private var filterDescription: String {
        var components: [String] = []
        if let filterDate {
            components.append(Self.dateFormatter.string(from: filterDate))
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
        let trimmedQuantity = quantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let selectedItem {
            return !trimmedQuantity.isEmpty && !mealItems.contains(where: { $0.name.caseInsensitiveCompare(selectedItem) == .orderedSame })
        }
        let trimmedQuery = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedQuery.isEmpty && !trimmedQuantity.isEmpty && !mealItems.contains(where: { $0.name.caseInsensitiveCompare(trimmedQuery) == .orderedSame })
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
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportLog()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.entries.isEmpty)
                .accessibilityLabel("Export meals JSON")
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
                DietFilterSheet(selectedDate: $filterDate, selectedMealType: $filterMealType)
            case .share(let file):
                ShareSheet(activityItems: [file.url]) {
                    Task { @MainActor in
                        try? FileManager.default.removeItem(at: file.url)
                        activeSheet = nil
                    }
                }
            }
        }
        .alert("Error", isPresented: errorAlertBinding, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .task {
            viewModel.load()
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
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Search or add food", text: $itemQuery)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: itemQuery, initial: false) { _, newValue in
                        if viewModel.catalog.contains(where: { $0.caseInsensitiveCompare(newValue) == .orderedSame }) {
                            selectedItem = viewModel.catalog.first { $0.caseInsensitiveCompare(newValue) == .orderedSame }
                        } else {
                            selectedItem = nil
                        }
                    }

                if !filteredCatalog.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredCatalog, id: \.self) { name in
                                Button {
                                    selectedItem = name
                                    itemQuery = name
                                } label: {
                                    HStack {
                                        Text(name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedItem == name {
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
                                        if selectedItem == name {
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

                let trimmedQuery = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedQuery.isEmpty && !viewModel.catalog.contains(where: { $0.caseInsensitiveCompare(trimmedQuery) == .orderedSame }) {
                    Button {
                        viewModel.addCatalogItem(named: trimmedQuery)
                        selectedItem = trimmedQuery
                        itemQuery = trimmedQuery
                    } label: {
                        Label("Add \(trimmedQuery) to catalog", systemImage: "plus")
                            .font(.subheadline)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Quantity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. 80 g", text: $quantityText)
                    .textFieldStyle(.roundedBorder)
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
                        HStack {
                            VStack(alignment: .leading) {
                                Text(draft.name)
                                    .font(.body)
                                Text(draft.quantity)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
                            filterDate = nil
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
                        Button {
                            activeSheet = .edit(entry)
                        } label: {
                            DietEntryCard(entry: entry)
                        }
                    }
                }
            }
        }
    }

    private var filterButton: some View {
        Button {
            activeSheet = .filter
        } label: {
            Image(systemName: filterDate == nil && filterMealType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .imageScale(.medium)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(filterDate == nil && filterMealType == nil ? Color.primary : Color.accentColor)
        }
        .accessibilityLabel("Filter meals")
        .buttonStyle(.plain)
    }

    private func addItemToMeal() {
        let quantity = quantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quantity.isEmpty else { return }
        let name: String
        if let selectedItem {
            name = selectedItem
        } else {
            name = itemQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !name.isEmpty else { return }
        mealItems.append(MealItemDraft(name: name, quantity: quantity))
        itemQuery = ""
        selectedItem = nil
        quantityText = ""
    }

    private func addMeal() {
        guard canSaveMeal else { return }
        let items = mealItems.map { DietItemEntry(name: $0.name, quantity: $0.quantity) }
        viewModel.addEntry(mealType: mealType, items: items)
        mealItems = []
        quantityText = ""
        itemQuery = ""
        selectedItem = nil
    }

    private func exportLog() {
        Task {
            if let url = await viewModel.exportLog() {
                await MainActor.run {
                    activeSheet = .share(ExportedFile(url: url))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
