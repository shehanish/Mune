//
//  SettingsView.swift
//  Mune
//
//  Created by GitHub Copilot.
//

import SwiftUI
import UserNotifications
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage("dailyRemindersEnabled") private var dailyRemindersEnabled = false
    @AppStorage("reminderHour")          private var reminderHour          = 20   // 8 PM default
    @AppStorage("reminderMinute")        private var reminderMinute        = 0
    @AppStorage("reduceMotionEnabled")   private var reduceMotionEnabled   = false
    @AppStorage("userName")              private var userName              = ""
    @AppStorage("activeProfileID")       private var activeProfileID       = ""

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionDeniedAlert = false
    @State private var reminderTime = Date()
    @State private var showFeedbackSheet = false
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var exportErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header

                        // MARK: Notifications card
                        settingsCard(title: "Daily reminder") {
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

                                    Text("A quick nudge to check in with yourself.")
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
                            Toggle("Reduce motion", isOn: $reduceMotionEnabled)
                            Text("Turns off blob and breathing animations. Also follows your iPhone Reduce Motion setting.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, -6)
                        }

                        // MARK: Feedback card
                        settingsCard(title: "Feedback") {
                            Text("Tell me what’s helping, what’s confusing, or what you’d change. Screenshots help.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Button {
                                showFeedbackSheet = true
                            } label: {
                                Label("Send feedback", systemImage: "envelope.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }

                        // MARK: Your data
                        settingsCard(title: "Your data") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("What stays on this device")
                                    .font(.subheadline.weight(.semibold))
                                Text("Journal, check-ins, rebuild steps, reality checks, recovery snapshots, drawings, and your profile.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("What may leave this device")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.top, 4)
                                Text("Chat messages and check-in insights may be sent to AI to generate replies. Feedback you send goes by email.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Button {
                                    exportData()
                                } label: {
                                    Label("Export my data", systemImage: "square.and.arrow.up")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.brandPrimary)
                                }
                                .padding(.top, 4)
                            }
                        }

                        // MARK: Account card
                        settingsCard(title: "This space") {
                            Text("Change your name, photo, and healing focus in Profile. Leave anytime from Profile. Drawings save from the drawing page in Calm Space.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        // MARK: Legal card
                        settingsCard(title: "Legal") {
                            Link(destination: CrisisResources.privacyPolicyURL) {
                                Label("Privacy Policy", systemImage: "hand.raised.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.brandPrimary)
                            }
                            Divider()
                            Link(destination: CrisisResources.termsOfUseURL) {
                                Label("Terms of Use", systemImage: "doc.text.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.brandPrimary)
                            }
                            Divider()
                            Text("Mune offers support. It is not therapy, medical care, or a crisis service. If you’re in crisis, find a local helpline or call your local emergency number.")
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
            .sheet(isPresented: $showExportSheet, onDismiss: {
                exportURL = nil
            }) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .alert("Couldn’t export", isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { if !$0 { exportErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportErrorMessage ?? "")
            }
            .alert("Notifications need a quick yes", isPresented: $showPermissionDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("To get reminders, allow notifications for Mune in iPhone Settings.")
            }
            .onAppear { loadState() }
        }
    }

    private func exportData() {
        let userID = activeProfileID.isEmpty ? LocalProfileStore.legacyUserID : activeProfileID
        if let url = DataExportService.exportText(userID: userID, userName: userName, context: modelContext) {
            exportURL = url
            showExportSheet = true
        } else {
            exportErrorMessage = "I couldn’t create the export file just now."
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Make this feel like yours")
                .font(.title2.bold())
                .foregroundStyle(Color.brandPrimary)

            Text("Keep what helps. Turn off what doesn’t.")
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
        content.title        = "Quick check-in"
        content.body         = "How are you today? Take a minute when you can."
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

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}