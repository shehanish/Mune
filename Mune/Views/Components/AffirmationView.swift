import SwiftUI

struct AffirmationView: View {
    @State private var selectedAffirmationIndex = 0

    private let affirmations = [
        "Missing them is human. Going back isn’t the only way to honor that ache.",
        "Choosing gentle distance can be a quiet act of care for yourself.",
        "You don’t have to forget them. You’re allowed to find yourself again, gently."
    ]

    /// Tall enough for the longest quote to wrap fully; keeps the card compact.
    private let quoteHeight: CGFloat = 80

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Something soft to hold while you heal.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)

            VStack(spacing: 8) {
                TabView(selection: $selectedAffirmationIndex) {
                    ForEach(affirmations.indices, id: \.self) { index in
                        Text("\"\(affirmations[index])\"")
                            .font(.callout.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.brandPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, minHeight: quoteHeight, alignment: .center)
                            .tag(index)
                            .accessibilityLabel(affirmations[index])
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: quoteHeight)
                .animation(.easeInOut(duration: 0.22), value: selectedAffirmationIndex)

                Text("\(selectedAffirmationIndex + 1) of \(affirmations.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary.opacity(0.7))

                HStack(spacing: 6) {
                    ForEach(affirmations.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedAffirmationIndex ? Color.brandPrimary : Color.brandPrimary.opacity(0.22))
                            .frame(width: index == selectedAffirmationIndex ? 16 : 7, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: selectedAffirmationIndex)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .padding(.horizontal, 12)
            .background(
                LinearGradient(
                    colors: [Color.cardSurfaceStrong, Color.cardSurfaceSoft],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
            .accessibilityHint("Swipe left or right for another gentle reminder")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AffirmationView()
        .padding()
}
