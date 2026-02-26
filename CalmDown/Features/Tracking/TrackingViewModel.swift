import Foundation
import SwiftData

@MainActor
final class TrackingViewModel: ObservableObject {
    @Published var todayWaterMl:    Int = 0
    @Published var todayCaffeineMg: Int = 0
    @Published var selectedEmotions: Set<String> = []
    @Published var moodNote:         String = ""
    @Published var energyLevel:      Int = 3           // 1-5
    @Published var selectedTriggers: Set<String> = []
    @Published var recentMoods: [MoodEntry] = []

    let waterGoalMl    = 2000
    let caffeineGoalMg = 400

    static let triggerOptions = [
        "Work", "Sleep", "Family", "Relationship",
        "Health", "Money", "Traffic", "Food", "Exercise", "Social"
    ]

    var waterProgress: Double { Double(todayWaterMl) / Double(waterGoalMl) }

    // MARK: - Load today's totals
    func loadTodayTotals(context: ModelContext) {
        let today      = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<HydrationEntry>(
            predicate: #Predicate { $0.timestamp >= today }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        todayWaterMl    = entries.reduce(0) { $0 + $1.waterMl }
        todayCaffeineMg = entries.reduce(0) { $0 + $1.caffeineMg }
    }

    // MARK: - Water
    func addWater(_ ml: Int, context: ModelContext) {
        let entry = HydrationEntry(waterMl: ml, caffeineMg: 0)
        context.insert(entry)
        try? context.save()
        todayWaterMl += ml
    }

    // MARK: - Caffeine
    func addCaffeine(_ mg: Int, context: ModelContext) {
        let entry = HydrationEntry(waterMl: 0, caffeineMg: mg)
        context.insert(entry)
        try? context.save()
        todayCaffeineMg += mg
    }

    // MARK: - Mood
    func toggleEmotion(_ name: String) {
        if selectedEmotions.contains(name) {
            selectedEmotions.remove(name)
        } else {
            selectedEmotions.insert(name)
        }
    }

    func toggleTrigger(_ trigger: String) {
        if selectedTriggers.contains(trigger) {
            selectedTriggers.remove(trigger)
        } else {
            selectedTriggers.insert(trigger)
        }
    }

    // MARK: - Recent moods
    func loadRecentMoods(context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        recentMoods = (try? context.fetch(descriptor)) ?? []
    }

    func saveMood(context: ModelContext) {
        let triggersString = selectedTriggers.sorted().joined(separator: ",")
        for name in selectedEmotions {
            if let emotion = Emotion.catalog.first(where: { $0.name == name }) {
                let entry = MoodEntry(
                    emotion: emotion.name,
                    emoji: emotion.emoji,
                    note: moodNote,
                    energyLevel: energyLevel,
                    triggers: triggersString
                )
                context.insert(entry)
            }
        }
        try? context.save()
        selectedEmotions.removeAll()
        selectedTriggers.removeAll()
        moodNote = ""
        energyLevel = 3
    }
}
