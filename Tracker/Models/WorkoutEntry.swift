import Foundation

struct WorkoutEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var exerciseName: String
    var reps: Int
    var sets: Int
    var weight: Double?

    init(id: UUID = UUID(), date: Date = Date(), exerciseName: String, reps: Int, sets: Int, weight: Double?) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
        self.reps = reps
        self.sets = sets
        self.weight = weight
    }

    var hasWeight: Bool {
        weight != nil
    }

    var formattedWeight: String {
        guard let weight else { return "Bodyweight" }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        formatter.locale = Locale.current
        return (formatter.string(from: NSNumber(value: weight)) ?? "\(weight)") + " kg"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
