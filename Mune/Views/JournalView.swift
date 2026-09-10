//
//  JournalView.swift
//  Mune
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
    @FocusState private var focusedField: JournalField?

    private enum JournalField: Hashable {
        case journal
        case gratitudeOne
        case gratitudeTwo
        case gratitudeThree
    }

    init(vm: JournalViewModel) {
        _vm = State(initialValue: vm)
    }

    var body: some View {
        ZStack {
            Color.appBackgroundGradient
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        moodCheckInsCard
                        header
                        recordCard
                        writtenJournalCard
                        saveButton
                        gratitudesCard
                        saveButton
                        statusCard
                        historyCard
                        dashboardCard
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 90)
                }
                .onChange(of: focusedField) { _, field in
                    guard let field else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(field, anchor: .center)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task { await vm.loadHistory() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .journalEntriesDidChange)) { _ in
            Task { await vm.loadHistory() }
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
                    Text("When you check in on Home, those feelings will gently gather here.")
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
            Text("Feelings you’ve shared")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(Color.cardSurfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var dashboardCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your healing week")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            if vm.healingDashboard.weeklyCheckIns > 0 {
                Text(vm.healingDashboard.moodTrend)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                metricCard(title: "Moments you checked in", value: "\(vm.healingDashboard.weeklyCheckIns)")
                metricCard(title: "Days with gratitude", value: "\(vm.healingDashboard.gratitudeDays)")
            }

            if let dominantMood = vm.healingDashboard.dominantMood {
                Text("Feeling that showed up most: \(dominantMood)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text(vm.healingDashboard.supportMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color.cardGradient)
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
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journal")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.brandPrimary)

            Text("A quiet place for what’s on your heart. Write, speak, or both. I’ll hold the space while you feel.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cardSurfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Speak it out")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            Text(vm.isRecording ? "I’m listening… speak naturally. Your words will land softly in your journal." : "If writing feels hard, speak. I’ll turn your words into text so you can edit them gently.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await vm.toggleRecording()
                }
            } label: {
                HStack {
                    Image(systemName: vm.isRecording ? "stop.circle.fill" : "mic.fill")
                    Text(vm.isRecording ? "I’m done speaking" : "Start speaking")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(vm.isRecording ? Color.red.opacity(0.9) : Color.brandFill)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)

            if let voiceStatusMessage = vm.voiceStatusMessage {
                Label(voiceStatusMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.brandPrimary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(voiceStatusMessage)
            }

            if vm.isTranscribing {
                ProgressView("Bringing your words into the journal…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.cardSurfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var writtenJournalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s pages")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            VStack(alignment: .leading, spacing: 10) {
                Text("Gentle prompts")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)

                Text("Tap one when you need a starting place. Change every word. This is yours.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(JournalViewModel.breakupTemplates) { template in
                            journalPromptChip(template)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .clipped()
            }

            TextEditor(text: $vm.journalText)
                .focused($focusedField, equals: .journal)
                .frame(minHeight: 160)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
                )
        }
        .padding(18)
        .background(Color.cardSurfaceSoft, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .id(JournalField.journal)
    }

    private func journalPromptChip(_ template: JournalViewModel.JournalTemplate) -> some View {
        let isSelected = vm.selectedTemplateID == template.id

        return Button {
            vm.applyJournalTemplate(template)
        } label: {
            Text(template.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? Color.buttonText : Color.brandPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    isSelected ? Color.brandFill : Color.brandPrimary.opacity(0.12),
                    in: Capsule(style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(template.title)
        .accessibilityHint("Adds this gentle journal prompt")
    }

    private var gratitudesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Three soft gratitudes")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            Text("When you can, name a few things, even tiny ones, that you’re grateful for today.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            gratitudeField(title: "Something I’m grateful for…", text: $vm.gratitudeOne, field: .gratitudeOne)
            gratitudeField(title: "Another small kindness…", text: $vm.gratitudeTwo, field: .gratitudeTwo)
            gratitudeField(title: "One more, if you have it…", text: $vm.gratitudeThree, field: .gratitudeThree)
        }
        .padding(18)
        .background(Color.cardSurfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func gratitudeField(title: String, text: Binding<String>, field: JournalField) -> some View {
        TextField(title, text: text)
            .focused($focusedField, equals: field)
            .padding(14)
            .background(Color.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.brandPrimary.opacity(0.15), lineWidth: 1)
            )
            .textInputAutocapitalization(.sentences)
            .id(field)
    }

    private var saveButton: some View {
        Button {
            vm.saveJournalEntry()
        } label: {
            Text("Save this entry")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(vm.canSaveEntry ? Color.brandFill : Color.brandFill.opacity(0.35))
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
                HStack(alignment: .center, spacing: 12) {
                    Button(isSelectingHistoryEntries ? "Done" : "Select") {
                        isSelectingHistoryEntries.toggle()
                        if !isSelectingHistoryEntries {
                            selectedJournalEntryKeys.removeAll()
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)

                    Spacer(minLength: 8)

                    if isSelectingHistoryEntries && !selectedJournalEntryKeys.isEmpty {
                        Button(role: .destructive) {
                            let keys = selectedJournalEntryKeys
                            selectedJournalEntryKeys.removeAll()
                            isSelectingHistoryEntries = false
                            Task { await vm.deleteJournalEntries(withKeys: keys) }
                        } label: {
                            Text("Delete Selected")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
                .frame(minHeight: 28)

                if vm.moodEntries.isEmpty && vm.historyEntries.isEmpty {
                    Text("Your saved pages will gather here over time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    LazyVStack(spacing: 12) {
                        if !vm.historyEntries.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your pages")
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
                Text("Earlier pages")
                    .font(.headline)
                    .foregroundStyle(Color.brandPrimary)
                Spacer()
                Image(systemName: showHistoryEntries ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.cardSurfaceSoft)
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
        .background(Color.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func journalEntryRow(_ entry: JournalEntry) -> some View {
        let key = vm.journalEntryKey(entry)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                if isSelectingHistoryEntries {
                    Button {
                        toggleJournalSelection(for: entry)
                    } label: {
                        Image(systemName: selectedJournalEntryKeys.contains(key) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(Color.brandPrimary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select entry")
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)

                        Spacer(minLength: 4)

                        if entry.transcript != nil {
                            Label("Recorded", systemImage: "mic.fill")
                                .font(.caption)
                                .foregroundStyle(Color.brandPrimary)
                                .labelStyle(.titleAndIcon)
                        } else {
                            Label("Journal", systemImage: "note.text")
                                .font(.caption)
                                .foregroundStyle(Color.brandPrimary)
                                .labelStyle(.titleAndIcon)
                        }
                    }

                    if !entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(entry.journalText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let transcript = entry.transcript, !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(transcript)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                Button(role: .destructive) {
                    Task { await vm.deleteJournalEntries(withKeys: [key]) }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete journal entry")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.fieldSurface)
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
