import SwiftUI

struct EditWorkoutEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entry: WorkoutEntry
    @State private var weightText: String
    @FocusState private var focusedField: Field?

    let onSave: (WorkoutEntry) -> Void
    let onDelete: (WorkoutEntry) -> Void

    private enum Field: Hashable {
        case weight
    }

    init(entry: WorkoutEntry, onSave: @escaping (WorkoutEntry) -> Void, onDelete: @escaping (WorkoutEntry) -> Void) {
        _entry = State(initialValue: entry)
        if let weight = entry.weight {
            _weightText = State(initialValue: String(weight))
        } else {
            _weightText = State(initialValue: "")
        }
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    Picker("Name", selection: $entry.exerciseName) {
                        ForEach(ExerciseCatalog.exercises, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }

                Section("Volume") {
                    Stepper(value: $entry.sets, in: 1...50) {
                        Text("Sets: \(entry.sets)")
                    }

                    Stepper(value: $entry.reps, in: 1...200) {
                        Text("Reps: \(entry.reps)")
                    }
                }

                Section("Load") {
                    TextField("Weight (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)

                    if weightText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Leave blank for bodyweight exercises")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        onDelete(entry)
                        dismiss()
                    } label: {
                        Text("Delete Entry")
                    }
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        guard !entry.exerciseName.isEmpty else { return false }
        guard entry.reps > 0, entry.sets > 0 else { return false }
        let trimmed = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Double(trimmed) != nil
    }

    private func saveChanges() {
        guard canSave else { return }
        let trimmed = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.weight = trimmed.isEmpty ? nil : Double(trimmed)
        entry.date = Date()
        onSave(entry)
        dismiss()
    }
}

#Preview {
    EditWorkoutEntryView(
        entry: WorkoutEntry(exerciseName: "Bench Press", reps: 8, sets: 4, weight: 60)
    ) { _ in } onDelete: { _ in }
}

struct EditDietEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entry: DietEntry
    @State private var items: [DietItemEntry]

    let onSave: (DietEntry) -> Void
    let onDelete: (DietEntry) -> Void

    init(entry: DietEntry, onSave: @escaping (DietEntry) -> Void, onDelete: @escaping (DietEntry) -> Void) {
        _entry = State(initialValue: entry)
        _items = State(initialValue: entry.items)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal") {
                    Picker("Type", selection: $entry.mealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Items") {
                    ForEach($items) { $item in
                        VStack(alignment: .leading) {
                            TextField("Food name", text: $item.name)
                                .textInputAutocapitalization(.words)
                            TextField("Quantity", text: $item.quantity)
                                .textInputAutocapitalization(.sentences)
                                .keyboardType(.default)
                        }
                    }
                    .onDelete { indices in
                        items.remove(atOffsets: indices)
                    }

                    Button {
                        items.append(DietItemEntry(name: "", quantity: ""))
                    } label: {
                        Label("Add Item", systemImage: "plus.circle")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        onDelete(entry)
                        dismiss()
                    } label: {
                        Text("Delete Meal")
                    }
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        guard !items.isEmpty else { return false }
        return items.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty && !$0.quantity.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func saveChanges() {
        guard canSave else { return }
        entry.items = items
        entry.date = Date()
        onSave(entry)
        dismiss()
    }
}

#Preview("Diet Edit") {
    EditDietEntryView(
        entry: DietEntry(
            mealType: .dinner,
            items: [DietItemEntry(name: "Paneer", quantity: "100 g")]
        )
    ) { _ in } onDelete: { _ in }
}
