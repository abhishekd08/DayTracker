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

enum MealType: String, Codable, CaseIterable, Identifiable {
    case preWorkout
    case postWorkout
    case lunch
    case eveningMeal
    case dinner
    case extras

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preWorkout: return "Pre-Workout"
        case .postWorkout: return "Post-Workout"
        case .lunch: return "Lunch"
        case .eveningMeal: return "Evening Snacks"
        case .dinner: return "Dinner"
        case .extras: return "Extras"
    }
}
}

struct DietItemEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var quantity: String

    init(id: UUID = UUID(), name: String, quantity: String) {
        self.id = id
        self.name = name
        self.quantity = quantity
    }
}

struct DietEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var mealType: MealType
    var items: [DietItemEntry]

    init(id: UUID = UUID(), date: Date = Date(), mealType: MealType, items: [DietItemEntry]) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.items = items
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var summaryLine: String {
        items.map { "\($0.name) \($0.quantity)" }.joined(separator: ", ")
    }
}
