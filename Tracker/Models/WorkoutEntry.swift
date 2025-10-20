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
    var portionAmount: Int
    var unit: PortionUnit
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?
    var hasMacros: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }

    init(
        id: UUID = UUID(),
        name: String,
        portionAmount: Int = 100,
        unit: PortionUnit = .grams,
        calories: Int? = nil,
        protein: Int? = nil,
        carbs: Int? = nil,
        fat: Int? = nil
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

    private enum CodingKeys: String, CodingKey {
        case id, name, portionAmount, unit, calories, protein, carbs, fat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        portionAmount = try container.decodeIfPresent(Int.self, forKey: .portionAmount)
            ?? Int(ceil(try container.decodeIfPresent(Double.self, forKey: .portionAmount) ?? 100))
        unit = try container.decode(PortionUnit.self, forKey: .unit)
        calories = FoodCatalogItem.decodeInt(from: container, key: .calories)
        protein = FoodCatalogItem.decodeInt(from: container, key: .protein)
        carbs = FoodCatalogItem.decodeInt(from: container, key: .carbs)
        fat = FoodCatalogItem.decodeInt(from: container, key: .fat)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(portionAmount, forKey: .portionAmount)
        try container.encode(unit, forKey: .unit)
        try container.encodeIfPresent(calories, forKey: .calories)
        try container.encodeIfPresent(protein, forKey: .protein)
        try container.encodeIfPresent(carbs, forKey: .carbs)
        try container.encodeIfPresent(fat, forKey: .fat)
    }

    private static func decodeInt(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int? {
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let doubleValue = try? container.decode(Double.self, forKey: key) {
            return Int(ceil(doubleValue))
        }
        return nil
    }

    func scaledMacros(for amount: Double) -> (calories: Int?, protein: Int?, carbs: Int?, fat: Int?) {
        guard portionAmount > 0 else {
            return (calories, protein, carbs, fat)
        }
        let scale = amount / Double(portionAmount)
        return (
            calories.map { Int(ceil(Double($0) * scale)) },
            protein.map { Int(ceil(Double($0) * scale)) },
            carbs.map { Int(ceil(Double($0) * scale)) },
            fat.map { Int(ceil(Double($0) * scale)) }
        )
    }
}

struct DietItemEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var quantity: String
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: String,
        calories: Int? = nil,
        protein: Int? = nil,
        carbs: Int? = nil,
        fat: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, quantity, calories, protein, carbs, fat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(String.self, forKey: .quantity)
        calories = DietItemEntry.decodeInt(from: container, key: .calories)
        protein = DietItemEntry.decodeInt(from: container, key: .protein)
        carbs = DietItemEntry.decodeInt(from: container, key: .carbs)
        fat = DietItemEntry.decodeInt(from: container, key: .fat)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(quantity, forKey: .quantity)
        try container.encodeIfPresent(calories, forKey: .calories)
        try container.encodeIfPresent(protein, forKey: .protein)
        try container.encodeIfPresent(carbs, forKey: .carbs)
        try container.encodeIfPresent(fat, forKey: .fat)
    }

    private static func decodeInt(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int? {
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let doubleValue = try? container.decode(Double.self, forKey: key) {
            return Int(ceil(doubleValue))
        }
        return nil
    }

    var hasMacros: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }

    var macrosSummary: String? {
        var components: [String] = []
        if let calories {
            components.append("\(calories) kcal")
        }
        if let protein {
            components.append("P \(protein) g")
        }
        if let carbs {
            components.append("C \(carbs) g")
        }
        if let fat {
            components.append("F \(fat) g")
        }
        return components.isEmpty ? nil : components.joined(separator: " • ")
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

    func exportDictionary() -> [String: Any] {
        [
            "mealType": mealType.displayName,
            "date": ISO8601DateFormatter().string(from: date),
            "items": items.map { item -> [String: Any] in
                var dict: [String: Any] = [
                    "name": item.name,
                    "quantity": item.quantity
                ]
                if let calories = item.calories { dict["calories"] = calories }
                if let protein = item.protein { dict["protein"] = protein }
                if let carbs = item.carbs { dict["carbs"] = carbs }
                if let fat = item.fat { dict["fat"] = fat }
                return dict
            }
        ]
    }
}
