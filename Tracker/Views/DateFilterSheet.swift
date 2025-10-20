import SwiftUI

struct DateRange: Equatable {
    var start: Date
    var end: Date
}

struct DateRangeFilterSheet: View {
    @Binding var selectedRange: DateRange?
    @State private var proposedStart: Date
    @State private var proposedEnd: Date
    @Environment(\.dismiss) private var dismiss

    init(selectedRange: Binding<DateRange?>) {
        _selectedRange = selectedRange
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let range = selectedRange.wrappedValue {
            _proposedStart = State(initialValue: calendar.startOfDay(for: range.start))
            _proposedEnd = State(initialValue: calendar.startOfDay(for: range.end))
        } else {
            _proposedStart = State(initialValue: today)
            _proposedEnd = State(initialValue: today)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Start Date") {
                    DatePicker(
                        "Start",
                        selection: $proposedStart,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }

                Section("End Date") {
                    DatePicker(
                        "End",
                        selection: $proposedEnd,
                        in: proposedStart...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }

                if selectedRange != nil {
                    Section {
                        Button(role: .destructive) {
                            selectedRange = nil
                            dismiss()
                        } label: {
                            Label("Clear Filter", systemImage: "xmark.circle")
                        }
                    }
                }
            }
            .navigationTitle("Filter by Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        let calendar = Calendar.current
                        let normalizedStart = calendar.startOfDay(for: proposedStart)
                        let endStart = calendar.startOfDay(for: proposedEnd)
                        let normalizedEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: endStart) ?? endStart
                        selectedRange = DateRange(start: normalizedStart, end: normalizedEnd)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DateRangeFilterSheet(selectedRange: .constant(DateRange(start: Date(), end: Date())))
}

struct DietFilterSheet: View {
    @Binding var selectedRange: DateRange?
    @Binding var selectedMealType: MealType?
    @State private var proposedStart: Date
    @State private var proposedEnd: Date
    @State private var proposedMealType: MealType?
    @Environment(\.dismiss) private var dismiss

    init(selectedRange: Binding<DateRange?>, selectedMealType: Binding<MealType?>) {
        _selectedRange = selectedRange
        _selectedMealType = selectedMealType
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let range = selectedRange.wrappedValue {
            _proposedStart = State(initialValue: calendar.startOfDay(for: range.start))
            _proposedEnd = State(initialValue: calendar.startOfDay(for: range.end))
        } else {
            _proposedStart = State(initialValue: today)
            _proposedEnd = State(initialValue: today)
        }
        _proposedMealType = State(initialValue: selectedMealType.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Start Date") {
                    DatePicker(
                        "Start",
                        selection: $proposedStart,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                }

                Section("End Date") {
                    DatePicker(
                        "End",
                        selection: $proposedEnd,
                        in: proposedStart...,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                }

                if selectedRange != nil {
                    Section {
                        Button("Clear Date Range", role: .destructive) {
                            selectedRange = nil
                            dismiss()
                        }
                    }
                }

                Section("Meal Type") {
                    Picker("Type", selection: Binding(get: {
                        proposedMealType
                    }, set: { newValue in
                        proposedMealType = newValue
                    })) {
                        Text("All").tag(MealType?.none)
                        ForEach(MealType.allCases) { type in
                            Text(type.displayName).tag(Optional(type))
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filter Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        let calendar = Calendar.current
                        let normalizedStart = calendar.startOfDay(for: proposedStart)
                        let endStart = calendar.startOfDay(for: proposedEnd)
                        let normalizedEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: endStart) ?? endStart
                        selectedRange = DateRange(start: normalizedStart, end: normalizedEnd)
                        selectedMealType = proposedMealType
                        dismiss()
                    }
                }
            }
            .onChange(of: proposedStart) { _, newValue in
                if proposedEnd < newValue {
                    proposedEnd = newValue
                }
            }
        }
    }
}

#Preview("Diet Filter") {
    DietFilterSheet(selectedRange: .constant(DateRange(start: Date(), end: Date())), selectedMealType: .constant(.lunch))
}
