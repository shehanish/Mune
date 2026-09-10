//
//  SettingsView.swift
//  Mune
//
//  Created by GitHub Copilot.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("dailyRemindersEnabled") private var dailyRemindersEnabled = false
    @AppStorage("reminderHour")          private var reminderHour          = 20   // 8 PM default
    @AppStorage("reminderMinute")        private var reminderMinute        = 0
    @AppStorage("healingHintsEnabled")   private var healingHintsEnabled   = true
    @AppStorage("reduceMotionEnabled")   private var reduceMotionEnabled   = false
    @AppStorage("activeProfileID")       private var activeProfileID       = ""

    @State private var saveDrawingsEnabled = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionDeniedAlert = false
    @State private var reminderTime = Date()
    @State private var showFeedbackSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header

                        // MARK: Notifications card
                        settingsCard(title: "A gentle reminder") {
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle("Remind me to check in with myself", isOn: Binding(
                                    get: { dailyRemindersEnabled },
                                    set: { newValue in
                                        if newValue {
                                            requestAndSchedule()
                                        } else {
                                            dailyRemindersEnabled = false
                                            cancelReminder()
                                        }
                                    }
                                ))

                                if dailyRemindersEnabled {
                                    DatePicker(
                                        "Reminder time",
                                        selection: $reminderTime,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .onChange(of: reminderTime) { _, newTime in
                                        let cal = Calendar.current
                                        reminderHour   = cal.component(.hour,   from: newTime)
                                        reminderMinute = cal.component(.minute, from: newTime)
                                        scheduleReminder(hour: reminderHour, minute: reminderMinute)
                                    }

                                    Text("A soft nudge to pause and check in with your heart.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if notificationStatus == .denied {
                                    Label("Notifications are blocked. You can enable them in Settings → Mune when you’re ready.", systemImage: "bell.slash")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }

                        // MARK: Display card
                        settingsCard(title: "Display") {
                            Toggle("Gentle hints", isOn: $healingHintsEnabled)
                            Text("Show soft tips and prompts as we move through the app together.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, -6)

                            Toggle("Reduce motion", isOn: $reduceMotionEnabled)
                            Text("Turns off moving animations if they feel like too much.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, -6)
                        }

                        settingsCard(title: "Calm Space") {
                            Toggle("Save drawings", isOn: Binding(
                                get: { saveDrawingsEnabled },
                                set: { newValue in
                                    saveDrawingsEnabled = newValue
                                    let profileID = CalmSpaceViewModel.currentProfileID()
                                    UserDefaults.standard.set(newValue, forKey: CalmSpaceViewModel.enabledKey(for: profileID))
                                    UserDefaults.standard.set(newValue, forKey: CalmSpaceViewModel.saveDrawingsEnabledKey)
                                    if !newValue {
                                        CalmSpaceViewModel.clearDrawings(for: profileID)
                                    }
                                }
                            ))
                            Text("Keep named drawings in a private folder for this space. Turn off if you only want to draw for the moment.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, -6)
                        }

                        // MARK: Feedback card
                        settingsCard(title: "Feedback") {
                            Text("Tell me what would help you more. Screenshots are welcome.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Button {
                                showFeedbackSheet = true
                            } label: {
                                Label("Feedback", systemImage: "envelope.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }

                        // MARK: Account card
                        settingsCard(title: "This space") {
                            Text("Use Profile to change your name or photo. Leave this space anytime from Profile. Your pages stay safely on this device.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        // MARK: Legal card
                        settingsCard(title: "Legal") {
                            Link(destination: URL(string: "https://shehanish.github.io/Mune/privacy-policy.html")!) {
                                Label("Privacy Policy", systemImage: "hand.raised.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.brandPrimary)
                            }
                            Divider()
                            Text("Mune offers kind breakup support. It is not therapy, medical care, or a crisis service. If you’re in crisis, find a local helpline or call your local emergency number.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackView()
            }
            .alert("Notifications need a quick yes", isPresented: $showPermissionDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To receive gentle reminders, please allow notifications for Mune in your iPhone Settings.")
            }
            .onAppear { loadState() }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Make this space feel like yours")
                .font(.title2.bold())
                .foregroundStyle(Color.brandPrimary)

            Text("Keep what helps, soften what feels like too much.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            content()
                .font(.subheadline)
                .tint(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Notification helpers

    private func loadState() {
        CalmSpaceViewModel.migrateUnscopedDrawingsIfNeeded()
        let profileID = CalmSpaceViewModel.currentProfileID()
        if let stored = UserDefaults.standard.object(forKey: CalmSpaceViewModel.enabledKey(for: profileID)) as? Bool {
            saveDrawingsEnabled = stored
        } else {
            saveDrawingsEnabled = UserDefaults.standard.bool(forKey: CalmSpaceViewModel.saveDrawingsEnabledKey)
        }

        // Restore reminder time picker from saved hour/minute
        var comps        = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour       = reminderHour
        comps.minute     = reminderMinute
        reminderTime     = Calendar.current.date(from: comps) ?? Date()

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
                // If permission was revoked externally, sync the toggle
                if settings.authorizationStatus == .denied { dailyRemindersEnabled = false }
            }
        }
    }

    private func requestAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    notificationStatus        = .authorized
                    dailyRemindersEnabled     = true
                    scheduleReminder(hour: reminderHour, minute: reminderMinute)
                } else {
                    notificationStatus        = .denied
                    dailyRemindersEnabled     = false
                    showPermissionDeniedAlert = true
                }
            }
        }
    }

    private func scheduleReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [AppConfig.dailyReminderIdentifier])

        let content          = UNMutableNotificationContent()
        content.title        = "A soft check-in 🌿"
        content.body         = "How is your heart today? Even a few quiet moments with yourself can help."
        content.sound        = .default

        var dateComponents   = DateComponents()
        dateComponents.hour  = hour
        dateComponents.minute = minute

        let trigger          = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request          = UNNotificationRequest(identifier: AppConfig.dailyReminderIdentifier, content: content, trigger: trigger)

        center.add(request)
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [AppConfig.dailyReminderIdentifier])
    }
}

#Preview {
    SettingsView()
}