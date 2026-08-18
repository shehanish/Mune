//
//  JournalView.swift
//  Mend
//
//  Created by Shehani Hansika on 07.07.26.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @State private var vm: JournalViewModel
    @State private var showMoodEntries: Bool = false
    @State private var showHistoryEntries: Bool = false
    @State private var isSelectingMoodEntries: Bool = false
    @State private var isSelectingHistoryEntries: Bool = false
    @State private var selectedMoodEntryKeys: Set<String> = []
    @State private var selectedJournalEntryKeys: Set<String> = []

    init(vm: JournalViewModel) {
        _vm = State(initialValue: vm)
    }

    var body: some View {
        ZStack {
            Color.appBackgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    moodCheckInsCard
                    header
                    recordCard
                    writtenJournalCard
                    gratitudesCard
                    saveButton
                    statusCard
                    historyCard
                    dashboardCard
                }
                .padding()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            Task { await vm.loadHistory() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .journalEntriesDidChange)) { _ in
            Task { await vm.loadHistory() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
    }

    private var moodCheckInsCard: some View {
        DisclosureGroup(isExpanded: $showMoodEntries) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(isSelectingMoodEntries ? "Done" : "Select") {
                        isSelectingMoodEntries.toggle()
                        if !isSelectingMoodEntries {
                            selectedMoodEntryKeys.removeAll()
                        }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.brandPrimary)

                    Spacer()

                    if isSelectingMoodEntries && !selectedMoodEntryKeys.isEmpty {
                        Button(role: .destructive) {
                            let keys = selectedMoodEntryKeys
                            selectedMoodEntryKeys.removeAll()
                            isSelectingMoodEntries = false
                            Task { await vm.deleteMoodEntries(withKeys: keys) }
                        } label: {
                            Text("Delete Selected")
                                .font(.caption.bold())
                        }
                    }
                }

                if vm.moodEntries.isEmpty {
                    Text("Your home check-ins will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.moodEntries) { entry in
                            moodEntryRow(entry)
                        }
                    }
                }
            }
            .padding(.top, 12)
        } label: {
            HStack {
                Text("Mood Check-Ins")
                    .font(.headline)
                    .foregroundStyle(Color.brandPrimary)
                Spacer()
                Image(systemName: showMoodEntries ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var dashboardCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your healing week")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            Text(vm.healingDashboard.moodTrend)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                metricCard(title: "Check-ins", value: "\(vm.healingDashboard.weeklyCheckIns)")
                metricCard(title: "Gratitude days", value: "\(vm.healingDashboard.gratitudeDays)")
            }

            if let dominantMood = vm.healingDashboard.dominantMood {
                Text("Most common mood: \(dominantMood)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !vm.healingDashboard.themes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Common themes")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    FlowLayout(items: vm.healingDashboard.themes) { theme in
                        Text(theme)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.brandPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.brandPrimary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            Text(vm.healingDashboard.supportMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.92), Color.brandPrimary.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journal")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.brandPrimary)

            Text("Process what you're feeling — write, speak, or both. This is your space to grieve and reflect.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Voice Journal")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            Text(vm.isRecording ? "Listening… speak naturally. Words will appear in Daily Journal." : "Record a spoken journal entry. The transcript will appear in Daily Journal so you can edit it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await vm.toggleRecording()
                }
            } label: {
                HStack {
                    Image(systemName: vm.isRecording ? "stop.circle.fill" : "mic.fill")
                    Text(vm.isRecording ? "Stop Recording" : "Start Recording")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(vm.isRecording ? Color.red.opacity(0.9) : Color.darkCharcoal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)

            if vm.isTranscribing {
                ProgressView("Adding transcript to your journal...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var writtenJournalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Journal")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            TextEditor(text: $vm.journalText)
                .frame(minHeight: 160)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
                )
        }
        .padding(18)
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var gratitudesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Gratitudes")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            Text("Add at least three things you’re grateful for today.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            gratitudeField(title: "Gratitude 1", text: $vm.gratitudeOne)
            gratitudeField(title: "Gratitude 2", text: $vm.gratitudeTwo)
            gratitudeField(title: "Gratitude 3", text: $vm.gratitudeThree)
        }
        .padding(18)
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func gratitudeField(title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .padding(14)
            .background(Color.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.brandPrimary.opacity(0.15), lineWidth: 1)
            )
    }

    private var saveButton: some View {
        Button {
            vm.saveJournalEntry()
        } label: {
            Text("Save Journal Entry")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(vm.canSaveEntry ? Color.brandPrimary : Color.brandPrimary.opacity(0.35))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(!vm.canSaveEntry)
    }

    private var statusCard: some View {
        Group {
            if let statusMessage = vm.statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var historyCard: some View {
        DisclosureGroup(isExpanded: $showHistoryEntries) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(isSelectingHistoryEntries ? "Done" : "Select") {
                        isSelectingHistoryEntries.toggle()
                        if !isSelectingHistoryEntries {
                            selectedJournalEntryKeys.removeAll()
                        }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.brandPrimary)

                    Spacer()

                    if isSelectingHistoryEntries && !selectedJournalEntryKeys.isEmpty {
                        Button(role: .destructive) {
                            let keys = selectedJournalEntryKeys
                            selectedJournalEntryKeys.removeAll()
                            isSelectingHistoryEntries = false
                            Task { await vm.deleteJournalEntries(withKeys: keys) }
                        } label: {
                            Text("Delete Selected")
                                .font(.caption.bold())
                        }
                    }
                }

                Text(vm.debugHistoryMessage)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)

                if vm.moodEntries.isEmpty && vm.historyEntries.isEmpty {
                    Text("Your saved entries will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    LazyVStack(spacing: 12) {
                        if !vm.historyEntries.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Journal Entries")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)

                                ForEach(vm.historyEntries) { entry in
                                    journalEntryRow(entry)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 12)
        } label: {
            HStack {
                Text("Journal History")
                    .font(.headline)
                    .foregroundStyle(Color.brandPrimary)
                Spacer()
                Image(systemName: showHistoryEntries ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func moodEntryRow(_ entry: MoodEntry) -> some View {
        let key = vm.moodEntryKey(entry)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button {
                    if isSelectingMoodEntries {
                        toggleMoodSelection(for: entry)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        if isSelectingMoodEntries {
                            Image(systemName: selectedMoodEntryKeys.contains(key) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(Color.brandPrimary)
                                .padding(.top, 1)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.bold())

                            if !entry.moods.isEmpty {
                                Text(entry.moods.joined(separator: ", "))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if let note = entry.notes, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(note)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    Task { await vm.deleteMoodEntries(withKeys: [key]) }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func journalEntryRow(_ entry: JournalEntry) -> some View {
        let key = vm.journalEntryKey(entry)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button {
                    if isSelectingHistoryEntries {
                        toggleJournalSelection(for: entry)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        if isSelectingHistoryEntries {
                            Image(systemName: selectedJournalEntryKeys.contains(key) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(Color.brandPrimary)
                                .padding(.top, 1)
                        }

                        HStack {
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.bold())
                            Spacer()
                            if entry.transcript != nil {
                                Label("Recorded", systemImage: "mic.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.brandPrimary)
                            } else {
                                Label("Journal", systemImage: "note.text")
                                    .font(.caption)
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    Task { await vm.deleteJournalEntries(withKeys: [key]) }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if !entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.journalText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let transcript = entry.transcript, !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(transcript)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !entry.gratitudeOne.isEmpty || !entry.gratitudeTwo.isEmpty || !entry.gratitudeThree.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gratitudes")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    if !entry.gratitudeOne.isEmpty {
                        Text("• \(entry.gratitudeOne)")
                    }
                    if !entry.gratitudeTwo.isEmpty {
                        Text("• \(entry.gratitudeTwo)")
                    }
                    if !entry.gratitudeThree.isEmpty {
                        Text("• \(entry.gratitudeThree)")
                    }
                }
                .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func toggleMoodSelection(for entry: MoodEntry) {
        let key = vm.moodEntryKey(entry)
        if selectedMoodEntryKeys.contains(key) {
            selectedMoodEntryKeys.remove(key)
        } else {
            selectedMoodEntryKeys.insert(key)
        }
    }

    private func toggleJournalSelection(for entry: JournalEntry) {
        let key = vm.journalEntryKey(entry)
        if selectedJournalEntryKeys.contains(key) {
            selectedJournalEntryKeys.remove(key)
        } else {
            selectedJournalEntryKeys.insert(key)
        }
    }

}

private struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        FlexibleWrap(items: items, content: content)
    }
}

private struct FlexibleWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                content(item)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: JournalEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let moodRepo = SwiftDataMoodRepository(context: context)
    let vm = JournalViewModel(context: context, moodRepo: moodRepo, userID: "app-user", userName: "Friend")

    JournalView(vm: vm)
        .modelContainer(container)
}
