enum ExerciseCatalog {
    static let exercises: [String] = [
        "Back Squat",
        "Front Squat",
        "Deadlift",
        "Romanian Deadlift",
        "Bench Press",
        "Incline Bench Press",
        "Overhead Press",
        "Push Up",
        "Pull Up",
        "Bent Over Row",
        "Lat Pulldown",
        "Seated Row",
        "Biceps Curl",
        "Triceps Extension",
        "Lateral Raise",
        "Leg Press",
        "Leg Extension",
        "Leg Curl",
        "Hip Thrust",
        "Calf Raise",
        "Plank",
        "Russian Twist",
        "Mountain Climber",
        "Burpee"
    ]

    static func matching(_ query: String) -> [String] {
        guard !query.isEmpty else { return exercises }
        return exercises.filter { $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }
}
