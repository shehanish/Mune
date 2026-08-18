import SwiftUI

struct WelcomeView: View {
    @State private var showAuthSheet = false
    @State private var appeared     = false

    var body: some View {
        ZStack {
            // Background
            Color.appBackgroundGradient.ignoresSafeArea()

            // Decorative blobs
            Circle()
                .fill(Color.brandPrimary.opacity(0.12))
                .frame(width: 340)
                .blur(radius: 60)
                .offset(x: 160, y: -280)
                .allowsHitTesting(false)

            Circle()
                .fill(Color.sageGreen.opacity(0.14))
                .frame(width: 300)
                .blur(radius: 70)
                .offset(x: -160, y: 320)
                .allowsHitTesting(false)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 200)
                .blur(radius: 40)
                .offset(x: 0, y: 80)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Hero
                VStack(spacing: 0) {
                    // Floating mascot
                    BlobAvatarView(width: 180, height: 148, showShadow: true, animate: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: appeared)

                    // App name
                    VStack(spacing: 10) {
                        Text("Mend")
                            .font(.system(size: 62, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.brandPrimary, Color.sageGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .kerning(2)
                            .shadow(color: Color.brandPrimary.opacity(0.18), radius: 8, y: 4)

                        Text("Your breakup healing companion")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.textOnPrimary.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2), value: appeared)
                }

                Spacer(minLength: 36)

                // MARK: - Feature highlights
                VStack(spacing: 12) {
                    WelcomeFeatureRow(
                        icon: "hand.raised.fill",
                        title: "No contact support",
                        subtitle: "Stay strong when you want to reach out"
                    )
                    WelcomeFeatureRow(
                        icon: "heart.circle.fill",
                        title: "Help in hard moments",
                        subtitle: "When you want to text them or feel overwhelmed"
                    )
                    WelcomeFeatureRow(
                        icon: "lock.fill",
                        title: "Private grief space",
                        subtitle: "Your breakup story stays on your device"
                    )
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.35), value: appeared)

                Spacer(minLength: 36)

                // MARK: - CTA
                VStack(spacing: 14) {
                    Button {
                        showAuthSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Text("Start your healing")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.brandPrimary.opacity(0.78)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.brandPrimary.opacity(0.32), radius: 16, y: 8)
                    }

                    Text("Free · Private · No account required")
                        .font(.caption)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.48))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.45), value: appeared)
            }
        }
        .onAppear { appeared = true }
        .sheet(isPresented: $showAuthSheet) {
            AuthView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
        }
    }
}

// MARK: - Feature row
private struct WelcomeFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.60))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.brandPrimary.opacity(0.10), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textOnPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textOnPrimary.opacity(0.62))
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeView()
}

