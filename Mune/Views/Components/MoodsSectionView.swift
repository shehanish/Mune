//
//  MoodsSectionView.swift
//  Mune
//
//  Created by Shehani Hansika on 07.05.26.
//


import SwiftUI

struct MoodsSectionView: View {
    let moods: [String]
    @Binding var selectedMoods: Set<String>

    @Binding var notesText: String
    var isNotesFocused: FocusState<Bool>.Binding
    var canShare: Bool = true
    var isSharing: Bool = false

    var onApply: (_ appliedMoods: [String]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How do you feel today?")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .foregroundStyle(Color.brandPrimary)

            MoodPicker(moods: moods, selectedMoods: $selectedMoods)

            VStack(spacing: 12) {
                SelectedMoodsBox(selectedMoods: Array(selectedMoods).sorted())
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Write whatever is on your heart…", text: $notesText, axis: .vertical)
                        .focused(isNotesFocused)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .textInputAutocapitalization(.sentences)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.brandPrimary.opacity(0.35), lineWidth: 1)
                        )
                }

                Button {
                    guard canShare, !isSharing else { return }
                    onApply(Array(selectedMoods).sorted())
                } label: {
                    HStack(spacing: 8) {
                        if isSharing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSharing ? "Sharing…" : "Share this with me")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(canShare ? Color.brandFill : Color.brandFill.opacity(0.35))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(!canShare)
                .accessibilityHint(
                    canShare
                    ? "Saves this check-in"
                    : "Pick a feeling or write a note first"
                )
            }
            .padding(.horizontal)
        }
    }
}
#Preview {
    MoodsSectionViewPreviewWrapper()
}

private struct MoodsSectionViewPreviewWrapper: View {
    private let moods = [
        "Calm", "Sad", "Angry", "Anxious",
        "Okay", "Hopeful", "Tired", "Lonely", "Empty"
    ]

    @State private var selectedMoods: Set<String> = ["Calm", "Tired"]
    @State private var notesText: String = "I felt a bit overwhelmed today, but better now."
    @FocusState private var isNotesFocused: Bool

    var body: some View {
        MoodsSectionView(
            moods: moods,
            selectedMoods: $selectedMoods,
            notesText: $notesText,
            isNotesFocused: $isNotesFocused
        ) { _ in
            // Action for preview
        }
        .padding()
    }
}
