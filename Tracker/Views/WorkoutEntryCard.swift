import SwiftUI

struct WorkoutEntryCard: View {
    let entry: WorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.exerciseName)
                    .font(.headline)
                Spacer()
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label("\(entry.sets)x\(entry.reps)", systemImage: "repeat")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label(entry.formattedWeight, systemImage: entry.hasWeight ? "dumbbell.fill" : "figure.walk")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    WorkoutEntryCard(
        entry: WorkoutEntry(
            exerciseName: "Bench Press",
            reps: 8,
            sets: 4,
            weight: 60
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

struct DietEntryCard: View {
    let entry: DietEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.mealType.displayName)
                    .font(.headline)
                Spacer()
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.items) { item in
                    HStack {
                        Text(item.name)
                            .font(.subheadline)
                        Spacer()
                        Text(item.quantity)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview("Diet Entry") {
    DietEntryCard(
        entry: DietEntry(
            mealType: .lunch,
            items: [
                DietItemEntry(name: "Paneer", quantity: "80 g"),
                DietItemEntry(name: "Rice", quantity: "120 g")
            ]
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
