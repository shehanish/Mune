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
            HStack(spacing: 10) {
                ForEach(moods, id: \.self) { mood in
                    MoodChip(
                        title: mood,
                        isSelected: selectedMoods.contains(mood)
                    ) {
                        toggle(mood)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity)
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
                showsCheckmark: true,
                selectedForeground: .brandPrimary,
                unselectedForeground: .brandPrimary,
                selectedFill: Color.sageGreen.opacity(0.3),
                unselectedFill: Color.chipSurface
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MoodPicker(moods: ["Calm", "Sad", "Angry", "Anxious", "Okay", "Hopeful", "Tired", "Lonely"], selectedMoods: .constant(["Calm", "Sad"]))
}

