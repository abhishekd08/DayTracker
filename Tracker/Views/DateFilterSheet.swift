import SwiftUI

struct DateFilterSheet: View {
    @Binding var selectedDate: Date?
    @State private var proposedDate: Date
    @Environment(\.dismiss) private var dismiss

    init(selectedDate: Binding<Date?>) {
        _selectedDate = selectedDate
        _proposedDate = State(initialValue: selectedDate.wrappedValue ?? Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker("Filter Date", selection: $proposedDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)

                if selectedDate != nil {
                    Button(role: .destructive) {
                        selectedDate = nil
                        dismiss()
                    } label: {
                        Label("Clear Filter", systemImage: "xmark.circle")
                    }
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Filter by Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        selectedDate = proposedDate
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DateFilterSheet(selectedDate: .constant(Date()))
}

struct DietFilterSheet: View {
    @Binding var selectedDate: Date?
    @Binding var selectedMealType: MealType?
    @State private var proposedDate: Date
    @State private var proposedMealType: MealType?
    @Environment(\.dismiss) private var dismiss

    init(selectedDate: Binding<Date?>, selectedMealType: Binding<MealType?>) {
        _selectedDate = selectedDate
        _selectedMealType = selectedMealType
        _proposedDate = State(initialValue: selectedDate.wrappedValue ?? Date())
        _proposedMealType = State(initialValue: selectedMealType.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("", selection: $proposedDate, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.graphical)

                    if selectedDate != nil {
                        Button("Clear Date", role: .destructive) {
                            selectedDate = nil
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
                        selectedDate = proposedDate
                        selectedMealType = proposedMealType
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("Diet Filter") {
    DietFilterSheet(selectedDate: .constant(Date()), selectedMealType: .constant(.lunch))
}
