import SwiftUI


struct AffirmationView: View {
    @State private var selectedAffirmationIndex = 0

    private let affirmations = [
        "Missing them is human. Going back isn’t the only way to honor that ache.",
        "Choosing no contact can be a quiet act of care for yourself.",
        "You don’t have to forget them. You’re allowed to find yourself again, gently."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Something soft to hold while you heal.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)

            VStack(spacing: 12) {
                Text("\"\(affirmations[selectedAffirmationIndex])\"")
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .minimumScaleFactor(0.9)

                Text("\(selectedAffirmationIndex + 1) of \(affirmations.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary.opacity(0.7))

                HStack(spacing: 6) {
                    ForEach(affirmations.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedAffirmationIndex ? Color.brandPrimary : Color.brandPrimary.opacity(0.22))
                            .frame(width: index == selectedAffirmationIndex ? 16 : 7, height: 7)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
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
            .contentShape(RoundedRectangle(cornerRadius: 22))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.22)) {
                    selectedAffirmationIndex = (selectedAffirmationIndex + 1) % affirmations.count
                }
            }
            .accessibilityLabel(affirmations[selectedAffirmationIndex])
            .accessibilityHint("Tap for another gentle reminder")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AffirmationView()
        .padding()
}
