//
//  SelectedMoodsBox.swift
//  Mune
//
//  Created by Shehani Hansika on 07.05.26.
//


import SwiftUI

struct SelectedMoodsBox: View {
    let selectedMoods: [String]

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            
            if selectedMoods.isEmpty {
                Text("Choose any feelings that fit. There’s no wrong answer.")
                    .font(.footnote)
                    .foregroundStyle(Color.brandPrimary.opacity(0.6))
            } else {
                ChipFlowLayout(spacing: 8) {
                    ForEach(selectedMoods, id: \.self) { mood in
                        Text(mood)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.brandPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.sageGreen.opacity(0.35), in: Capsule(style: .continuous))
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.cardSurfaceMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    SelectedMoodsBox(selectedMoods: [])
}
