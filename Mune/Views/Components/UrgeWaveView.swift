//
//  UrgeWaveView.swift
//  Mune
//
//  A 2-minute urge-surfing pause. Nothing is saved or sent.
//

import SwiftUI
import Combine

struct UrgeWaveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.recoveryNavigator) private var navigator
    @State private var secondsRemaining = Self.durationSeconds
    @State private var didFinish = false

    private static let durationSeconds = 120

    private var elapsed: Int { Self.durationSeconds - secondsRemaining }

    private var phaseTitle: String {
        switch elapsed {
        case ..<25: return "Name the urge"
        case ..<80: return "Stay with the wave"
        default: return "Let it crest"
        }
    }

    private var phaseMessage: String {
        switch elapsed {
        case ..<25:
            return "This feeling can be here. You do not have to act on it. Stay with yourself."
        case ..<80:
            return "Breathe. You’re allowed to pause. Come back to this moment, one breath at a time."
        default:
            return "You’re still here. The sharpest part is already softening. Stay until the timer ends."
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()

                if didFinish {
                    finishedContent
                } else {
                    activeContent
                }
            }
            .navigationTitle("2 quiet minutes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                guard !didFinish else { return }
                if secondsRemaining <= 1 {
                    secondsRemaining = 0
                    didFinish = true
                } else {
                    secondsRemaining -= 1
                }
            }
        }
    }

    private var activeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Text(timeLabel)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.top, 12)
                    .accessibilityLabel("\(minutes) minutes and \(seconds) seconds remaining")

                ProgressView(value: Double(elapsed), total: Double(Self.durationSeconds))
                    .tint(Color.sageGreen)
                    .padding(.horizontal, 32)

                VStack(spacing: 10) {
                    Text(phaseTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Text(phaseMessage)
                        .font(.subheadline)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)

                BreathingCircleView()

                Button("I’m through these 2 minutes") {
                    didFinish = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .padding(.bottom, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var finishedContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "water.waves")
                .font(.system(size: 44))
                .foregroundStyle(Color.sageGreen)
                .padding(.top, 40)

            Text("You stayed.")
                .font(.title.weight(.bold))
                .foregroundStyle(Color.brandPrimary)

            Text("You got through the spike. That’s something.")
                .font(.body)
                .foregroundStyle(Color.textOnPrimary.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    navigator.openJournalExercise(RecoveryExerciseID.miss)
                }
            } label: {
                Text("What do I actually miss?")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Button("I’m ready") {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.brandPrimary)

            Spacer()
        }
    }

    private var minutes: Int { max(0, secondsRemaining) / 60 }
    private var seconds: Int { max(0, secondsRemaining) % 60 }

    private var timeLabel: String {
        String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    UrgeWaveView()
}
