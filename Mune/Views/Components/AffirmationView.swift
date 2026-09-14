import SwiftUI

struct AffirmationView: View {
    @State private var selectedAffirmationIndex = 0

    private let affirmations = [
        "Missing them doesn’t mean you have to go back.",
        "You’re allowed to want something new for yourself.",
        "You can miss them and still pick yourself today."
    ]

    private let quoteHeight: CGFloat = 76

    var body: some View {
        VStack(spacing: 12) {
            // Tap rather than swipe, so a sideways drag here still changes tabs.
            Text("\"\(affirmations[selectedAffirmationIndex])\"")
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.brandPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, minHeight: quoteHeight, alignment: .center)
                .id(selectedAffirmationIndex)
                .transition(.opacity)
                .accessibilityLabel(affirmations[selectedAffirmationIndex])

            HStack(spacing: 5) {
                ForEach(affirmations.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedAffirmationIndex ? Color.brandPrimary.opacity(0.55) : Color.brandPrimary.opacity(0.16))
                        .frame(width: index == selectedAffirmationIndex ? 16 : 6, height: 6)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.brandPrimary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.brandPrimary.opacity(0.08), radius: 10, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.22)) {
                selectedAffirmationIndex = (selectedAffirmationIndex + 1) % affirmations.count
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap for another reminder")
    }
}

#Preview {
    AffirmationView()
        .padding()
        .background(Color.appBackgroundGradient)
}
