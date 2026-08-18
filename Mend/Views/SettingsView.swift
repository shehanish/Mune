//
//  SettingsView.swift
//  Mend
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
    @AppStorage("saveDrawingsEnabled")   private var saveDrawingsEnabled   = false

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionDeniedAlert = false
    @State private var reminderTime = Date()

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
                                Toggle("Remind me to check in", isOn: Binding(
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

                                    Text("A gentle nudge to check in and reflect on your day.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if notificationStatus == .denied {
                                    Label("Notifications are blocked. Enable them in Settings → Mend.", systemImage: "bell.slash")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }

                        // MARK: Display card
                        settingsCard(title: "Display") {
                            Toggle("Helpful hints", isOn: $healingHintsEnabled)
                            Text("Show gentle tips and prompts throughout the app.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, -6)

                            Toggle("Reduce motion", isOn: $reduceMotionEnabled)
                            Text("Turns off animated blobs and transitions.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, -6)
                        }

                        settingsCard(title: "Calm Space") {
                            Toggle("Save drawings", isOn: Binding(
                                get: { saveDrawingsEnabled },
                                set: { newValue in
                                    saveDrawingsEnabled = newValue
                                    if !newValue {
                                        UserDefaults.standard.removeObject(forKey: "savedCalmSpaceDoodles")
                                    }
                                }
                            ))
                            Text("Keep doodles on this device. Turn this off if you want drawings to stay temporary.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, -6)
                        }

                        // MARK: Account card
                        settingsCard(title: "Account") {
                            Text("Use Profile to change your name or photo. Use Sign Out in Profile to leave the app.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        // MARK: Legal card
                        settingsCard(title: "Legal") {
                            Link(destination: URL(string: "https://shehanish.github.io/Mend/privacy-policy.html")!) {
                                Label("Privacy Policy", systemImage: "hand.raised.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.brandPrimary)
                            }
                            Divider()
                            Text("Mend is a wellness support tool. It is not a substitute for professional mental health care. If you are in crisis, call or text 988.")
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
            .alert("Notifications blocked", isPresented: $showPermissionDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications for Mend in your iPhone Settings to receive daily reminders.")
            }
            .onAppear { loadState() }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Make Mend yours")
                .font(.title2.bold())
                .foregroundStyle(Color.brandPrimary)

            Text("Adjust what helps most and tone down what feels like too much.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.88))
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
        .background(Color.white.opacity(0.88))
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
        center.removePendingNotificationRequests(withIdentifiers: ["mend.daily.reminder"])

        let content          = UNMutableNotificationContent()
        content.title        = "Time to check in 🌿"
        content.body         = "How are you feeling today? A few moments of reflection can make a difference."
        content.sound        = .default

        var dateComponents   = DateComponents()
        dateComponents.hour  = hour
        dateComponents.minute = minute

        let trigger          = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request          = UNNotificationRequest(identifier: "mend.daily.reminder", content: content, trigger: trigger)

        center.add(request)
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["mend.daily.reminder"])
    }
}

#Preview {
    SettingsView()
}