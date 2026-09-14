import SwiftUI
import Combine

enum HealingDaysTracker {
    /// Session keys used while a profile is active (shared AppStorage).
    static let isActiveKey = "healingDaysIsActive"
    static let startDateKey = "healingDaysStartDate"
    static let goalKey = "healingDaysGoal"

    /// Legacy unscoped keys (pre multi-profile).
    static let legacyIsActiveKey = "healingDaysIsActive"
    static let legacyStartDateKey = "healingDaysStartDate"
    static let legacyGoalKey = "healingDaysGoal"

    static let defaultGoal = "Unlimited / Not Decided"

    static func isActiveKey(for profileID: String) -> String { "healingDaysIsActive.\(profileID)" }
    static func startDateKey(for profileID: String) -> String { "healingDaysStartDate.\(profileID)" }
    static func goalKey(for profileID: String) -> String { "healingDaysGoal.\(profileID)" }

    static func daysElapsed(since startDate: Date, to now: Date = .now) -> Int {
        let components = Calendar.current.dateComponents([.day], from: startDate, to: now)
        return max(0, components.day ?? 0)
    }

    static func startDate(from interval: Double) -> Date? {
        interval > 0 ? Date(timeIntervalSince1970: interval) : nil
    }

    static func activate(startDate: Date, goal: String) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: isActiveKey)
        defaults.set(startDate.timeIntervalSince1970, forKey: startDateKey)
        defaults.set(goal, forKey: goalKey)

        let profileID = LocalProfileStore.activeProfileID
        if !profileID.isEmpty {
            persistSessionIntoScoped(for: profileID)
        }
    }

    static func reset() {
        clearSessionKeys()
        let profileID = LocalProfileStore.activeProfileID
        if !profileID.isEmpty {
            persistSessionIntoScoped(for: profileID)
        }
    }

    static func clearSessionKeys() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: isActiveKey)
        defaults.set(0.0, forKey: startDateKey)
        defaults.set("", forKey: goalKey)
    }

    static func persistSessionIntoScoped(for profileID: String) {
        guard !profileID.isEmpty else { return }
        let defaults = UserDefaults.standard
        defaults.set(defaults.bool(forKey: isActiveKey), forKey: isActiveKey(for: profileID))
        defaults.set(defaults.double(forKey: startDateKey), forKey: startDateKey(for: profileID))
        defaults.set(defaults.string(forKey: goalKey) ?? "", forKey: goalKey(for: profileID))
    }

    static func loadScopedIntoSession(for profileID: String) {
        guard !profileID.isEmpty else {
            clearSessionKeys()
            return
        }
        let defaults = UserDefaults.standard
        defaults.set(defaults.bool(forKey: isActiveKey(for: profileID)), forKey: isActiveKey)
        defaults.set(defaults.double(forKey: startDateKey(for: profileID)), forKey: startDateKey)
        defaults.set(defaults.string(forKey: goalKey(for: profileID)) ?? "", forKey: goalKey)
    }

    /// Copy old global keys into a profile bucket once (values already live in session keys).
    static func migrateLegacyKeysIfNeeded(into profileID: String) {
        let defaults = UserDefaults.standard
        let scopedActive = isActiveKey(for: profileID)
        guard defaults.object(forKey: scopedActive) == nil else { return }

        defaults.set(defaults.bool(forKey: legacyIsActiveKey), forKey: scopedActive)
        defaults.set(defaults.double(forKey: legacyStartDateKey), forKey: startDateKey(for: profileID))
        defaults.set(defaults.string(forKey: legacyGoalKey) ?? "", forKey: goalKey(for: profileID))
    }
}

struct HealingDaysSetupSheet: View {
    @Binding var selectedDate: Date
    @Binding var selectedPeriod: String?
    var onSave: () -> Void
    
    @State private var customDays: String = ""
    
    private let periodOptions = [
        "30 Days",
        "60 Days",
        "90 Days",
        "Unlimited / Not Decided",
        "Custom"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        Text("Start your day count")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.textOnPrimary)
                            .padding(.top, 20)

                        Text("Set the last time you contacted them. The counter starts from there.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.textOnPrimary.opacity(0.75))
                            .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("When was the last contact?")
                                .font(.subheadline)
                                .foregroundStyle(Color.textOnPrimary.opacity(0.8))
                                .padding(.horizontal, 20)

                            DatePicker(
                                "Last contact",
                                selection: $selectedDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color.fieldSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }

                        DropDownView(
                            title: "Optional goal",
                            prompt: "How long do you want to aim for?",
                            options: periodOptions,
                            selection: $selectedPeriod
                        )
                        .padding(.top, 10)

                        if selectedPeriod == "Custom" {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How many days?")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textOnPrimary.opacity(0.8))
                                    .padding(.horizontal, 20)

                                TextField("e.g. 14", text: $customDays)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.fieldSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                                                        .padding(.horizontal)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Spacer(minLength: 30)

                        Button(action: {
                            if selectedPeriod == "Custom" && !customDays.isEmpty {
                                selectedPeriod = "\(customDays) Days"
                            }
                            onSave()
                        }) {
                            Text("Save and begin")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background((selectedPeriod != nil && (selectedPeriod != "Custom" || !customDays.isEmpty)) ? Color.brandPrimary : Color.brandPrimary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(selectedPeriod == nil || (selectedPeriod == "Custom" && customDays.isEmpty))
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                    .animation(.snappy, value: selectedPeriod)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }
}

// MARK: - Active Tracker View
struct ActiveTrackerView: View {
    let startDate: Date
    let goal: String?
    let onReset: () -> Void
    
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var goalDays: Double? {
        guard let goal = goal else { return nil }
        if goal.contains("Unlimited") || goal.contains("Not Decided") {
            return nil
        }
        let daysString = goal.replacingOccurrences(of: " Days", with: "").trimmingCharacters(in: .whitespaces)
        return Double(daysString)
    }
    
    private var progress: Double {
        guard let goalDays = goalDays, goalDays > 0 else { return 1.0 }
        let totalSeconds = goalDays * 24 * 60 * 60
        let elapsedSeconds = now.timeIntervalSince(startDate)
        let calculatedProgress = elapsedSeconds / totalSeconds
        return min(max(calculatedProgress, 0.0), 1.0)
    }
    
    private var daysElapsed: Int {
        let components = Calendar.current.dateComponents([.day], from: startDate, to: now)
        return max(0, components.day ?? 0)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 8) {
                Text("Healing days")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textOnPrimary)

                Text("Days since you last contacted them")
                    .font(.subheadline)
                    .foregroundColor(Color.textOnPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            ZStack {
                Circle()
                    .stroke(Color.sageGreen.opacity(0.4), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        Color.sageGreen,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: progress)
                
                VStack(spacing: 8) {
                    Text("\(daysElapsed)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(Color.brandPrimary)
                    
                    Text(daysElapsed == 1 ? "Day without contact" : "Days without contact")
                        .font(.headline)
                        .foregroundColor(Color.brandPrimary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if let goalDays = goalDays {
                        Text("Goal: \(Int(goalDays)) Days")
                            .font(.caption)
                            .padding(.top, 4)
                            .foregroundColor(Color.brandPrimary.opacity(0.7))
                    } else {
                        Text("Goal: Open-ended")
                            .font(.caption)
                            .padding(.top, 4)
                            .foregroundColor(Color.brandPrimary.opacity(0.7))
                    }
                }
            }
            .frame(width: 280, height: 280)
            
            HStack(spacing: 20) {
                timeComponentView(title: "Hours", value: Calendar.current.dateComponents([.hour], from: startDate, to: now).hour.map { $0 % 24 } ?? 0)
                timeComponentView(title: "Mins", value: Calendar.current.dateComponents([.minute], from: startDate, to: now).minute.map { $0 % 60 } ?? 0)
                timeComponentView(title: "Secs", value: Calendar.current.dateComponents([.second], from: startDate, to: now).second.map { $0 % 60 } ?? 0)
            }
            .padding()
            .background(Color.sageGreen.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Button("Reset day count") {
                onReset()
            }
            .font(.headline)
            .padding()
            .background(Color.warmGray)
            .foregroundStyle(.red)
            .clipShape(Capsule())
            .padding(.top, 20)
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }
    
    private func timeComponentView(title: String, value: Int) -> some View {
        VStack {
            Text(String(format: "%02d", max(0, value)))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.brandPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(Color.brandPrimary.opacity(0.8))
        }
        .frame(width: 60)
    }
}
