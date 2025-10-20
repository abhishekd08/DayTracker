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

struct FoodCatalogItem: Identifiable, Codable, Equatable {
    enum PortionUnit: String, Codable, CaseIterable, Identifiable {
        case grams
        case milliliters

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .grams:
                return "Grams (g)"
            case .milliliters:
                return "Milliliters (mL)"
            }
        }

        var symbol: String {
            switch self {
            case .grams:
                return "g"
            case .milliliters:
                return "mL"
            }
        }
    }

    let id: UUID
    var name: String
    var portionAmount: Double
    var unit: PortionUnit
    var calories: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var hasMacros: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }

    init(
        id: UUID = UUID(),
        name: String,
        portionAmount: Double = 100,
        unit: PortionUnit = .grams,
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.portionAmount = portionAmount
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    func scaledMacros(for amount: Double) -> (calories: Double?, protein: Double?, carbs: Double?, fat: Double?) {
        guard portionAmount > 0 else {
            return (calories, protein, carbs, fat)
        }
        let scale = amount / portionAmount
        return (
            calories.map { $0 * scale },
            protein.map { $0 * scale },
            carbs.map { $0 * scale },
            fat.map { $0 * scale }
        )
    }
}

struct DietItemEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var quantity: String
    var calories: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: String,
        calories: Double? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    var hasMacros: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }

    var macrosSummary: String? {
        var components: [String] = []
        if let calories {
            components.append(Self.format(calories) + " kcal")
        }
        if let protein {
            components.append("P " + Self.format(protein) + " g")
        }
        if let carbs {
            components.append("C " + Self.format(carbs) + " g")
        }
        if let fat {
            components.append("F " + Self.format(fat) + " g")
        }
        return components.isEmpty ? nil : components.joined(separator: " • ")
    }

    private static func format(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.1f", rounded)
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
        items.map { item in
            var components: [String] = ["\(item.name) \(item.quantity)"]
            if let summary = item.macrosSummary {
                components.append("(\(summary))")
            }
            return components.joined(separator: " ")
        }.joined(separator: ", ")
    }
}
