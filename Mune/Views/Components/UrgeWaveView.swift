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
    @State private var secondsRemaining = Self.durationSeconds
    @State private var note = ""
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
            return "You want to reach out. That feeling is allowed to be here. You do not have to act on it."
        case ..<80:
            return "Breathe. The urge is a wave, not a command. Nothing has to be sent for you to get through this."
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
            .navigationTitle("Ride this wave")
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("If you need to say it, say it here")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Text("This stays on this screen only. It is never saved, sent, or shared.")
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary.opacity(0.65))

                    TextEditor(text: $note)
                        .frame(minHeight: 90)
                        .padding(8)
                        .background(Color.cardSurfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .scrollContentBackground(.hidden)
                }
                .padding(16)
                .background(Color.cardSurfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal)

                Button("I’m through this wave") {
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

            Text("The urge did not have to become a message. That is a real kind of healing — different from counting days, and different from sending the letter.")
                .font(.body)
                .foregroundStyle(Color.textOnPrimary.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                dismiss()
            } label: {
                Text("Back to Calm Space")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

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
