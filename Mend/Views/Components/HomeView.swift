//
//  ContentView.swift
//  Mend
//
//  Created by Shehani Hansika on 05.05.26.
//

import SwiftUI
import SwiftData

// MARK: - Preview-only AI service (kept outside #Preview to avoid macro issues)
private struct PreviewAIInsightService: AIInsightService {
    func generateMoodInsight(from input: MoodInsightInput, userName: String) async throws -> String {
        "Preview: Your mood today looks steady."
    }
    
    func generateChatResponse(conversation: [(isUser: Bool, text: String)], userName: String, context: ChatInsightContext?) async throws -> String {
        "Preview: I hear you. Take things one day at a time."
    }
}

struct HomeView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @AppStorage("userName") private var userName = "Friend"
    @AppStorage("healingFocus") private var healingFocus = ""
    @AppStorage("profileImageData") private var profileImageData: Data = Data()
    @AppStorage(NoContactTracker.isActiveKey) private var noContactIsActive = false
    @AppStorage(NoContactTracker.startDateKey) private var noContactStartDateInterval: Double = 0
    @AppStorage(NoContactTracker.goalKey) private var noContactGoal = ""
    @State private var showProfileSheet = false
    @State private var showSettingsSheet = false
    @State private var showFeedbackSheet = false
    @State private var showLogoutConfirmation = false
    @State private var showNoContactSheet = false
    
    private let moods = [
        "Calm", "Sad", "Angry", "Anxious",
        "Okay", "Hopeful", "Tired", "Lonely", "Empty"
    ]
    
    @State private var vm: HomeViewModel
    @Binding var selectedTab: Int
    private let onTalkToMeAboutIt: ((String) -> Void)?
    
    // MARK: - Greeting
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
        case 5..<12:
            timeBasedGreeting = "Good morning"
        case 12..<17:
            timeBasedGreeting = "Good afternoon"
        default:
            timeBasedGreeting = "Good evening"
        }
    }
    
    private var greetingText: String {
        let nameToDisplay = userName.isEmpty ? "Friend" : userName
        return "\(timeBasedGreeting), \(nameToDisplay)!"
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date())
    }

    private var noContactDays: Int {
        guard noContactIsActive,
              let startDate = NoContactTracker.startDate(from: noContactStartDateInterval) else {
            return 0
        }
        return NoContactTracker.daysElapsed(since: startDate)
    }

    private var noContactTrackSubtitle: String {
        if noContactIsActive {
            if noContactDays == 1 {
                return "1 gentle day. Tap when you’d like to look"
            }
            return "\(noContactDays) gentle days. Tap when you’d like to look"
        }
        return "Your streak can wait until you’re ready"
    }

    private var healingFocusTip: HealingFocusTip {
        HealingFocusTipBuilder.tip(
            healingFocusRaw: healingFocus,
            noContactIsActive: noContactIsActive,
            noContactDays: noContactDays
        )
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Welcome
                        VStack(spacing: 18) {
                            BlobAvatarView(
                                width: 150,
                                height: 160,
                                showShadow: true,
                                animate: true
                            )
                            .padding(.top, 2)

                            Text(greetingText)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.brandPrimary)

                            Text("I’m with you today. We’ll take this one soft step at a time.")
                                .font(.subheadline)
                                .foregroundStyle(Color.brandPrimary)

                            AffirmationView()
                                .padding(.top, 4)
                        }
                        .padding(15)
                        .background(Color.cardGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        // 1. Feel
                        VStack(alignment: .leading, spacing: 16) {
                            loopSectionLabel("With you")

                            Text("A moment to check in with yourself")
                                .font(.headline)
                                .foregroundStyle(Color.brandPrimary)

                            MoodsSectionView(
                                moods: moods,
                                selectedMoods: $vm.selectedMoods,
                                notesText: $vm.notesText,
                                isNotesFocused: $isNotesFocused,
                                canShare: vm.canShareCheckIn,
                                isSharing: vm.isSavingCheckIn
                            ) { _ in
                                Task { await vm.apply() }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .id("dailyCheckIn")

                        // 2. Reflect
                        VStack(alignment: .leading, spacing: 14) {
                            loopSectionLabel("For you")

                            Text("A few kind words for you")
                                .font(.headline)
                                .foregroundStyle(Color.brandPrimary)

                            if vm.isGeneratingTodayInsight {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("I’m right here… just gathering a thought for you.")
                                        .font(.footnote)
                                        .foregroundStyle(Color.brandPrimary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else if let insight = vm.todayInsightText, !insight.isEmpty {
                                VStack(spacing: 4) {
                                    AIInsightBubbleView(
                                        text: insight,
                                        avatarSystemImage: "person.crop.circle.fill"
                                    )

                                    Button(action: {
                                        onTalkToMeAboutIt?(insight)
                                        selectedTab = 1
                                    }) {
                                        HStack(spacing: 4) {
                                            Text("Talk it through with me")
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(Color.brandPrimary.opacity(0.7))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.trailing, 36)
                                }
                            } else {
                                Text("Share how you’re feeling above, and I’ll reflect with you gently.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if let err = vm.lastError {
                                Text(err)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(18)
                        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        // 3. Cope — one clear next step
                        VStack(alignment: .leading, spacing: 12) {
                            loopSectionLabel("Beside you")
                            healingFocusTipCard(proxy: proxy)
                        }

                        // 4. Track — progress only
                        VStack(alignment: .leading, spacing: 12) {
                            loopSectionLabel("Your path")
                            weekSnapshotCard(proxy: proxy)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 54)
                    .padding(.bottom, 16)
                    .safeAreaPadding(.top)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
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
            .background {
                Color.appBackgroundGradient.ignoresSafeArea()
            }

            homeAccountMenu
                .padding(.trailing, 16)
                .safeAreaPadding(.top)
                .padding(.top, 4)
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackView()
        }
        .sheet(isPresented: $showNoContactSheet) {
            CounterView(showsDismissButton: true)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Leave this space?", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                LocalProfileStore.signOut()
            }
        } message: {
            Text("Your journal and check-ins stay safely on this device. Come back to this space whenever you’re ready.")
        }
        .onAppear {
            updateGreeting()
            Task {
                await vm.loadHomeSummary()
            }
        }
    }

    private var homeAccountMenu: some View {
        Menu {
            Section("When you need a hand") {
                Button {
                    selectedTab = 1
                } label: {
                    Label("Keep talking with me", systemImage: "bubble.left.and.bubble.right")
                }

                Button {
                    selectedTab = 2
                } label: {
                    Label("Open your journal", systemImage: "book.pages")
                }
            }

            Section("This space") {
                Button {
                    showProfileSheet = true
                } label: {
                    Label("Profile", systemImage: "person.crop.circle")
                }

                Button {
                    showSettingsSheet = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }

                Button {
                    showFeedbackSheet = true
                } label: {
                    Label("Feedback", systemImage: "envelope")
                }

                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    Label("Leave this space for now", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            if !profileImageData.isEmpty, let uiImage = UIImage(data: profileImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.brandPrimary, lineWidth: 1)
                    )
            } else {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.brandPrimary)
            }
        }
        .accessibilityLabel("Profile menu")
    }

    private func loopSectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.8)
            .foregroundStyle(Color.brandPrimary.opacity(0.55))
    }

    private func healingFocusTipCard(proxy: ScrollViewProxy) -> some View {
        let tip = healingFocusTip

        return Button {
            handleHealingFocusTip(tip, proxy: proxy)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: tip.icon)
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 42, height: 42)
                    .background(Color.brandPrimary.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text("A gentle next step")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.65))

                    Text(tip.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)

                    Text(tip.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Text(tip.actionLabel)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color.cardGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("A gentle next step. \(tip.title). \(tip.message)")
        .accessibilityHint(tip.actionLabel)
    }

    private func handleHealingFocusTip(_ tip: HealingFocusTip, proxy: ScrollViewProxy) {
        switch tip.destination {
        case .noContact:
            showNoContactSheet = true
        case .calmSpace:
            selectedTab = 3
        case .journal:
            selectedTab = 2
        case .checkIn:
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("dailyCheckIn", anchor: .center)
            }
        }
    }

    private func weekSnapshotCard(proxy: ScrollViewProxy) -> some View {
        let insight = vm.weeklyTrackInsight

        return VStack(alignment: .leading, spacing: 14) {
            // Compact no-contact progress
            Button {
                showNoContactSheet = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.body)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 34, height: 34)
                        .background(Color.brandPrimary.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No contact")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)

                        Text(noContactTrackSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if noContactIsActive {
                        Text("\(noContactDays)")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(Color.sageGreen)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.4))
                }
                .padding(14)
                .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(noContactIsActive ? "No contact, \(noContactDays) days" : "Start no contact tracker")

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("This week")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)

                    Spacer()

                    if vm.weeklyCheckInCount > 0 {
                        Text(vm.weeklyCheckInCount == 1 ? "1 check-in" : "\(vm.weeklyCheckInCount) check-ins")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary.opacity(0.55))
                    }
                }

                Text(insight.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionLabel = insight.actionLabel, let destination = insight.destination {
                    Button {
                        handleTrackInsight(destination: destination, proxy: proxy)
                    } label: {
                        HStack(spacing: 4) {
                            Text(actionLabel)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                insight.isHeavy ? Color.orange.opacity(0.12) : Color.cardSurface,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .padding(18)
        .background(Color.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func handleTrackInsight(destination: HealingFocusTipDestination, proxy: ScrollViewProxy) {
        switch destination {
        case .noContact:
            showNoContactSheet = true
        case .calmSpace:
            selectedTab = 3
        case .journal:
            selectedTab = 2
        case .checkIn:
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("dailyCheckIn", anchor: .center)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MoodEntry.self, configurations: config)
    let context = ModelContext(container)
    
    let repo = SwiftDataMoodRepository(context: context)
    
    let vm = HomeViewModel(
        moodRepo: repo,
        aiService: PreviewAIInsightService(),
        userID: "preview-user",
        userName: "Friend"
    )
    
    HomeView(vm: vm, selectedTab: .constant(0))
}
