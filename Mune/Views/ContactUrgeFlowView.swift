//
//  ContactUrgeFlowView.swift
//  Mune
//
//  Five steps between the urge to text and sending anything.
//

import SwiftUI
import SwiftData
import Combine

struct ContactUrgeFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("activeProfileID") private var activeProfileID = ""

    @State private var step = 1
    @State private var feeling = ""
    @State private var hope = ""
    @State private var draft = ""
    @State private var secondsRemaining = 300
    @State private var didFinishPause = false
    @State private var outcomeMessage: String?

    private var userID: String {
        activeProfileID.isEmpty ? LocalProfileStore.legacyUserID : activeProfileID
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    Text("Step \(min(step, 5)) of 5")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.55))

                    Group {
                        switch step {
                        case 1: feelingStep
                        case 2: hopeStep
                        case 3: draftStep
                        case 4: pauseStep
                        default: reevaluateStep
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(22)
            }
            .navigationTitle("I want to text them")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                guard step == 4, !didFinishPause else { return }
                if secondsRemaining <= 1 {
                    secondsRemaining = 0
                    didFinishPause = true
                } else {
                    secondsRemaining -= 1
                }
            }
        }
    }

    private var feelingStep: some View {
        stepStack(
            title: "What are you feeling?",
            body: "Name the feeling under the urge. You don’t have to fix it yet."
        ) {
            ChipFlowLayout(spacing: 8) {
                ForEach(["Missing them", "Lonely", "Angry", "Anxious", "Rejected", "Hopeful they’ll reply"], id: \.self) { option in
                    Button {
                        feeling = option
                    } label: {
                        MuneChipLabel(title: option, isSelected: feeling == option, showsCheckmark: true)
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("Or write it in your own words…", text: $feeling, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            nextButton("Continue", enabled: !feeling.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                step = 2
            }
        }
    }

    private var hopeStep: some View {
        stepStack(
            title: "What do you hope will happen if you text them?",
            body: "The urge usually wants relief, not a real conversation. That’s useful to see."
        ) {
            TextField("I hope they…", text: $hope, axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .background(Color.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            nextButton("Write the message (don’t send it)", enabled: !hope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                step = 3
            }
        }
    }

    private var draftStep: some View {
        stepStack(
            title: "Write the message here.",
            body: "Get it out of your hands. Nothing here is sent. This stays on your phone."
        ) {
            TextEditor(text: $draft)
                .frame(minHeight: 160)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(Color.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            nextButton("Hold the message and pause", enabled: true) {
                secondsRemaining = 300
                didFinishPause = false
                step = 4
            }
        }
    }

    private var pauseStep: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(didFinishPause ? "You stayed." : "Five minutes. Don’t send it yet.")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(didFinishPause
                     ? "The sharpest part has had time to move. Now we look again."
                     : "Breathe. The urge can be here. You do not have to act on it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text(timeLabel)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.brandPrimary)
                        .padding(.top, 20)
                        .accessibilityLabel("\(secondsRemaining / 60) minutes and \(secondsRemaining % 60) seconds remaining")

                    BreathingCircleView()
                        .frame(width: 240, height: 240)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                    ProgressView(
                        value: Double(300 - secondsRemaining),
                        total: 300
                    )
                    .tint(Color.sageGreen)
                    .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 10) {
                if didFinishPause {
                    nextButton("Re-evaluate") {
                        step = 5
                    }
                } else {
                    Button("I’ve stayed long enough") {
                        didFinishPause = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var reevaluateStep: some View {
        stepStack(
            title: "Look at the urge again.",
            body: "A bad minute doesn’t get to make the decision. What feels true now?"
        ) {
            if let outcomeMessage {
                Text(outcomeMessage)
                    .font(.subheadline)
                    .foregroundStyle(Color.brandPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Close") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.brandFill)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                outcomeButton("Let it go") {
                    outcomeMessage = "You let the message stay here. That’s you choosing yourself."
                }
                outcomeButton("Save as unsent") {
                    saveUnsent()
                    outcomeMessage = "Saved privately in your journal. Nothing was sent."
                }
                outcomeButton("I still want to send it") {
                    outcomeMessage = "If you still want to, wait until morning. The urge can stay. Sending can wait."
                }
            }
        }
    }

    private func stepStack<Content: View>(title: String, body: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.brandPrimary)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func nextButton(_ title: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(enabled ? Color.brandFill : Color.brandFill.opacity(0.35))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .padding(.top, 8)
    }

    private func outcomeButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.cardSurface)
                .foregroundStyle(Color.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.brandPrimary.opacity(0.16), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var timeLabel: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func saveUnsent() {
        let body = """
        Feeling: \(feeling)

        I hoped: \(hope)

        Unsent message:
        \(draft)
        """
        let entry = JournalEntry(
            userID: userID,
            journalText: body,
            transcript: nil,
            gratitudeOne: "",
            gratitudeTwo: "",
            gratitudeThree: "",
            exerciseID: RecoveryExerciseID.unsent
        )
        modelContext.insert(entry)
        try? modelContext.save()
        NotificationCenter.default.post(name: .journalEntriesDidChange, object: nil)
    }
}
