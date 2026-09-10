import SwiftUI

// MARK: - AuthView
// 4-page onboarding: Welcome → Name → Focus → Complete
// Fully local — no account required (App Store compliant).

struct AuthView: View {

    // MARK: - Persisted state
    @AppStorage("isLoggedIn")   var isLoggedIn   = false
    @AppStorage("userName")     var userName     = ""
    @AppStorage("healingFocus") var healingFocus = ""
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Transient state
    @State private var name          = ""
    @State private var step          = 0           // 0 = welcome, 1 = name, 2 = focus, 3 = complete
    @State private var selectedFocuses: Set<String> = ["Healing days"]
    @State private var trackHealingDays = true
    @State private var healingDaysStartDate = Date()
    @State private var didCustomizeHealingDaysStartDate = false
    @State private var showNameError = false
    @State private var goingForward  = true

    // MARK: - Data
    private let focusOptions: [(title: String, subtitle: String, icon: String)] = [
        ("Healing days",       "Be with me when I want to reach out",      "leaf.fill"),
        ("Process the grief",  "A safe place to feel it, write it, say it", "heart.text.square.fill"),
        ("Hard moments",       "Gentle help when I want to text them",     "heart.circle.fill"),
        ("Rebuild my routine", "Small, kind steps back to myself",         "sun.and.horizon.fill"),
    ]

    private let indicatorSteps = 2   // steps 1 & 2 show the dot indicator

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackgroundGradient.ignoresSafeArea()
                Circle()
                    .fill(Color.brandPrimary.opacity(0.07))
                    .frame(width: 320)
                    .blur(radius: 44)
                    .offset(x: 130, y: -240)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                Circle()
                    .fill(Color.sageGreen.opacity(0.09))
                    .frame(width: 290)
                    .blur(radius: 52)
                    .offset(x: -150, y: 320)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                // Content
                VStack(spacing: 0) {
                    if step == 1 || step == 2 {
                        stepIndicator
                            .padding(.top, 18)
                            .padding(.bottom, 2)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    ZStack {
                        if step == 0 { welcomePage.transition(pageTransition) }
                        if step == 1 { namePage.transition(pageTransition) }
                        if step == 2 { focusPage.transition(pageTransition) }
                        if step == 3 { completePage.transition(pageTransition) }
                    }
                }
            }
            .animation(.spring(response: 0.46, dampingFraction: 0.82), value: step)
            .toolbar {
                // Skip — only on name and focus steps
                if step == 1 || step == 2 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") {
                            if step == 1 { advance() } else { completeOnboarding() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.50))
                        .accessibilityLabel(step == 1 ? "Skip name" : "Skip focus selection")
                    }
                }
            }
        }
        // Prevent accidental swipe-dismiss on the completion screen
        .interactiveDismissDisabled(step == 3)
        .onAppear {
            name = (userName.isEmpty || userName == "Friend") ? "" : userName
            let saved = healingFocus.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            var focuses = saved.isEmpty ? ["Healing days"] : Set(saved)
            if focuses.contains("No contact") {
                focuses.remove("No contact")
                focuses.insert("Healing days")
            }
            selectedFocuses = focuses
            refreshHealingDaysStartDateIfNeeded()
        }
        .onChange(of: step) { _, newStep in
            if newStep == 2 {
                refreshHealingDaysStartDateIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshHealingDaysStartDateIfNeeded()
            }
        }
    }

    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(1...indicatorSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color.brandPrimary : Color.brandPrimary.opacity(0.20))
                    .frame(width: index == step ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.38, dampingFraction: 0.75), value: step)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step) of \(indicatorSteps)")
    }

    // MARK: - Page: Welcome
    private var welcomePage: some View {
        VStack(spacing: 22) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Welcome to Mune")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textOnPrimary)

                Text("I’m here to walk with you through this.\nOne soft day at a time.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textOnPrimary.opacity(0.80))
                    .lineSpacing(4)
            }

            VStack(spacing: 10) {
                featurePill(icon: "lock.fill",          label: "Private. Your story stays on your device")
                featurePill(icon: "brain.head.profile", label: "Gentle, breakup-aware support when you need it")
                featurePill(icon: "leaf.fill",          label: "Calm tools for hard, tender moments")
            }

            Text("Mune offers kind support, not therapy or medical care. If you’re in crisis, find a local helpline or call emergency services.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.textOnPrimary.opacity(0.62))
                .padding(.top, 4)

            primaryButton("Walk with me") { advance() }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Page: Name
    private var namePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 28)

                pageHeader(
                    icon: "person.crop.circle.fill",
                    title: "What should I call you?",
                    message: "A first name or nickname is perfect. This little space is yours."
                )
                .padding(.bottom, 28)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Your name or nickname", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .font(.body)
                        .padding(14)
                        .background(Color.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    showNameError ? Color.red.opacity(0.55) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundStyle(Color.brandPrimary)
                        .accessibilityLabel("Name or nickname")
                        .onChange(of: name) { _, _ in
                            if showNameError { showNameError = false }
                        }

                    Group {
                        if showNameError {
                            Label("Could you keep it under 30 characters?", systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red.opacity(0.80))
                        } else if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Label("Hi, \(name.trimmingCharacters(in: .whitespacesAndNewlines)) . It’s so nice to meet you.", systemImage: "hand.wave.fill")
                                .foregroundStyle(Color.textOnPrimary.opacity(0.72))
                        } else {
                            Text("I’ll greet you by this name.")
                                .foregroundStyle(Color.textOnPrimary.opacity(0.60))
                        }
                    }
                    .font(.caption)
                    .animation(.easeInOut(duration: 0.18), value: showNameError)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)

                HStack(spacing: 12) {
                    secondaryButton("Back") { back() }
                    primaryButton("Next") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard trimmed.count <= 30 else {
                            withAnimation { showNameError = true }
                            return
                        }
                        advance()
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Page: Focus
    private var focusPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 28)

                pageHeader(
                    title: "What do you need\nmost right now?",
                    message: "Choose anything that feels true. I’ll gently focus on what matters for your heart right now."
                )
                .padding(.bottom, 24)

                VStack(spacing: 10) {
                    ForEach(focusOptions, id: \.title) { option in
                        focusRow(option)
                    }
                }
                .padding(.horizontal, 24)

                if selectedFocuses.contains("Healing days") || selectedFocuses.contains("No contact") {
                    healingDaysSetupSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 0)
                    .padding(.bottom, 36)

                HStack(spacing: 12) {
                    secondaryButton("Back") { back() }
                    primaryButton("Come into Mune") { completeOnboarding() }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Page: Complete
    private var completePage: some View {
        VStack(spacing: 22) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Welcome in\(nameDisplay).")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textOnPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Your space is ready.\nTake a breath. We’ll go gently, one day at a time.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textOnPrimary.opacity(0.78))
                    .lineSpacing(5)
            }

            primaryButton("Open Mune") {
                if let profile = LocalProfileStore.activeProfile() {
                    LocalProfileStore.activate(profile, signIn: true)
                } else {
                    isLoggedIn = true
                }
                dismiss()
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Reusable Components

    private func featurePill(icon: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.textOnPrimary.opacity(0.84))
            Spacer()
        }
        .padding(14)
        .background(Color.cardSurfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func pageHeader(icon: String? = nil, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.brandPrimary)
                    .padding(12)
                    .background(Color.cardSurfaceSoft)
                    .clipShape(Circle())
                    .padding(.horizontal, 28)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textOnPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.textOnPrimary.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 28)
        }
    }

    private func focusRow(_ option: (title: String, subtitle: String, icon: String)) -> some View {
        let isSelected = selectedFocuses.contains(option.title)
        return Button {
            withAnimation(.snappy) {
                if isSelected {
                    // Keep at least one selected
                    if selectedFocuses.count > 1 { selectedFocuses.remove(option.title) }
                } else {
                    selectedFocuses.insert(option.title)
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 30)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.headline)
                        .foregroundStyle(Color.textOnPrimary)
                    Text(option.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.70))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.textOnPrimary.opacity(0.28))
            }
            .padding(14)
            .background(isSelected ? Color.cardSurface : Color.cardSurfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brandPrimary.opacity(0.30) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title): \(option.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var healingDaysSetupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.brandPrimary.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Gently track my healing days")
                        .font(.headline)
                        .foregroundStyle(Color.textOnPrimary)

                    Text("A quiet count of days since you last had contact, only if it feels helpful.")
                        .font(.caption)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: $trackHealingDays)
                    .labelsHidden()
                    .tint(Color.brandPrimary)
                    .accessibilityLabel("Gently track my healing days")
            }

            if trackHealingDays {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When was the last contact?")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textOnPrimary.opacity(0.58))

                    DatePicker(
                        "When was the last contact?",
                        selection: Binding(
                            get: { healingDaysStartDate },
                            set: { newValue in
                                healingDaysStartDate = newValue
                                didCustomizeHealingDaysStartDate = true
                            }
                        ),
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Color.brandPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.cardSurfaceStrong, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("You can change this anytime from Home. No pressure.")
                        .font(.caption2)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.52))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .background(Color.cardSurfaceMuted, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .animation(.snappy, value: trackHealingDays)
    }

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandFill)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.brandPrimary.opacity(0.25), radius: 10, y: 6)
        }
    }

    private func secondaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cardSurfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: - Actions & Helpers

    private var pageTransition: AnyTransition {
        goingForward
            ? .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
              )
            : .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal:   .move(edge: .trailing).combined(with: .opacity)
              )
    }

    private func advance() {
        goingForward = true
        step = min(step + 1, 3)
    }

    private func back() {
        goingForward = false
        step = max(step - 1, 0)
    }

    private func refreshHealingDaysStartDateIfNeeded() {
        guard !didCustomizeHealingDaysStartDate else { return }
        healingDaysStartDate = Date()
    }

    private func completeOnboarding() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let focus = focusOptions
            .map(\.title)
            .filter { selectedFocuses.contains($0) }
            .joined(separator: ", ")

        let profile = LocalProfileStore.createProfile(
            displayName: trimmed.isEmpty ? "Friend" : trimmed,
            healingFocus: focus
        )
        LocalProfileStore.activate(profile, signIn: false)

        if (selectedFocuses.contains("Healing days") || selectedFocuses.contains("No contact")), trackHealingDays {
            let startDate = didCustomizeHealingDaysStartDate ? healingDaysStartDate : Date()
            HealingDaysTracker.activate(
                startDate: startDate,
                goal: HealingDaysTracker.defaultGoal
            )
        }

        advance()
    }

    private var nameDisplay: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : ", \(trimmed)"
    }
}


#Preview {
    AuthView()
}
