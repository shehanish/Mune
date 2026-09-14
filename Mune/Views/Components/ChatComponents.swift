import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var onExercise: ((CoachExercise) -> Void)?

    var body: some View {
        switch message.kind {
        case .crisisSupport(let signals):
            CrisisHelplineCard(message: message.text, signals: signals)
        case .text:
            textBubble
        }
    }

    private var textBubble: some View {
        HStack(alignment: .center, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 30)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundStyle(Color.brandPrimary.opacity(0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message.text)
                        .padding(14)
                        .background(Color.brandFill)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .cornerRadius(4, corners: [.bottomRight])
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundStyle(Color.brandPrimary.opacity(0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .center, spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cardSurfaceStrong)
                                .overlay(
                                    Circle()
                                        .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
                                )
                                .frame(width: 36, height: 36)

                            BlobAvatarView(width: 22, height: 18, showShadow: false)
                                .frame(width: 36, height: 36, alignment: .center)
                                .offset(y: -1)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(message.text)
                                .padding(14)
                                .background(Color.sageGreen.opacity(0.15))
                                .foregroundColor(Color.textOnPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .cornerRadius(4, corners: [.bottomLeft])

                            if let exercise = message.exercise {
                                Button {
                                    onExercise?(exercise)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Do this exercise")
                                        Image(systemName: "arrow.right")
                                            .font(.caption2.weight(.semibold))
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.brandPrimary)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 4)
                            }
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
}

struct CrisisHelplineCard: View {
    let message: String
    let signals: Set<CrisisSignal>

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.red.opacity(0.85))

                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.brandPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("If you’re in immediate danger, please call emergency services now.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                helplineButton(
                    title: "Find a helpline near you",
                    subtitle: "Local crisis lines worldwide · IASP",
                    systemImage: "globe",
                    url: CrisisResources.findHelplineURL
                )

                if let emergencyURL = CrisisResources.emergencyTelURL {
                    helplineButton(
                        title: "Call \(CrisisResources.emergencyNumber)",
                        subtitle: "Emergency services in your region",
                        systemImage: "cross.circle.fill",
                        url: emergencyURL
                    )
                }

                if CrisisResources.isUSRegion {
                    if let callURL = CrisisResources.usLifelineCallURL {
                        helplineButton(
                            title: "Call 988",
                            subtitle: "Suicide & Crisis Lifeline · United States",
                            systemImage: "phone.fill",
                            url: callURL
                        )
                    }

                    if let textURL = CrisisResources.usLifelineTextURL {
                        helplineButton(
                            title: "Text 988",
                            subtitle: "Message the Crisis Lifeline · United States",
                            systemImage: "message.fill",
                            url: textURL
                        )
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.red.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            signals.contains(.harmToOthers)
            ? "Crisis support and emergency resources"
            : "Crisis support resources"
        )
    }

    private func helplineButton(
        title: String,
        subtitle: String,
        systemImage: String,
        url: URL
    ) -> some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: systemImage)
                        .foregroundStyle(Color.red.opacity(0.85))
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.red.opacity(0.45))
            }
            .padding(12)
            .background(Color.cardSurfaceStrong, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// View extension to selectively round specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
