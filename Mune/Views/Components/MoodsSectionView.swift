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
    var showsTitle: Bool = true
    var title: String = "How are you feeling?"

    var onApply: (_ appliedMoods: [String]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showsTitle {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.brandPrimary)
            }

            MoodPicker(moods: moods, selectedMoods: $selectedMoods)

            Text("Pick one or more feelings above.")
                .font(.footnote)
                .foregroundStyle(Color.brandPrimary.opacity(0.45))
                .frame(maxWidth: .infinity)

            TextField("A note, if you want…", text: $notesText, axis: .vertical)
                .focused(isNotesFocused)
                .lineLimit(2...4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.brandPrimary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.brandPrimary.opacity(0.08), radius: 10, x: 0, y: 4)
                .textInputAutocapitalization(.sentences)

            Button {
                guard canShare, !isSharing else { return }
                onApply(Array(selectedMoods).sorted())
            } label: {
                HStack(spacing: 8) {
                    if isSharing {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSharing ? "Saving…" : "Check in")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(canShare ? Color.brandFill : Color.brandFill.opacity(0.35))
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canShare)
            .accessibilityHint(
                canShare
                ? "Saves this check-in"
                : "Pick a feeling or write a note first"
            )
        }
    }
}
#Preview {
    MoodsSectionViewPreviewWrapper()
}

private struct MoodsSectionViewPreviewWrapper: View {
    private let moods = RecoveryMood.checkInOptions

    @State private var selectedMoods: Set<String> = ["Sad", "I'm doing okay"]
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
