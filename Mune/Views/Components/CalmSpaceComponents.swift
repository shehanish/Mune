//
//  CalmSpaceComponents.swift
//  Mune
//

import SwiftUI

struct BreathingCircleView: View {
    @State private var scale: CGFloat = 0.6
    @State private var isInhaling = true

    private let outerSize: CGFloat = 240
    private let middleSize: CGFloat = 180
    private let innerSize: CGFloat = 80
    private let breathDuration: TimeInterval = 4.5
    private let labelFade: TimeInterval = 1.1

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.sageGreen.opacity(0.2))
                .frame(width: outerSize, height: outerSize)

            Circle()
                .fill(Color.sageGreen.opacity(0.4))
                .frame(width: middleSize, height: middleSize)

            Circle()
                .fill(Color.sageGreen)
                .frame(width: innerSize, height: innerSize)

            ZStack {
                Text("Inhale")
                    .opacity(isInhaling ? 1 : 0)
                    .scaleEffect(isInhaling ? 1 : 0.92)

                Text("Exhale")
                    .opacity(isInhaling ? 0 : 1)
                    .scaleEffect(isInhaling ? 0.92 : 1)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .animation(.easeInOut(duration: labelFade), value: isInhaling)
        }
        .scaleEffect(scale, anchor: .center)
        .frame(width: outerSize, height: outerSize)
        .frame(maxWidth: .infinity)
        .task {
            guard !MotionPreference.shouldReduceMotion else {
                scale = 1.0
                isInhaling = true
                return
            }

            scale = 0.6
            isInhaling = true

            withAnimation(.easeInOut(duration: breathDuration).repeatForever(autoreverses: true)) {
                scale = 1.0
            }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(breathDuration))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: labelFade)) {
                    isInhaling.toggle()
                }
            }
        }
    }
}

struct GroundingRow: View {
    let number: String
    let text: String
    let icon: String

    private let badgeSize: CGFloat = 28
    private let iconSlot: CGFloat = 28

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(number)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: badgeSize, height: badgeSize)
                .background(Color.sageGreen, in: Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.sageGreen.opacity(0.85))
                .frame(width: iconSlot, height: iconSlot)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 36)
    }
}

struct ResourceButton: View {
    let title: String
    let icon: String
    let subLabel: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.textOnPrimary)
                    Text(subLabel)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(color.opacity(0.5))
            }
            .padding()
            .background(Color.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct DoodleLine {
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
}

struct DoodleCanvasView: View {
    let lines: [DoodleLine]
    var sourceSize: CGSize?
    var lineColor: Color = .sageGreen
    var lineWidthScale: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let scaleX = sourceSize.map { size.width / max($0.width, 1) } ?? 1
                let scaleY = sourceSize.map { size.height / max($0.height, 1) } ?? 1

                for line in lines {
                    guard line.points.count > 1 else { continue }

                    var path = Path()
                    let scaledPoints = line.points.map { point in
                        CGPoint(x: point.x * scaleX, y: point.y * scaleY)
                    }
                    path.addLines(scaledPoints)
                    context.stroke(
                        path,
                        with: .color(lineColor),
                        lineWidth: line.lineWidth * lineWidthScale * min(scaleX, scaleY)
                    )
                }
            }
        }
    }
}
