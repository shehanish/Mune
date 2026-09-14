//
//  HomeViewModel.swift
//  Mune
//
//  Created by Shehani Hansika on 11.05.26.
//


import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    //Text note user can type
    var notesText: String = ""
    //AI Strings
    var todayInsightText: String?
    var isGeneratingTodayInsight: Bool = false
    var hasCheckedInToday: Bool = false
    
    private let moodRepo: any MoodRepository
    private let aiService: any AIInsightService
    private let userID: String
    private let userName: String
    private let calendar: Calendar

    // Ephemeral UI state
    var selectedMoods: Set<String> = []
    var isSavingCheckIn: Bool = false
    var activeCrisisSignals: Set<CrisisSignal> = []
    var crisisSupportMessage: String?

    // Weekly Home summary (kept lean for Track; extra fields feed chat context)
    var weeklyMoodCounts: [MoodCount] = []
    var weeklyCheckInCount: Int = 0
    var weeklyNoteCount: Int = 0
    var weeklySummaryLine: String = ""
    var weeklyHelpfulPatternText: String = ""
    var weeklyWarningText: String?
    var weeklyTrendBars: [WeeklyTrendBar] = []
    var latestCheckInText: String = "No check-ins yet. That’s okay."
    var weeklyTrackInsight: WeeklyTrackInsight = .empty
    var recoveryIntervention: RecoveryIntervention = .defaultCheckIn

    // Error state (repo or AI)
    var lastError: String?
    private var lastHealingDaysCount: Int?

    init(
        moodRepo: any MoodRepository,
        aiService: any AIInsightService,
        userID: String,
        userName: String,
        calendar: Calendar = .current
    ) {
        self.moodRepo = moodRepo
        self.aiService = aiService
        self.userID = userID
        self.userName = userName
        self.calendar = calendar
    }

    /// Needs at least one mood (or a note), and only one save at a time.
    var canShareCheckIn: Bool {
        guard !isSavingCheckIn else { return false }
        let hasMoods = !selectedMoods.isEmpty
        let hasNote = !notesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasMoods || hasNote
    }


    // User action: save mood entry
    func apply() async {
        guard !isSavingCheckIn else { return }

        let applied = Array(selectedMoods).sorted()
        let trimmed = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesOrNil: String? = trimmed.isEmpty ? nil : trimmed

        guard !applied.isEmpty || notesOrNil != nil else { return }

        isSavingCheckIn = true
        defer { isSavingCheckIn = false }

        let crisisSignals = CrisisSupportDetector.detect(in: trimmed)
        let moodsJoined = applied.joined(separator: " ")
        let moodSignals = CrisisSupportDetector.detect(in: moodsJoined)
        let combinedSignals = crisisSignals.union(moodSignals)

        do {
            try await moodRepo.addMoodEntry(
                userID: userID,
                notes: notesOrNil,
                moods: applied,
                timestamp: .now
            )

            NotificationCenter.default.post(name: .journalEntriesDidChange, object: nil)

            selectedMoods.removeAll()
            notesText = ""
            lastError = nil

            if combinedSignals.isEmpty {
                activeCrisisSignals = []
                crisisSupportMessage = nil
            } else {
                activeCrisisSignals = combinedSignals
                crisisSupportMessage = combinedSignals.contains(.harmToOthers)
                    ? "I’m glad you said something. If you or someone else might be in danger, please get help now."
                    : "I’m glad you said something. You don’t have to hold this alone. Please reach out for help now."
            }

            await loadHomeSummary()
            await refreshRecoveryEngine(healingDaysCount: lastHealingDaysCount)
            await generateInsightForToday()
        } catch {
            MuneLog.debug("[HomeViewModel] apply failed: \(error)")
            lastError = friendlyErrorMessage(for: error, fallback: "I couldn’t save that just now. When you’re ready, we can try again together.")
        }
    }

    func loadHomeSummary() async {
        do {
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
            let entries = try await moodRepo.fetchMoodEntries(userID: userID, from: start, to: end)

            let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

            weeklyCheckInCount = sortedEntries.count
            weeklyNoteCount = sortedEntries.compactMap { entry in
                entry.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }.count

            var counts: [String: Int] = [:]
            var moodScores: [Int] = []
            for entry in sortedEntries {
                for mood in entry.moods {
                    counts[mood, default: 0] += 1
                    moodScores.append(moodWeight(for: mood))
                }
            }

            weeklyMoodCounts = counts
                .map { MoodCount(mood: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }

            weeklyHelpfulPatternText = helpfulPatternSummary(from: sortedEntries) ?? ""
            weeklyWarningText = heavyWeekWarning(for: moodScores, checkInCount: sortedEntries.count)
            weeklyTrendBars = buildWeeklyTrendBars(from: sortedEntries, ending: end)
            weeklyTrackInsight = buildWeeklyTrackInsight(
                checkInCount: sortedEntries.count,
                moodCounts: weeklyMoodCounts,
                helpfulPattern: weeklyHelpfulPatternText,
                warning: weeklyWarningText
            )

            let startOfToday = calendar.startOfDay(for: end)
            hasCheckedInToday = sortedEntries.contains { $0.timestamp >= startOfToday }

            if let latest = sortedEntries.last {
                let moodText = latest.moods.isEmpty ? "You hadn’t named a feeling yet" : latest.moods.joined(separator: ", ")
                let noteText = latest.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                latestCheckInText = noteText.isEmpty ? moodText : "\(moodText) · \(noteText)"
            } else {
                latestCheckInText = "No check-ins yet. That’s okay."
            }
        } catch {
            MuneLog.debug("[HomeViewModel] loadHomeSummary failed: \(error)")
            lastError = friendlyErrorMessage(for: error, fallback: "I couldn’t load your home summary right now. We can try again in a moment.")
        }
    }

    private func buildWeeklyTrendBars(from entries: [MoodEntry], ending endDate: Date) -> [WeeklyTrendBar] {
        let weekStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -6, to: endDate) ?? endDate)

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                return nil
            }

            let dayEntries = entries.filter { $0.timestamp >= day && $0.timestamp < nextDay }
            let moodScores = dayEntries.flatMap { $0.moods }.map(moodWeight(for:))
            let averageScore = moodScores.isEmpty ? 0.0 : Double(moodScores.reduce(0, +)) / Double(moodScores.count)

            return WeeklyTrendBar(
                dayLabel: shortDayLabel(for: day),
                averageScore: averageScore,
                entryCount: dayEntries.count
            )
        }
    }

    private func buildWeeklyTrackInsight(
        checkInCount: Int,
        moodCounts: [MoodCount],
        helpfulPattern: String,
        warning: String?
    ) -> WeeklyTrackInsight {
        if checkInCount == 0 {
            return WeeklyTrackInsight(
                message: "When you’re ready, share how you’re feeling above. Noticing is already a brave, kind step.",
                actionLabel: "Check in with me",
                destination: .checkIn,
                isHeavy: false
            )
        }

        if let warning {
            return WeeklyTrackInsight(
                message: "\(warning) Come take a slow breath with me, then one small kind thing for yourself.",
                actionLabel: "Come to Calm Space",
                destination: .calmSpace,
                isHeavy: true
            )
        }

        if !helpfulPattern.isEmpty {
            return WeeklyTrackInsight(
                message: "\(helpfulPattern) Hold that close this week. You’re learning what soothes you.",
                actionLabel: "Open your journal",
                destination: .journal,
                isHeavy: false
            )
        }

        if let top = moodCounts.first, RecoveryMood.isHeavy(top.mood) {
            return WeeklyTrackInsight(
                message: "\(top.mood) showed up most this week. Noticing it is a start. Writing something down, or talking with me, can help you figure out what’s next.",
                actionLabel: "Open your journal",
                destination: .journal,
                isHeavy: false
            )
        }

        let checkInText = checkInCount == 1 ? "1 check-in" : "\(checkInCount) check-ins"
        return WeeklyTrackInsight(
            message: "You had \(checkInText) this week. Showing up for yourself matters. I’m proud of you.",
            actionLabel: nil,
            destination: nil,
            isHeavy: false
        )
    }

    private func helpfulPatternSummary(from entries: [MoodEntry]) -> String? {
        let noteText = entries.compactMap { entry in
            entry.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }

        guard !noteText.isEmpty else { return nil }

        let themes: [(label: String, keywords: [String])] = [
            ("rest", ["rest", "sleep", "nap", "slow down"]),
            ("a walk", ["walk", "outside", "stretch", "move", "movement"]),
            ("breathing or meditation", ["breathe", "breathing", "meditation", "ground"]),
            ("talking to someone safe", ["talk", "text", "friend", "support", "call"]),
            ("writing it down", ["journal", "write", "writing", "note"]),
            ("food and water", ["water", "drink", "eat", "meal", "food"]),
            ("music", ["music", "song", "playlist"]),
            ("therapy", ["therapy", "therapist", "counselor", "counsellor"])
        ]

        var counts: [String: Int] = [:]
        for note in noteText {
            let lowercased = note.lowercased()
            for theme in themes where theme.keywords.contains(where: { lowercased.contains($0) }) {
                counts[theme.label, default: 0] += 1
            }
        }

        let topThemes = counts
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { $0.key }

        guard !topThemes.isEmpty else { return nil }

        return "What seemed to help most: \(topThemes.joined(separator: " and "))."
    }

    private func heavyWeekWarning(for scores: [Int], checkInCount: Int) -> String? {
        guard checkInCount >= 3, !scores.isEmpty else {
            return nil
        }

        let averageScore = Double(scores.reduce(0, +)) / Double(scores.count)

        if averageScore <= -0.35 {
            return "This week asked a lot of you, and you still showed up."
        } else if averageScore <= -0.15 {
            return "Some days were tender. You’re still here, and that counts."
        } else {
            return nil
        }
    }

    func refreshRecoveryEngine(healingDaysCount: Int?, now: Date = .now) async {
        lastHealingDaysCount = healingDaysCount

        do {
            let start = RecoverySignalBuilder.lookbackStart(from: now, calendar: calendar)
            let entries = try await moodRepo.fetchMoodEntries(userID: userID, from: start, to: now)
            let signals = RecoverySignalBuilder.make(
                now: now,
                calendar: calendar,
                entries: entries,
                healingDaysCount: healingDaysCount
            )
            recoveryIntervention = RecoveryEngine.intervention(from: signals)
        } catch {
            MuneLog.debug("[HomeViewModel] refreshRecoveryEngine failed: \(error)")
            recoveryIntervention = RecoveryEngine.intervention(
                from: RecoverySignalBuilder.make(
                    now: now,
                    calendar: calendar,
                    entries: [],
                    healingDaysCount: healingDaysCount
                )
            )
        }
    }

    private func moodWeight(for mood: String) -> Int {
        RecoveryMood.weight(for: mood)
    }

    private func shortDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    /// Generates a 1 to 3 sentence insight based only on mood entries logged today.
    func generateInsightForToday() async {
        guard !isGeneratingTodayInsight else { return }

        isGeneratingTodayInsight = true
        todayInsightText = "One sec… thinking this through with you."   // show text immediately
        lastError = nil

        // Artificial pause so the user sees the loading state
        try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s

        defer { isGeneratingTodayInsight = false }

        do {
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)

            let entries = try await moodRepo.fetchMoodEntries(
                userID: userID,
                from: startOfToday,
                to: now
            )

            guard let latestEntry = entries.last else {
                todayInsightText = "Try something small: water, a short walk, or a message to someone you trust."
                return
            }

            let latestMoods = latestEntry.moods
            let latestNotes = latestEntry.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let counts = latestMoods.reduce(into: [String: Int]()) { result, mood in
                result[mood, default: 0] += 1
            }

            let input = MoodInsightInput(
                startDate: startOfToday,
                endDate: now,
                moodCounts: counts,
                notes: latestNotes.isEmpty ? [] : [latestNotes]
            )

            MuneLog.debug("[HomeViewModel] reflection AI input latestEntry moodCount=\(counts.count) hasNote=\(!latestNotes.isEmpty)")

            todayInsightText = try await aiService.generateMoodInsight(from: input, userName: userName)
        } catch {
            MuneLog.debug("[HomeViewModel] generateInsightForToday failed: \(error)")
            lastError = friendlyErrorMessage(for: error, fallback: "I couldn’t put that into words just now. We can try again when you’re ready.")
            todayInsightText = "I hit a small snag reflecting with you. Let’s try again in a moment."
        }
    }

    private func friendlyErrorMessage(for error: Error, fallback: String) -> String {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain || nsError.domain == NSCocoaErrorDomain {
            return fallback
        }

        return fallback
    }
}

struct WeeklyTrackInsight: Equatable {
    let message: String
    let actionLabel: String?
    let destination: HealingFocusTipDestination?
    let isHeavy: Bool

    static let empty = WeeklyTrackInsight(
        message: "When you’re ready, share how you’re feeling above.",
        actionLabel: "Check in with me",
        destination: .checkIn,
        isHeavy: false
    )
}

struct WeeklyTrendBar: Identifiable, Hashable {
    let dayLabel: String
    let averageScore: Double
    let entryCount: Int

    var id: String { dayLabel }

    var normalizedHeight: Double {
        let normalized = (averageScore + 1.0) / 2.0
        return max(0.12, min(1.0, normalized))
    }
}
