//
//  ProfileView.swift
//  Mend
//
//  Created by Shehani Hansika on 07.05.26.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @AppStorage("isLoggedIn")    var isLoggedIn    = false
    @AppStorage("userName")      var userName      = ""
    @AppStorage("healingFocus")  var healingFocus  = ""
    @AppStorage("profileImageData") var profileImageData: Data = Data()

    @Environment(\.dismiss) var dismiss

    @State private var editName   = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    @State private var showSignOutAlert = false

    // Derived focus chips from comma-separated storage
    private var focusChips: [String] {
        healingFocus
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient.ignoresSafeArea()
                    VStack(spacing: 24) {

                        // MARK: - Avatar hero
                        VStack(spacing: 14) {
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                ZStack(alignment: .bottomTrailing) {
                                    Group {
                                        if let profileImage {
                                            profileImage
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundStyle(Color.brandPrimary.opacity(0.55))
                                        }
                                    }
                                    .frame(width: 108, height: 108)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                    .shadow(color: Color.brandPrimary.opacity(0.18), radius: 12, y: 6)

                                    // Camera badge
                                    Image(systemName: "camera.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(7)
                                        .background(Color.brandFill)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        .offset(x: 4, y: 4)
                                }
                            }
                            .onChange(of: selectedItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        profileImageData = data
                                        if let uiImage = UIImage(data: data) {
                                            profileImage = Image(uiImage: uiImage)
                                        }
                                    }
                                }
                            }
                            .accessibilityLabel("Change profile photo")

                            // Name display
                            Text(userName.isEmpty ? "Friend" : userName)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.textOnPrimary)

                           

                            // Remove photo link
                            if profileImage != nil || !profileImageData.isEmpty {
                                Button {
                                    profileImageData = Data()
                                    profileImage     = nil
                                    selectedItem     = nil
                                } label: {
                                    Text("Remove photo")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.top, 32)

                        // MARK: - About you card
                        VStack(alignment: .leading, spacing: 16) {
                            Label("About you", systemImage: "person.fill")
                                .font(.headline)
                                .foregroundStyle(Color.brandPrimary)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                TextField("Your name or nickname", text: $editName)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .font(.body)
                                    .padding(12)
                                    .background(Color.cardSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(Color.brandPrimary)
                                    .accessibilityLabel("Name or nickname")
                            }

                            if !focusChips.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Healing focus")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    ChipFlowLayout(spacing: 6) {
                                        ForEach(focusChips, id: \.self) { chip in
                                            Text(chip)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Color.brandPrimary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.brandPrimary.opacity(0.10), in: Capsule(style: .continuous))
                                        }
                                    }

                                    Text("You chose this when you arrived. It guides my gentle tips.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                        .padding(.horizontal, 20)

                        // MARK: - Save button
                        Button {
                            let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
                            userName = trimmed.isEmpty ? "Friend" : trimmed
                            if !LocalProfileStore.activeProfileID.isEmpty {
                                LocalProfileStore.updateDisplayName(userName, for: LocalProfileStore.activeProfileID)
                            }
                            dismiss()
                        } label: {
                            Text("Save my changes")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.brandFill)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: Color.brandPrimary.opacity(0.22), radius: 8, y: 5)
                        }
                        .padding(.horizontal, 20)

                        // MARK: - Leave space
                        Button {
                            showSignOutAlert = true
                        } label: {
                            Label("Leave this space for now", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red.opacity(0.80))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .alert("Leave this space?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Leave", role: .destructive) {
                    LocalProfileStore.signOut()
                    editName = ""
                    profileImage = nil
                    selectedItem = nil
                    dismiss()
                }
            } message: {
                Text("Your journal and check-ins stay safely on this device. Come back to this space whenever you’re ready.")
            }
            .onAppear {
                editName = userName
                if !profileImageData.isEmpty, let uiImage = UIImage(data: profileImageData) {
                    profileImage = Image(uiImage: uiImage)
                }
            }
    }
}

#Preview {
    ProfileView()
}
