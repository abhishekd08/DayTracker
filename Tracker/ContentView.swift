import SwiftUI

struct ContentView: View {
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
        NavigationStack {
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

#Preview {
    ContentView()
}
