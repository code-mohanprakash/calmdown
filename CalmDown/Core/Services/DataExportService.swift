import Foundation
import SwiftData
import SwiftUI

// MARK: - Export DTO structs (Codable, separate from @Model)

struct ExportFile: Codable {
    let exportDate:       Date
    let appVersion:       String
    let hrvReadings:      [HRVReadingDTO]
    let moodEntries:      [MoodEntryDTO]
    let hydrationEntries: [HydrationEntryDTO]
    let settings:         SettingsDTO
}

struct HRVReadingDTO: Codable {
    let id:        String
    let timestamp: Date
    let value:     Double
    let heartRate: Double?
}

struct MoodEntryDTO: Codable {
    let id:        String
    let timestamp: Date
    let emotion:   String
    let emoji:     String
    let note:      String
}

struct HydrationEntryDTO: Codable {
    let id:          String
    let timestamp:   Date
    let waterMl:     Int
    let caffeineMg:  Int
}

struct SettingsDTO: Codable {
    let userName:               String
    let stressAlertsEnabled:    Bool
    let hydrationRemindersEnabled: Bool
}

// MARK: - Service

struct DataExportService {

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // ── Export ────────────────────────────────────────────────────────────────

    static func buildExportFile(context: ModelContext) throws -> ExportFile {
        let hrv    = try context.fetch(FetchDescriptor<HRVReading>())
        let moods  = try context.fetch(FetchDescriptor<MoodEntry>())
        let hydro  = try context.fetch(FetchDescriptor<HydrationEntry>())

        let defaults = UserDefaults.standard

        return ExportFile(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            hrvReadings: hrv.map {
                HRVReadingDTO(id: $0.id.uuidString, timestamp: $0.timestamp, value: $0.value, heartRate: $0.heartRate)
            },
            moodEntries: moods.map {
                MoodEntryDTO(id: $0.id.uuidString, timestamp: $0.timestamp, emotion: $0.emotion, emoji: $0.emoji, note: $0.note)
            },
            hydrationEntries: hydro.map {
                HydrationEntryDTO(id: $0.id.uuidString, timestamp: $0.timestamp, waterMl: $0.waterMl, caffeineMg: $0.caffeineMg)
            },
            settings: SettingsDTO(
                userName: defaults.string(forKey: "userName") ?? "",
                stressAlertsEnabled: defaults.bool(forKey: "stressAlertsEnabled"),
                hydrationRemindersEnabled: defaults.bool(forKey: "hydrationRemindersEnabled")
            )
        )
    }

    /// Serialise to a temp file and return its URL (ready for ShareSheet)
    static func exportToURL(context: ModelContext) throws -> URL {
        let export = try buildExportFile(context: context)

        let encoder = JSONEncoder()
        encoder.outputFormatting    = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(export)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())

        let fileName = "calmdown-backup-\(dateStr).json"
        let tempURL  = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL, options: .atomic)

        // Record backup date
        UserDefaults.standard.set(Date(), forKey: "lastBackupDate")

        return tempURL
    }

    // ── Import ────────────────────────────────────────────────────────────────

    @MainActor
    static func importFromURL(_ url: URL, context: ModelContext) throws -> ImportResult {
        let data    = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file    = try decoder.decode(ExportFile.self, from: data)

        var inserted = (hrv: 0, mood: 0, hydration: 0)

        // Existing IDs to avoid duplicates
        let existingHRV   = Set((try? context.fetch(FetchDescriptor<HRVReading>()))?.map(\.id.uuidString) ?? [])
        let existingMood  = Set((try? context.fetch(FetchDescriptor<MoodEntry>()))?.map(\.id.uuidString) ?? [])
        let existingHydro = Set((try? context.fetch(FetchDescriptor<HydrationEntry>()))?.map(\.id.uuidString) ?? [])

        for dto in file.hrvReadings where !existingHRV.contains(dto.id) {
            context.insert(HRVReading(
                id: UUID(uuidString: dto.id) ?? UUID(),
                timestamp: dto.timestamp,
                value: dto.value,
                heartRate: dto.heartRate
            ))
            inserted.hrv += 1
        }

        for dto in file.moodEntries where !existingMood.contains(dto.id) {
            context.insert(MoodEntry(
                id: UUID(uuidString: dto.id) ?? UUID(),
                timestamp: dto.timestamp,
                emotion: dto.emotion,
                emoji: dto.emoji,
                note: dto.note
            ))
            inserted.mood += 1
        }

        for dto in file.hydrationEntries where !existingHydro.contains(dto.id) {
            context.insert(HydrationEntry(
                id: UUID(uuidString: dto.id) ?? UUID(),
                timestamp: dto.timestamp,
                waterMl: dto.waterMl,
                caffeineMg: dto.caffeineMg
            ))
            inserted.hydration += 1
        }

        try context.save()

        // Restore settings
        let defaults = UserDefaults.standard
        if !file.settings.userName.isEmpty {
            defaults.set(file.settings.userName, forKey: "userName")
        }

        UserDefaults.standard.set(Date(), forKey: "lastBackupDate")

        return ImportResult(
            exportedOn: file.exportDate,
            hrvCount: inserted.hrv,
            moodCount: inserted.mood,
            hydrationCount: inserted.hydration
        )
    }

    // ── Backup state ──────────────────────────────────────────────────────────

    static var lastBackupDate: Date? {
        UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    }

    /// Returns true if user has data but hasn't backed up in > 7 days
    static func shouldNudgeBackup(context: ModelContext) -> Bool {
        guard let count = try? context.fetchCount(FetchDescriptor<MoodEntry>()),
              count > 0 || ((try? context.fetchCount(FetchDescriptor<HydrationEntry>())) ?? 0) > 0
        else { return false }

        if let last = lastBackupDate {
            return Date().timeIntervalSince(last) > 7 * 24 * 3600
        }
        return true  // never backed up
    }
}

// MARK: - Result model

struct ImportResult {
    let exportedOn:    Date
    let hrvCount:      Int
    let moodCount:     Int
    let hydrationCount: Int

    var summary: String {
        "Restored \(hrvCount) HRV readings, \(moodCount) mood logs, \(hydrationCount) hydration entries."
    }
}
