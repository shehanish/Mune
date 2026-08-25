import SwiftUI

struct BlobAvatarView: View {
    var width: CGFloat = 220
    var height: CGFloat = 170
    var showShadow: Bool = true
    var animate: Bool = false
    
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var rotation: Angle = .degrees(0)
    var scale: CGFloat = 1

    private var motionX: CGFloat { animate ? 6 : 0 }
    private var motionY: CGFloat { animate ? 8 : 0 }

    private func content(phase: CGFloat) -> some View {
        let animatedOffsetX = offsetX + (animate ? sin(phase * 1.3) * motionX : 0)
        let animatedOffsetY = offsetY + (animate ? cos(phase * 1.6) * motionY : 0)
        let animatedRotation = rotation + (animate ? .degrees(sin(phase * 1.1) * 4) : .degrees(0))
        let animatedScale = scale * (animate ? 1 + (cos(phase * 1.8) * 0.02) : 1)

        return ZStack {
            if showShadow {
                Ellipse()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: width * 0.72, height: height * 0.10)
                    .blur(radius: 8)
                    .offset(y: height * 0.42 + abs(animatedOffsetY) * 0.12)
            }

            Image("IMG_3016")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .scaleEffect(animatedScale)
                .rotationEffect(animatedRotation)
                .offset(x: animatedOffsetX, y: animatedOffsetY)
        }
        // Leave room for the wobble so edges aren't clipped.
        .frame(
            width: width + motionX * 2 + 8,
            height: height + motionY * 2 + 8
        )
    }
    
    var body: some View {
        Group {
            if animate {
                TimelineView(.animation) { context in
                    content(phase: context.date.timeIntervalSinceReferenceDate)
                }
            } else {
                content(phase: 0)
            }
        }
    }
}
