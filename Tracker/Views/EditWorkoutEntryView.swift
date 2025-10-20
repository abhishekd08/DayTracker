import SwiftUI

struct EditWorkoutEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entry: WorkoutEntry
    @State private var weightText: String
    @FocusState private var focusedField: Field?

    let catalog: [String]
    let onSave: (WorkoutEntry) -> Void
    let onDelete: (WorkoutEntry) -> Void

    private enum Field: Hashable {
        case weight
    }

    init(entry: WorkoutEntry, catalog: [String], onSave: @escaping (WorkoutEntry) -> Void, onDelete: @escaping (WorkoutEntry) -> Void) {
        _entry = State(initialValue: entry)
        if let weight = entry.weight {
            _weightText = State(initialValue: String(weight))
        } else {
            _weightText = State(initialValue: "")
        }
        self.catalog = catalog
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    Picker("Name", selection: $entry.exerciseName) {
                        ForEach(catalog, id: \.self) { name in
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

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
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
        entry: WorkoutEntry(exerciseName: "Bench Press", reps: 8, sets: 4, weight: 60),
        catalog: ExerciseCatalog.exercises
    ) { _ in } onDelete: { _ in }
}

// MARK: - EditDietEntryView

struct EditDietEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entry: DietEntry
    @State private var items: [DietItemEntry]
    @FocusState private var isMealFieldFocused: Bool

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
                        ItemRow(item: $item, isMealFieldFocused: $isMealFieldFocused)
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isMealFieldFocused = false }
                }
            }
        }
    }

    private var canSave: Bool {
        guard !items.isEmpty else { return false }
        return items.allSatisfy {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !$0.quantity.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func saveChanges() {
        guard canSave else { return }
        entry.items = items
        entry.date = Date()
        onSave(entry)
        dismiss()
    }
}

// MARK: - ItemRow Subview

private struct ItemRow: View {
    @Binding var item: DietItemEntry
    @FocusState.Binding var isMealFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Food name", text: $item.name)
                .textInputAutocapitalization(.words)
                .focused($isMealFieldFocused)
                .textFieldStyle(.roundedBorder)

            ReadOnlyValueBox(title: "Quantity", value: quantityDisplay(for: item.quantity))

            Text("Macros")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ReadOnlyValueBox(title: "Calories", value: macroDisplay(for: item.calories, unit: "kcal"))
                ReadOnlyValueBox(title: "Protein", value: macroDisplay(for: item.protein, unit: "g"))
            }

            HStack(spacing: 12) {
                ReadOnlyValueBox(title: "Carbs", value: macroDisplay(for: item.carbs, unit: "g"))
                ReadOnlyValueBox(title: "Fat", value: macroDisplay(for: item.fat, unit: "g"))
            }
        }
    }

    private func macroDisplay(for value: Int?, unit: String) -> String {
        guard let value else { return "—" }
        return unit.isEmpty ? "\(value)" : "\(value) \(unit)"
    }

    private func quantityDisplay(for value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
    }
}

// MARK: - Preview

#Preview("Diet Edit") {
    EditDietEntryView(
        entry: DietEntry(
            mealType: .dinner,
            items: [DietItemEntry(name: "Paneer", quantity: "100 g", calories: 180, protein: 18, carbs: 6, fat: 10)]
        )
    ) { _ in } onDelete: { _ in }
}

// MARK: - ReadOnlyValueBox

private struct ReadOnlyValueBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary, lineWidth: 1)
                )
        }
    }
}
