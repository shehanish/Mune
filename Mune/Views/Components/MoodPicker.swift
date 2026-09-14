//
//  MoodPicker.swift
//  Mune
//
//  Created by Shehani Hansika on 07.05.26.
//

import SwiftUI

struct MoodPicker: View {
    let moods: [String]
    @Binding var selectedMoods: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(moods, id: \.self) { mood in
                    MoodChip(
                        title: mood,
                        isSelected: selectedMoods.contains(mood)
                    ) {
                        toggle(mood)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .blocksTabSwipe()
    }

    private func toggle(_ mood: String) {
        withAnimation(.snappy) {
            if selectedMoods.contains(mood) {
                selectedMoods.remove(mood)
            } else {
                selectedMoods.insert(mood)
            }
        }
    }
}

private struct MoodChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            MuneChipLabel(
                title: title,
                isSelected: isSelected,
                showsCheckmark: false,
                selectedForeground: .brandPrimary,
                unselectedForeground: .brandPrimary,
                selectedFill: Color.sageGreen.opacity(0.38),
                unselectedFill: Color.white
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MoodPicker(moods: ["Calm", "Sad", "Angry", "Anxious", "Okay", "Hopeful", "Tired", "Lonely"], selectedMoods: .constant(["Calm", "Sad"]))
}

