//
//  HomeView.swift
//  Mune
//
//  Created by Shehani Hansika on 05.05.26.
//

import SwiftUI
import SwiftData

private struct PreviewAIInsightService: AIInsightService {
    func generateMoodInsight(from input: MoodInsightInput, userName: String) async throws -> String {
        "Preview: Your mood today looks steady."
    }

    func generateChatResponse(conversation: [(isUser: Bool, text: String)], userName: String, context: ChatInsightContext?) async throws -> String {
        "Preview: I hear you. Take things one day at a time."
    }
}

struct HomeView: View {
    @AppStorage("userName") private var userName = "Friend"
    @AppStorage("profileImageData") private var profileImageData: Data = Data()
    @AppStorage("healingFocus") private var healingFocus = ""
    @AppStorage(HealingDaysTracker.isActiveKey) private var healingDaysIsActive = false
    @AppStorage(HealingDaysTracker.startDateKey) private var healingDaysStartDateInterval: Double = 0
    @AppStorage(HealingDaysTracker.goalKey) private var healingDaysGoal = ""
    @State private var showProfileSheet = false
    @State private var showSettingsSheet = false
    @State private var showHealingDaysSheet = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.recoveryNavigator) private var navigator
    @Environment(\.modelContext) private var modelContext
    @State private var rebuildShowedUpText: String?

    private let moods = RecoveryMood.checkInOptions

    @State private var vm: HomeViewModel
    @Binding var selectedTab: Int
    private let onTalkToMeAboutIt: ((String) -> Void)?

    @State private var timeBasedGreeting: String = "Good morning"
    @FocusState private var isNotesFocused: Bool

    init(vm: HomeViewModel, selectedTab: Binding<Int>, onTalkToMeAboutIt: ((String) -> Void)? = nil) {
        _vm = State(initialValue: vm)
        _selectedTab = selectedTab
        self.onTalkToMeAboutIt = onTalkToMeAboutIt
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5: timeBasedGreeting = "It’s late"
        case 5..<12: timeBasedGreeting = "Good morning"
        case 12..<17: timeBasedGreeting = "Good afternoon"
        default: timeBasedGreeting = "Good evening"
        }
    }

    private var displayedUserName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Friend" : trimmed
    }

    private var healingDaysCount: Int {
        guard healingDaysIsActive,
              let startDate = HealingDaysTracker.startDate(from: healingDaysStartDateInterval) else {
            return 0
        }
        return HealingDaysTracker.daysElapsed(since: startDate)
    }

    private var healingDaysCountOrNil: Int? {
        healingDaysIsActive ? healingDaysCount : nil
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.appBackgroundGradient.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        welcomeCard
                            .padding(.horizontal, 20)

                        focusTipCard
                            .padding(.horizontal, 20)

                        checkInChapter
                            .padding(.horizontal, 20)
                            .id("dailyCheckIn")

                        if vm.hasCheckedInToday {
                            nextStepCard(proxy: proxy)
                                .padding(.horizontal, 20)
                        }

                        storyStrip
                            .padding(.bottom, vm.hasCheckedInToday ? 28 : 16)
                    }
                    .padding(.top, 8)
                    .safeAreaPadding(.top)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isNotesFocused) { _, isFocused in
                    guard isFocused else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("dailyCheckIn", anchor: .center)
                        }
                    }
                }
            }

            homeAccountMenu
                .padding(.trailing, 18)
                .safeAreaPadding(.top)
                .padding(.top, 6)
        }
        .sheet(isPresented: $showProfileSheet) { ProfileView() }
        .sheet(isPresented: $showSettingsSheet) { SettingsView() }
        .sheet(isPresented: $showHealingDaysSheet) {
            CounterView(showsDismissButton: true)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            refreshHome(includingSummary: true)
            refreshRebuildShowedUp()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshHome(includingSummary: false)
            refreshRebuildShowedUp()
        }
        .onChange(of: selectedTab) { _, tab in
            guard tab == 0 else { return }
            refreshHome(includingSummary: false)
            refreshRebuildShowedUp()
        }
        .onChange(of: navigator.showRebuild) { _, isShowing in
            if !isShowing {
                refreshRebuildShowedUp()
            }
        }
        .onChange(of: healingDaysIsActive) { _, _ in
            refreshHome(includingSummary: false)
        }
        .onChange(of: healingDaysStartDateInterval) { _, _ in
            refreshHome(includingSummary: false)
        }
    }

    private var welcomeCard: some View {
        VStack(spacing: 18) {
            BlobAvatarView(width: 128, height: 108, showShadow: true, animate: !MotionPreference.shouldReduceMotion)
                .padding(.top, 16)

            Text("\(timeBasedGreeting), \(displayedUserName)!")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.brandPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)

            Text("Hey. Glad you’re here. We’ll take today as it comes.")
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary.opacity(0.68))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)

            AffirmationView()
                .padding(.top, 6)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 36, style: .continuous))
    }

    private var focusTipCard: some View {
        let tip = HealingFocusTipBuilder.tip(
            healingFocusRaw: healingFocus,
            healingDaysIsActive: healingDaysIsActive,
            healingDaysCount: healingDaysCount
        )

        return Button {
            handleFocusTip(tip)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: tip.icon)
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(tip.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.brandPrimary)
                    Text(tip.message)
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary.opacity(0.55))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(tip.actionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.62))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tip.title). \(tip.message)")
        .accessibilityHint(tip.actionLabel)
    }

    private func handleFocusTip(_ tip: HealingFocusTip) {
        switch tip.destination {
        case .healingDays:
            showHealingDaysSheet = true
        case .calmSpace:
            navigator.openCalmSpace(focus: .breathe)
        case .journal:
            navigator.openJournal()
        case .rebuild:
            navigator.openRebuild()
        case .checkIn:
            break
        }
    }

    private var checkInChapter: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("CHECK-IN")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Color.brandPrimary.opacity(0.4))

                Text("How are you right now?")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.brandPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            MoodsSectionView(
                moods: moods,
                selectedMoods: $vm.selectedMoods,
                notesText: $vm.notesText,
                isNotesFocused: $isNotesFocused,
                canShare: vm.canShareCheckIn,
                isSharing: vm.isSavingCheckIn,
                showsTitle: false
            ) { _ in
                Task { await vm.apply() }
            }

            if vm.isGeneratingTodayInsight || (vm.hasCheckedInToday && vm.todayInsightText != nil) {
                companionNote
            }

            if let crisisMessage = vm.crisisSupportMessage, !vm.activeCrisisSignals.isEmpty {
                CrisisHelplineCard(message: crisisMessage, signals: vm.activeCrisisSignals)
            }

            if let err = vm.lastError {
                Text(err)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func nextStepCard(proxy: ScrollViewProxy) -> some View {
        let intervention = vm.recoveryIntervention

        return VStack(alignment: .leading, spacing: 10) {
            Text(intervention.headline)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let why = intervention.whyLine {
                Text(why)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.brandPrimary.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let context = intervention.contextLine {
                Text(context)
                    .font(.caption2)
                    .foregroundStyle(Color.brandPrimary.opacity(0.4))
            }

            Text(intervention.body)
                .font(.footnote)
                .foregroundStyle(Color.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                handleRecoveryDestination(intervention, proxy: proxy)
            } label: {
                HStack(spacing: 6) {
                    Text(intervention.actionLabel)
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.brandFill, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel([
            intervention.headline,
            intervention.whyLine,
            intervention.body,
            intervention.actionLabel
        ].compactMap { $0 }.joined(separator: ". "))
    }

    private var companionNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mune")
                .font(.caption2)
                .foregroundStyle(Color.brandPrimary.opacity(0.7))
                .padding(.leading, 44)

            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.cardSurfaceStrong)
                        .overlay(
                            Circle()
                                .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
                        )
                        .frame(width: 36, height: 36)

                    BlobAvatarView(width: 22, height: 18, showShadow: false)
                        .frame(width: 36, height: 36, alignment: .center)
                        .offset(y: -1)
                }

                if vm.isGeneratingTodayInsight {
                    Text("thinking…")
                        .font(.subheadline)
                        .foregroundStyle(Color.brandPrimary.opacity(0.55))
                        .padding(14)
                        .background(Color.sageGreen.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .cornerRadius(4, corners: [.bottomLeft])
                } else if let insight = vm.todayInsightText, !insight.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insight)
                            .font(.subheadline)
                            .foregroundStyle(Color.textOnPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(14)
                            .background(Color.sageGreen.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .cornerRadius(4, corners: [.bottomLeft])

                        Button {
                            onTalkToMeAboutIt?(insight)
                            selectedTab = 1
                        } label: {
                            HStack(spacing: 4) {
                                Text("Talk it through with me")
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary.opacity(0.75))
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 4)
                    }
                }
            }
        }
        .padding(.top, 8)
        .accessibilityLabel("Reply from Mune")
    }

    private var storyStrip: some View {
        return VStack(spacing: 12) {
            storyTile(
                icon: "sun.max.fill",
                title: "Rebuild yourself",
                subtitle: rebuildShowedUpText
                    ?? "Small daily steps for your body, mind, and people. Build a life that feels like yours again."
            ) {
                navigator.openRebuild()
            }

            storyTile(
                icon: "heart.text.clipboard",
                title: "Recovery progress",
                subtitle: "A weekly check on how you’re really doing, not just the day count."
            ) {
                navigator.openProgress()
            }

            storyTile(
                icon: "leaf.fill",
                title: "Healing days",
                subtitle: healingDaysIsActive
                    ? "\(healingDaysCount) \(healingDaysCount == 1 ? "day" : "days") since last contact."
                    : "Count the days since you last contacted them."
            ) {
                showHealingDaysSheet = true
            }
        }
        .padding(.horizontal, 20)
    }

    private func storyTile(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary.opacity(0.3))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.62))
            )
        }
        .buttonStyle(.plain)
    }

    private var homeAccountMenu: some View {
        Menu {
            Section("When you need a hand") {
                Button { selectedTab = 1 } label: {
                    Label("Talk with me", systemImage: "bubble.left.and.bubble.right")
                }
                Button { selectedTab = 2 } label: {
                    Label("Journal", systemImage: "book.pages")
                }
            }
            Section("This space") {
                Button { showProfileSheet = true } label: {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                Button { showSettingsSheet = true } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        } label: {
            if !profileImageData.isEmpty, let uiImage = UIImage(data: profileImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.brandPrimary.opacity(0.7))
                    .background(Circle().fill(Color.white.opacity(0.55)).frame(width: 36, height: 36))
            }
        }
        .accessibilityLabel("Profile menu")
    }

    private func refreshRebuildShowedUp() {
        let userID = LocalProfileStore.activeProfileID.isEmpty
            ? LocalProfileStore.legacyUserID
            : LocalProfileStore.activeProfileID
        let start = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<RebuildGoal>(
            predicate: #Predicate { $0.userID == userID && $0.date >= start && $0.isDone == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let done = (try? modelContext.fetch(descriptor)) ?? []
        if done.isEmpty {
            rebuildShowedUpText = nil
        } else if done.count == 1 {
            rebuildShowedUpText = "You showed up today: \(done[0].title)."
        } else {
            rebuildShowedUpText = "You showed up today: \(done[0].title) + \(done.count - 1) more."
        }
    }

    private func refreshHome(includingSummary: Bool) {
        updateGreeting()
        Task {
            if includingSummary {
                await vm.loadHomeSummary()
            }
            await vm.refreshRecoveryEngine(healingDaysCount: healingDaysCountOrNil)
        }
    }

    private func handleRecoveryDestination(_ intervention: RecoveryIntervention, proxy: ScrollViewProxy) {
        switch intervention.destination {
        case .checkIn:
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("dailyCheckIn", anchor: .center)
            }
        case .chat:
            if let starter = intervention.chatStarter {
                onTalkToMeAboutIt?(starter)
            }
            navigator.openChat()
        default:
            navigator.handle(intervention.destination)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: MoodEntry.self, JournalEntry.self, RealityCheckEntry.self, RebuildGoal.self, RecoverySnapshot.self,
        configurations: config
    )
    let context = ModelContext(container)
    let repo = SwiftDataMoodRepository(context: context)
    let vm = HomeViewModel(
        moodRepo: repo,
        aiService: PreviewAIInsightService(),
        userID: "preview-user",
        userName: "Friend"
    )

    HomeView(vm: vm, selectedTab: .constant(0))
        .modelContainer(container)
}
