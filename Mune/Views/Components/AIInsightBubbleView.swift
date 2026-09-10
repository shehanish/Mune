//
//  AIInsightBubbleView.swift
//  Mune
//
//  Created by Shehani Hansika on 13.05.26.
//


import SwiftUI

struct AIInsightBubbleView: View {
    let text: String
    var avatarSystemImage: String = "IMG_3016"

    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            BlobAvatarView(width: 30, height: 25, showShadow: false)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary)
                .padding(12)
                .background(Color.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.brandPrimary.opacity(0.35), lineWidth: 1)
                       
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: 350, alignment: .leading)
        .padding(.horizontal)
    }
}


