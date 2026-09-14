//
//  JournalView.swift
//  Mune
//
//  Created by Shehani Hansika on 07.07.26.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.recoveryNavigator) private var navigator
    @State private var vm: JournalViewModel
    @State private var showHistoryEntries: Bool = false
    @State private var isSelectingHistoryEntries: Bool = false
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
                        header
                        if let crisisMessage = vm.crisisSupportMessage, !vm.activeCrisisSignals.isEmpty {
                            CrisisHelplineCard(message: crisisMessage, signals: vm.activeCrisisSignals)
                        }
                        recordCard
                        writtenJournalCard
                        gratitudesCard
                        historyCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journal")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.brandPrimary)
            Text("Write what’s on your mind, or say it out loud. No perfect sentences needed.")
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Speak it out")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.brandPrimary)

            Text(vm.isRecording
                 ? "I’m listening. Speak naturally. You can edit after."
                 : "If typing feels hard, just talk. I’ll turn it into text you can edit.")
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await vm.toggleRecording() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: vm.isRecording ? "stop.fill" : "mic.fill")
                    Text(vm.isRecording ? "I’m done speaking" : "Start speaking")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(vm.isRecording ? Color.red.opacity(0.9) : Color.brandFill)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if let voiceStatusMessage = vm.voiceStatusMessage {
                Label(voiceStatusMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.brandPrimary.opacity(0.85))
            }

            if vm.isTranscribing {
                ProgressView("Bringing your words into the journal…")
                    .font(.footnote)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var writtenJournalCard: some View {
        let prompts = journalPromptItems

        return VStack(alignment: .leading, spacing: 14) {
            Text("Today’s pages")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.brandPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Prompts")
                    .font(.headline)
                    .foregroundStyle(Color.brandPrimary)

                Text("Tap one to start. Change every word. It’s yours.")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandPrimary.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(prompts) { prompt in
                        Button {
                            applyJournalPrompt(prompt)
                        } label: {
                            MuneChipLabel(
                                title: prompt.title,
                                isSelected: isPromptSelected(prompt),
                                showsCheckmark: false,
                                selectedForeground: .brandPrimary,
                                unselectedForeground: .brandPrimary,
                                selectedFill: Color.sageGreen.opacity(0.38),
                                unselectedFill: Color.white
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(prompt.title)
                        .accessibilityHint("Uses this journal prompt")
                    }
                }
                .padding(.vertical, 2)
            }

            TextEditor(text: $vm.journalText)
                .focused($focusedField, equals: .journal)
                .frame(minHeight: 160)
                .padding(14)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.brandPrimary.opacity(0.14), lineWidth: 1)
                )

            saveButton
            statusCard
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .id(JournalField.journal)
    }

    private var journalPromptItems: [JournalPromptItem] {
        var items: [JournalPromptItem] = JournalViewModel.breakupTemplates.map {
            JournalPromptItem(id: $0.id, title: $0.title, kind: .template($0))
        }
        items.append(JournalPromptItem(id: "reality-check", title: "Reality Check", kind: .realityCheck))
        items.append(JournalPromptItem(id: RecoveryExerciseID.miss, title: "What do I miss?", kind: .exercise(RecoveryExerciseID.miss)))
        return items
    }

    private func applyJournalPrompt(_ prompt: JournalPromptItem) {
        switch prompt.kind {
        case .realityCheck:
            navigator.openRealityCheck()
        case .exercise(let id):
            navigator.openJournalExercise(id)
        case .template(let template):
            vm.applyJournalTemplate(template)
        }
    }

    private func isPromptSelected(_ prompt: JournalPromptItem) -> Bool {
        if case .template(let template) = prompt.kind {
            return vm.selectedTemplateID == template.id
        }
        return false
    }

    private var gratitudesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gratitudes")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.brandPrimary)

            Text("Three small things, if you have them. They don’t have to be big.")
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                gratitudeField(title: "Something I’m grateful for…", text: $vm.gratitudeOne, field: .gratitudeOne)
                gratitudeField(title: "Another small kindness…", text: $vm.gratitudeTwo, field: .gratitudeTwo)
                gratitudeField(title: "One more, if you have it…", text: $vm.gratitudeThree, field: .gratitudeThree)
            }

            Button {
                vm.saveJournalEntry()
            } label: {
                Text("Save this entry")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(vm.canSaveGratitudes ? Color.brandFill : Color.brandFill.opacity(0.35))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!vm.canSaveGratitudes)
            .accessibilityHint(
                vm.canSaveGratitudes
                ? "Saves your gratitudes"
                : "Write at least one gratitude first"
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
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
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(vm.canSaveJournalWriting ? Color.brandFill : Color.brandFill.opacity(0.35))
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!vm.canSaveJournalWriting)
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
        foldCard(
            icon: "book.pages.fill",
            title: "Earlier pages",
            subtitle: earlierPagesSubtitle,
            isExpanded: $showHistoryEntries
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let weekLine = thisWeekLine {
                    Text(weekLine)
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 2)
                }

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

                if vm.historyEntries.isEmpty {
                    Text("Your saved pages will show up here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.historyEntries) { entry in
                            journalEntryRow(entry)
                        }
                    }
                }
            }
        }
    }

    private var earlierPagesSubtitle: String {
        let count = vm.historyEntries.count
        let pages: String = {
            if count == 0 { return "Past writing you’ve saved" }
            if count == 1 { return "1 saved page" }
            return "\(count) saved pages"
        }()

        if let weekLine = thisWeekLine {
            return "\(pages). \(weekLine)"
        }
        return "\(pages). Open to look back."
    }

    /// Compact week hint so Journal doesn’t need a separate “This week” card.
    private var thisWeekLine: String? {
        let checkIns = vm.healingDashboard.weeklyCheckIns
        let gratitude = vm.healingDashboard.gratitudeDays
        guard checkIns > 0 || gratitude > 0 else { return nil }

        var parts: [String] = ["This week"]
        if checkIns > 0 {
            parts.append("\(checkIns) \(checkIns == 1 ? "check-in" : "check-ins")")
        }
        if gratitude > 0 {
            parts.append("\(gratitude) gratitude \(gratitude == 1 ? "day" : "days")")
        }
        if let mood = vm.healingDashboard.dominantMood {
            parts.append("mostly \(mood)")
        }
        return parts.joined(separator: " · ")
    }

    private func foldCard<Content: View>(
        icon: String,
        title: String,
        subtitle: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.brandPrimary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.brandPrimary.opacity(0.55))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(subtitle)
            .accessibilityHint(isExpanded.wrappedValue ? "Collapse" : "Expand")

            if isExpanded.wrappedValue {
                content()
                    .padding(.top, 14)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.62))
        )
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

    private func toggleJournalSelection(for entry: JournalEntry) {
        let key = vm.journalEntryKey(entry)
        if selectedJournalEntryKeys.contains(key) {
            selectedJournalEntryKeys.remove(key)
        } else {
            selectedJournalEntryKeys.insert(key)
        }
    }

}

private struct JournalPromptItem: Identifiable {
    enum Kind {
        case realityCheck
        case exercise(String)
        case template(JournalViewModel.JournalTemplate)
    }

    let id: String
    let title: String
    let kind: Kind
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
