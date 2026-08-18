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
    @AppStorage("profileImageData") private var profileImageData: Data = Data()
    @State private var showProfileSheet = false
    @State private var showSettingsSheet = false
    @State private var showLogoutConfirmation = false
    
    private let moods = [
        "Calm", "Sad", "Angry", "Anxious",
        "Okay", "Hopeful", "Tired", "Lonely", "Empty"
    ]
    
    @State private var vm: HomeViewModel
    @Binding var selectedTab: Int
    private let onTalkToMeAboutIt: ((String) -> Void)?
    
    // MARK: - Greeting
    @State private var timeBasedGreeting: String = "Good morning"
    
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()
                    .dismissKeyboardOnTap()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
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

                            Text("Getting through today, one step at a time.")
                                .font(.subheadline)
                                .foregroundStyle(Color.brandPrimary)

                            AffirmationView()
                                .padding(.top, 4)
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color.white.opacity(0.96), Color.brandPrimary.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily check-in")
                                .font(.headline)
                                .foregroundStyle(Color.brandPrimary)

                            MoodsSectionView(
                                moods: moods,
                                selectedMoods: $vm.selectedMoods,
                                notesText: $vm.notesText
                            ) { _ in
                                Task { await vm.apply() }
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Your reflection")
                                .font(.headline)
                                .foregroundStyle(Color.brandPrimary)

                            if vm.isGeneratingTodayInsight {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("I’m here with you… just a moment.")
                                        .font(.footnote)
                                        .foregroundStyle(Color.brandPrimary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if let insight = vm.todayInsightText, !insight.isEmpty {
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
                                            Text("Talk to me about it")
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(Color.brandPrimary.opacity(0.7))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.trailing, 36)
                                }
                            }

                            if let err = vm.lastError {
                                Text(err)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                        weekSnapshotCard
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 110)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Section("Quick Actions") {
                                Button {
                                    selectedTab = 1
                                } label: {
                                    Label("Continue Chat", systemImage: "bubble.left.and.bubble.right")
                                }

                                Button {
                                    selectedTab = 2
                                } label: {
                                    Label("Open Journal", systemImage: "book.pages")
                                }
                            }

                            Section("Account") {
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

                                Button(role: .destructive) {
                                    showLogoutConfirmation = true
                                } label: {
                                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            }
                        } label: {
                            if !profileImageData.isEmpty, let uiImage = UIImage(data: profileImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.brandPrimary, lineWidth: 1)
                                    )
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .font(.title2)
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showProfileSheet) {
                    ProfileView()
                }
                .sheet(isPresented: $showSettingsSheet) {
                    SettingsView()
                }
                .alert("Log out?", isPresented: $showLogoutConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Log Out", role: .destructive) {
                        userName = ""
                        profileImageData = Data()
                        isLoggedIn = false
                    }
                } message: {
                    Text("You can sign back in anytime. Your saved journal data stays on the device unless you clear it.")
                }
            }
            .onAppear {
                updateGreeting()
                Task {
                    await vm.loadHomeSummary()
                }
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
    }

    private var weekSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Your healing week", systemImage: "calendar")
                        .font(.headline)
                        .foregroundStyle(Color.brandPrimary)
                    Text(vm.weeklySummaryLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.brandPrimary)
                    .padding(10)
                    .background(Color.brandPrimary.opacity(0.10))
                    .clipShape(Circle())
            }

            // Metrics row
            HStack(spacing: 10) {
                summaryMetric(icon: "checkmark.circle.fill", title: "Check-ins", value: "\(vm.weeklyCheckInCount)")
                summaryMetric(icon: "note.text",            title: "Notes",      value: "\(vm.weeklyNoteCount)")
            }

            if let warning = vm.weeklyWarningText {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .padding(.top, 2)

                    Text(warning)
                        .font(.footnote)
                        .foregroundStyle(Color.brandPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What's helping your healing")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text(vm.weeklyHelpfulPatternText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.brandPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(Color.white.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if !vm.weeklyMoodCounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most common moods")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    let maxCount = max(vm.weeklyMoodCounts.first?.count ?? 1, 1)
                    ForEach(vm.weeklyMoodCounts.prefix(4)) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.mood)
                                    .font(.footnote.weight(.medium))
                                Spacer()
                                Text("\(item.count)")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }

                            GeometryReader { proxy in
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.brandPrimary.opacity(0.85))
                                    .frame(width: proxy.size.width * CGFloat(item.count) / CGFloat(maxCount), height: 8)
                            }
                            .frame(height: 8)
                        }
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if !vm.weeklyTrendBars.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mood trend")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(vm.weeklyTrendBars) { bar in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(bar.averageScore >= 0.25 ? Color.green.opacity(0.85) : bar.averageScore <= -0.25 ? Color.red.opacity(0.8) : Color.brandPrimary.opacity(0.8))
                                    .frame(height: CGFloat(18 + 42 * bar.normalizedHeight))

                                Text(bar.dayLabel)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(bar.dayLabel), \(bar.entryCount) check-ins")
                        }
                    }
                    .frame(height: 78)

                    HStack(spacing: 12) {
                        legendDot(color: Color.green.opacity(0.85), label: "Lighter")
                        legendDot(color: Color.brandPrimary.opacity(0.8), label: "Mixed")
                        legendDot(color: Color.red.opacity(0.8), label: "Heavier")
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }

            if vm.weeklyCheckInCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary.opacity(0.70))
                    
                    // Modern concatenation using nested Text interpolation
                    Text("Last check-in: \(Text(vm.latestCheckInText).font(.caption).foregroundStyle(.secondary))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.70))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.brandPrimary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.96), Color.brandPrimary.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func summaryMetric(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Color.brandPrimary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.90))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
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
