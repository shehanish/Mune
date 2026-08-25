import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAuthSheet = false
    @State private var appeared = false
    @State private var profiles: [LocalProfileStore.Profile] = []
    @State private var profilePendingDelete: LocalProfileStore.Profile?

    var body: some View {
        ZStack {
            Color.appBackgroundGradient.ignoresSafeArea()

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
                Spacer(minLength: 24)

                VStack(spacing: 0) {
                    BlobAvatarView(width: 150, height: 124, showShadow: true, animate: true)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: appeared)

                    VStack(spacing: 10) {
                        Text("Mend")
                            .font(.system(size: 54, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.brandPrimary, Color.sageGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .kerning(2)
                            .shadow(color: Color.brandPrimary.opacity(0.18), radius: 8, y: 4)

                        Text("A kind companion for this hard chapter")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.textOnPrimary.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2), value: appeared)
                }

                Spacer(minLength: 20)

                if profiles.isEmpty {
                    guestHighlights
                } else {
                    profilePicker
                }

                Spacer(minLength: 20)

                VStack(spacing: 14) {
                    Button {
                        showAuthSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Text(profiles.isEmpty ? "I’m ready. Walk with me" : "Begin a new gentle space")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.brandFill, Color.brandFill.opacity(0.78)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.brandPrimary.opacity(0.32), radius: 16, y: 8)
                    }

                    Text("Free · Private · Just for you. No account needed")
                        .font(.caption)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.48))

                    Text("Mend offers support, not therapy. If you’re in crisis, find a local helpline or call emergency services.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.textOnPrimary.opacity(0.40))
                        .padding(.top, 2)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.45), value: appeared)
            }
        }
        .onAppear {
            appeared = true
            LocalProfileStore.migrateLegacyIfNeeded()
            profiles = LocalProfileStore.allProfiles()
        }
        .sheet(isPresented: $showAuthSheet, onDismiss: {
            profiles = LocalProfileStore.allProfiles()
        }) {
            AuthView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
        }
        .alert(
            "Remove this space?",
            isPresented: Binding(
                get: { profilePendingDelete != nil },
                set: { if !$0 { profilePendingDelete = nil } }
            )
        ) {
            Button("Keep it", role: .cancel) {
                profilePendingDelete = nil
            }
            Button("Remove", role: .destructive) {
                if let profile = profilePendingDelete {
                    deleteProfile(profile)
                }
                profilePendingDelete = nil
            }
        } message: {
            if let profile = profilePendingDelete {
                Text("“\(profile.displayName)” and everything saved here (check-ins, journal, drawings) will leave this device. This can’t be undone.")
            }
        }
    }

    private var guestHighlights: some View {
        VStack(spacing: 12) {
            WelcomeFeatureRow(
                icon: "leaf.fill",
                title: "Gentle no-contact support",
                subtitle: "I’ll sit with you when the urge to reach out feels loud"
            )
            WelcomeFeatureRow(
                icon: "heart.circle.fill",
                title: "Here for the hard moments",
                subtitle: "When you want to text them, or everything feels like too much"
            )
            WelcomeFeatureRow(
                icon: "lock.fill",
                title: "A private place to grieve",
                subtitle: "Your story stays on your device, only yours"
            )
        }
        .padding(.horizontal, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.35), value: appeared)
    }

    private var profilePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome back. Pick up gently where you left off")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textOnPrimary.opacity(0.75))
                .padding(.horizontal, 28)

            VStack(spacing: 10) {
                ForEach(profiles) { profile in
                    HStack(spacing: 10) {
                        Button {
                            LocalProfileStore.activate(profile)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandPrimary.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Text(String(profile.displayName.prefix(1)).uppercased())
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.brandPrimary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.displayName)
                                        .font(.headline)
                                        .foregroundStyle(Color.textOnPrimary)
                                    Text("Come back in")
                                        .font(.caption)
                                        .foregroundStyle(Color.textOnPrimary.opacity(0.62))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.brandPrimary.opacity(0.45))
                            }
                            .padding(14)
                            .background(Color.cardSurfaceMuted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.30), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            profilePendingDelete = profile
                        } label: {
                            Image(systemName: "trash")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.red.opacity(0.85))
                                .frame(width: 44, height: 44)
                                .background(Color.cardSurfaceMuted, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.30), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete \(profile.displayName)")
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.35), value: appeared)
    }

    private func deleteProfile(_ profile: LocalProfileStore.Profile) {
        LocalProfileStore.purgeSwiftData(for: profile.id, context: modelContext)
        LocalProfileStore.deleteProfile(id: profile.id)
        withAnimation(.snappy) {
            profiles = LocalProfileStore.allProfiles()
        }
    }
}

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
                .background(Color.cardSurfaceMuted)
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
        .background(Color.cardSurfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.30), lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeView()
        .modelContainer(for: [MoodEntry.self, JournalEntry.self], inMemory: true)
}
