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
            TabView(selection: $selectedAffirmationIndex) {
                ForEach(affirmations.indices, id: \.self) { index in
                    Text("\"\(affirmations[index])\"")
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.brandPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 18)
                        .frame(maxWidth: .infinity, minHeight: quoteHeight, alignment: .center)
                        .tag(index)
                        .accessibilityLabel(affirmations[index])
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: quoteHeight)

            VStack(spacing: 8) {
                Text("\(selectedAffirmationIndex + 1) of \(affirmations.count)")
                    .font(.caption2)
                    .foregroundStyle(Color.brandPrimary.opacity(0.38))

                HStack(spacing: 5) {
                    ForEach(affirmations.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedAffirmationIndex ? Color.brandPrimary.opacity(0.55) : Color.brandPrimary.opacity(0.16))
                            .frame(width: index == selectedAffirmationIndex ? 16 : 6, height: 6)
                    }
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
        .accessibilityElement(children: .contain)
        .accessibilityHint("Swipe left or right for another reminder")
    }
}

#Preview {
    AffirmationView()
        .padding()
        .background(Color.appBackgroundGradient)
}
