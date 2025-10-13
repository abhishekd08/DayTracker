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
