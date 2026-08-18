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

    // MARK: - Transient state
    @State private var name          = ""
    @State private var step          = 0           // 0 = welcome, 1 = name, 2 = focus, 3 = complete
    @State private var selectedFocuses: Set<String> = ["No contact"]
    @State private var showNameError = false
    @State private var goingForward  = true

    // MARK: - Data
    private let focusOptions: [(title: String, subtitle: String, icon: String)] = [
        ("No contact",         "Stay strong when I want to reach out",     "hand.raised.fill"),
        ("Process the grief",  "Journal, voice note, feel it safely",      "heart.text.square.fill"),
        ("Hard moments",       "Help when I want to text them",            "heart.circle.fill"),
        ("Rebuild my routine", "Small daily wins, back to myself",         "sun.and.horizon.fill"),
    ]

    private let indicatorSteps = 2   // steps 1 & 2 show the dot indicator

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackgroundGradient.ignoresSafeArea()
                    .dismissKeyboardOnTap()
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                }
            }
        }
        // Prevent accidental swipe-dismiss on the completion screen
        .interactiveDismissDisabled(step == 3)
        .onAppear {
            name = (userName.isEmpty || userName == "Friend") ? "" : userName
            let saved = healingFocus.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            selectedFocuses = saved.isEmpty ? ["No contact"] : Set(saved)
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 36) {
                Spacer(minLength: 52)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 168)
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 132)
                    Image(systemName: "heart.text.square.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58)
                        .foregroundStyle(Color.brandPrimary)
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Welcome to Mend")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textOnPrimary)

                    Text("Your breakup healing companion.\nOne day at a time — especially the hard ones.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.80))
                        .lineSpacing(4)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 10) {
                    featurePill(icon: "lock.fill",          label: "Private — your story stays on your device")
                    featurePill(icon: "brain.head.profile", label: "Breakup-aware AI support")
                    featurePill(icon: "hand.raised.fill",   label: "Built for no contact and hard moments")
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 40)

                primaryButton("Get Started") { advance() }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Page: Name
    private var namePage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 28)

                pageHeader(
                    icon: "person.crop.circle.fill",
                    title: "What's your name?",
                    message: "Just your first name or a nickname is perfect. This is your space."
                )
                .padding(.bottom, 28)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Your name or nickname", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .font(.body)
                        .padding(14)
                        .background(Color.white.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    showNameError ? Color.red.opacity(0.55) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundStyle(Color.darkCharcoal)
                        .accessibilityLabel("Name or nickname")
                        .onChange(of: name) { _, _ in
                            if showNameError { showNameError = false }
                        }

                    Group {
                        if showNameError {
                            Label("Please keep it under 30 characters.", systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red.opacity(0.80))
                        } else if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Label("Hi, \(name.trimmingCharacters(in: .whitespacesAndNewlines))!", systemImage: "hand.wave.fill")
                                .foregroundStyle(Color.textOnPrimary.opacity(0.72))
                        } else {
                            Text("This is how Mend will greet you.")
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
                    icon: "sparkles",
                    title: "What do you need\nmost right now?",
                    message: "Pick everything that fits — Mend will focus on what matters for your breakup."
                )
                .padding(.bottom, 24)

                VStack(spacing: 10) {
                    ForEach(focusOptions, id: \.title) { option in
                        focusRow(option)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)

                HStack(spacing: 12) {
                    secondaryButton("Back") { back() }
                    primaryButton("Enter Mend") { completeOnboarding() }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Page: Complete
    private var completePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.07))
                        .frame(width: 190)
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.12))
                        .frame(width: 148)
                    Image(systemName: "checkmark.seal.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64)
                        .foregroundStyle(Color.brandPrimary)
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("You're all set\(nameDisplay)!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textOnPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Your breakup buddy is ready.\nTake a breath. One day at a time.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.78))
                        .lineSpacing(5)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()

            primaryButton("Open My Mend") {
                isLoggedIn = true
                dismiss()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
        }
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
        .background(Color.white.opacity(0.54))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
    }

    private func pageHeader(icon: String, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.brandPrimary)
                .padding(12)
                .background(Color.white.opacity(0.72))
                .clipShape(Circle())
                .padding(.horizontal, 28)
                .accessibilityHidden(true)

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
            .background(isSelected ? Color.white.opacity(0.88) : Color.white.opacity(0.50))
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

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandPrimary)
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
                .background(Color.white.opacity(0.68))
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

    private func completeOnboarding() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userName     = trimmed.isEmpty ? "Friend" : trimmed
        healingFocus = focusOptions
            .map(\.title)
            .filter { selectedFocuses.contains($0) }
            .joined(separator: ", ")
        advance()
    }

    private var nameDisplay: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : ", \(trimmed)"
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


#Preview {
    AuthView()
}
