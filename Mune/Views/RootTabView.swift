//
//  RootTabView.swift
//  Mune
//
//  Created by Shehani Hansika on 07.05.26.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("userName") private var userName = "Friend"
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @State private var selectedTab: Int = 0

    // Keep VMs in State so they are only created once and don't leak memory on re-renders
    @State private var homeVM: HomeViewModel?
    @State private var chatVM: ChatViewModel?
    @State private var journalVM: JournalViewModel?
    @State private var boundProfileID: String = ""

    private var userID: String {
        activeProfileID.isEmpty ? LocalProfileStore.legacyUserID : activeProfileID
    }

    var body: some View {
        
        ZStack {
            if let homeVM = homeVM, let chatVM = chatVM, let journalVM = journalVM {
                TabView(selection: $selectedTab) {
                    HomeView(
                        vm: homeVM,
                        selectedTab: $selectedTab,
                        onTalkToMeAboutIt: { message in
                            chatVM.queueConversationStarter(message)
                        }
                    )
                        .tabItem { Label("Home", systemImage: "house") }
                        .tag(0)

                    ChatView(vm: chatVM)
                        .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                        .tag(1)

                    JournalView(vm: journalVM)
                        .tabItem { Label("Journal", systemImage: "note.text") }
                        .tag(2)
                        
                    CalmSpaceView()
                        .tabItem { Label("Calm Space", systemImage: "heart.fill") }
                        .tag(3)
                }
                .tint(Color.brandPrimary)
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            } else {
                ProgressView() // Show loading until VMs initialize
            }
        }
        .onAppear {
            LocalProfileStore.migrateLegacyIfNeeded()
            setupViewModels(force: false)
            applyScreenshotLaunchArguments()
        }
        .onChange(of: activeProfileID) { _, newID in
            guard !newID.isEmpty, newID != boundProfileID else { return }
            setupViewModels(force: true)
        }
        .onChange(of: userName) { _, newName in
            // Keep the active profile display name in sync when edited from Profile.
            guard !activeProfileID.isEmpty else { return }
            LocalProfileStore.updateDisplayName(newName, for: activeProfileID)
            homeVM = nil
            chatVM = nil
            journalVM = nil
            setupViewModels(force: true)
        }
    }

    private func applyScreenshotLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-tab-chat") {
            selectedTab = 1
        } else if args.contains("-tab-journal") {
            selectedTab = 2
        } else if args.contains("-tab-calm") || args.contains("-open-urge-wave") {
            selectedTab = 3
        }
    }
    
    private func setupViewModels(force: Bool) {
        if !force, homeVM != nil, boundProfileID == userID { return }

        let moodRepo = SwiftDataMoodRepository(context: modelContext)
        let aiService: any AIInsightService = OpenAIInsightService(
            apiKey: AppConfig.useDirectAuth ? AppConfig.apiKey : "",
            endpointURL: AppConfig.chatEndpointURL
        )

        homeVM = HomeViewModel(
            moodRepo: moodRepo,
            aiService: aiService,
            userID: userID,
            userName: userName
        )
        
        journalVM = JournalViewModel(context: modelContext, moodRepo: moodRepo, userID: userID, userName: userName)

        chatVM = ChatViewModel(
            aiService: aiService,
            userName: userName,
            contextProvider: {
                guard let homeVM, let journalVM else {
                    return nil
                }

                return chatContext(homeVM: homeVM, journalVM: journalVM)
            }
        )

        boundProfileID = userID
    }

    private func chatContext(homeVM: HomeViewModel, journalVM: JournalViewModel) -> ChatInsightContext {
        let recentMoodHighlights = journalVM.moodEntries.prefix(3).map { entry in
            let moods = entry.moods.isEmpty ? "No mood selected" : entry.moods.joined(separator: ", ")
            let note = entry.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if note.isEmpty {
                return moods
            }

            return "\(moods): \(note)"
        }

        let recentJournalHighlights = journalVM.historyEntries.prefix(3).map { entry in
            let journal = entry.journalText.trimmingCharacters(in: .whitespacesAndNewlines)
            let transcript = entry.transcript?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let gratitudes = [entry.gratitudeOne, entry.gratitudeTwo, entry.gratitudeThree]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            var parts: [String] = []

            if !journal.isEmpty {
                parts.append("Journal: \(journal)")
            }

            if !transcript.isEmpty {
                parts.append("Transcript: \(transcript)")
            }

            if !gratitudes.isEmpty {
                parts.append("Gratitudes: \(gratitudes.joined(separator: " | "))")
            }

            return parts.isEmpty ? "Recent entry" : parts.joined(separator: " • ")
        }

        return ChatInsightContext(
            weeklySummaryLine: homeVM.weeklySummaryLine,
            weeklyHelpfulPatternText: homeVM.weeklyHelpfulPatternText,
            weeklyWarningText: homeVM.weeklyWarningText,
            latestCheckInText: homeVM.latestCheckInText,
            healingTrendText: journalVM.healingDashboard.moodTrend,
            healingSupportMessage: journalVM.healingDashboard.supportMessage,
            healingThemes: journalVM.healingDashboard.themes,
            recentMoodHighlights: recentMoodHighlights,
            recentJournalHighlights: recentJournalHighlights
        )
    }
}

// MARK: - Stub AI service (safe until you wire OpenAI key)
private struct PreviewAIInsightService: AIInsightService {
    func generateMoodInsight(from input: MoodInsightInput, userName: String) async throws -> String {
        "You're making progress. Log a mood to see insights."
    }
    func generateChatResponse(conversation: [(isUser: Bool, text: String)], userName: String, context: ChatInsightContext?) async throws -> String {
        "I'm here for you. Take things one day at a time."
    }
}

#Preview {
    RootTabView()
    .modelContainer(for: [MoodEntry.self, JournalEntry.self], inMemory: true)
}
