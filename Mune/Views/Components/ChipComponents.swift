//
//  ChipComponents.swift
//  Mend
//

import SwiftUI

struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let proposedWidth = proposal.width ?? 0
        let width = (proposedWidth.isFinite && proposedWidth > 0) ? proposedWidth : 320
        var origin = CGPoint.zero
        var maxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > width, origin.x > 0 {
                origin.x = 0
                origin.y += size.height + spacing
            }
            maxY = max(maxY, origin.y + size.height)
            origin.x += size.width + spacing
        }

        return CGSize(width: width, height: maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = CGPoint(x: bounds.minX, y: bounds.minY)

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += size.height + spacing
            }
            subview.place(at: origin, proposal: ProposedViewSize(size))
            origin.x += size.width + spacing
        }
    }
}

struct MuneChipLabel: View {
    let title: String
    var isSelected: Bool = false
    var showsCheckmark: Bool = false
    var selectedForeground: Color = .white
    var unselectedForeground: Color = .brandPrimary
    var selectedFill: Color = .brandPrimary
    var unselectedFill: Color = .brandPrimary.opacity(0.12)

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            if showsCheckmark, isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.footnote)
            }
        }
        .foregroundStyle(isSelected ? selectedForeground : unselectedForeground)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background {
            Capsule(style: .continuous)
                .fill(isSelected ? selectedFill : unselectedFill)
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(
                    isSelected ? Color.sageGreen.opacity(0.45) : Color.sageGreen.opacity(0.18),
                    lineWidth: 1
                )
        }
    }
}
