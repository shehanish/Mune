import SwiftUI


struct AffirmationView: View {
    @State private var selectedAffirmationIndex = 0

    private let affirmations = [
        "Missing them doesn't mean going back is right.",
        "No contact is an act of self-respect.",
        "Healing isn't linear — today still counts."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A gentle reminder while you heal from this breakup.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.darkCharcoal)

            
            TabView(selection: $selectedAffirmationIndex) {
                ForEach(affirmations.indices, id: \.self) { index in
                    VStack(spacing: 12) {
                        Text("\"\(affirmations[index])\"")
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.darkCharcoal)
                            .padding(.horizontal, 10)

                        Text("\(index + 1) of \(affirmations.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 20)
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0.92), Color.white.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
                    )
                    .tag(index)
                    .padding(.horizontal, 4)
                }
            }
            .frame(height: 170)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
}

#Preview {
    AffirmationView()
        .padding()
}
