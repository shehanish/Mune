//
//  ProfileView.swift
//  Mune
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
    @AppStorage("activeProfileID") private var activeProfileID = ""

    @Environment(\.dismiss) var dismiss

    @State private var editName   = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    @State private var showSignOutAlert = false
    @State private var selectedFocuses: Set<String> = []

    private let focusOptions: [(title: String, subtitle: String, icon: String)] = [
        ("Healing days",       "Count days since last contact",            "leaf.fill"),
        ("Write it out",       "Get the feelings out of my head",          "heart.text.square.fill"),
        ("Find my calm",       "Something to do when it gets loud",        "heart.circle.fill"),
        ("Rebuild my routine", "Small steps back into my own life",        "sun.and.horizon.fill"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient.ignoresSafeArea()
                ScrollView {
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

                            Text(userName.isEmpty ? "Friend" : userName)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.textOnPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.75)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 20)

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
                                    .background(Color.brandPrimary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(Color.brandPrimary)
                                    .accessibilityLabel("Name or nickname")
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Healing focus")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Text("Pick what you need most. This personalizes one tip on Home.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                VStack(spacing: 8) {
                                    ForEach(focusOptions, id: \.title) { option in
                                        focusToggleRow(option)
                                    }
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
                            saveProfile()
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
                selectedFocuses = Self.parseFocusSet(healingFocus)
                if !profileImageData.isEmpty, let uiImage = UIImage(data: profileImageData) {
                    profileImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    private func focusToggleRow(_ option: (title: String, subtitle: String, icon: String)) -> some View {
        let isOn = selectedFocuses.contains(option.title)
        return Button {
            if isOn {
                selectedFocuses.remove(option.title)
            } else {
                selectedFocuses.insert(option.title)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Text(option.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isOn ? Color.brandPrimary : Color.brandPrimary.opacity(0.28))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isOn ? Color.brandPrimary.opacity(0.10) : Color.brandPrimary.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    private func saveProfile() {
        let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = trimmed.isEmpty ? "Friend" : trimmed

        let focusOrder = focusOptions.map(\.title)
        let joined = focusOrder.filter { selectedFocuses.contains($0) }.joined(separator: ", ")
        healingFocus = joined

        if !activeProfileID.isEmpty {
            LocalProfileStore.updateDisplayName(userName, for: activeProfileID)
            LocalProfileStore.updateHealingFocus(joined, for: activeProfileID)
        }

        dismiss()
    }

    private static func parseFocusSet(_ raw: String) -> Set<String> {
        let parts = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var result = Set<String>()
        for part in parts {
            switch part {
            case "No contact", "Healing days":
                result.insert("Healing days")
            case "Process the grief", "Write it out":
                result.insert("Write it out")
            case "Hard moments", "Find my calm":
                result.insert("Find my calm")
            case "Rebuild my routine":
                result.insert("Rebuild my routine")
            default:
                result.insert(part)
            }
        }
        return result
    }
}

#Preview {
    ProfileView()
}
