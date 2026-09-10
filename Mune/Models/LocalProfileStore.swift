//
//  LocalProfileStore.swift
//  Mend
//
//  Local multi-profile sessions (no cloud accounts).
//  Each profile keeps its own SwiftData userID + preferences.
//

import Foundation
import SwiftData

enum LocalProfileStore {
    static let legacyUserID = "app-user"

    private static let profilesKey = "localProfiles.v1"
    private static let activeProfileIDKey = "activeProfileID"
    private static let didMigrateKey = "localProfiles.didMigrateLegacy.v1"

    struct Profile: Codable, Identifiable, Hashable {
        var id: String
        var displayName: String
        var healingFocus: String
        var createdAt: Date
    }

    // MARK: - Keys

    static var activeProfileID: String {
        get { UserDefaults.standard.string(forKey: activeProfileIDKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: activeProfileIDKey) }
    }

    static func healingFocusKey(for profileID: String) -> String {
        "healingFocus.\(profileID)"
    }

    static func profileImageKey(for profileID: String) -> String {
        "profileImageData.\(profileID)"
    }

    // MARK: - Profiles

    static func allProfiles() -> [Profile] {
        migrateLegacyIfNeeded()
        guard let data = UserDefaults.standard.data(forKey: profilesKey),
              let profiles = try? JSONDecoder().decode([Profile].self, from: data) else {
            return []
        }
        return profiles.sorted { $0.createdAt < $1.createdAt }
    }

    static func profile(id: String) -> Profile? {
        allProfiles().first { $0.id == id }
    }

    static func activeProfile() -> Profile? {
        let id = activeProfileID
        guard !id.isEmpty else { return nil }
        return profile(id: id)
    }

    @discardableResult
    static func createProfile(displayName: String, healingFocus: String) -> Profile {
        migrateLegacyIfNeeded()
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = Profile(
            id: UUID().uuidString,
            displayName: trimmed.isEmpty ? "Friend" : trimmed,
            healingFocus: healingFocus,
            createdAt: .now
        )
        var profiles = allProfiles()
        profiles.append(profile)
        save(profiles)
        UserDefaults.standard.set(healingFocus, forKey: healingFocusKey(for: profile.id))
        return profile
    }

    static func updateDisplayName(_ name: String, for profileID: String) {
        var profiles = allProfiles()
        guard let index = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profiles[index].displayName = trimmed.isEmpty ? "Friend" : trimmed
        save(profiles)
    }

    static func updateHealingFocus(_ focus: String, for profileID: String) {
        var profiles = allProfiles()
        guard let index = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[index].healingFocus = focus
        save(profiles)
        UserDefaults.standard.set(focus, forKey: healingFocusKey(for: profileID))
    }

    /// Removes the profile and its local preferences. Call `purgeSwiftData(for:context:)` separately for entries.
    static func deleteProfile(id profileID: String) {
        migrateLegacyIfNeeded()
        var profiles = allProfiles()
        guard profiles.contains(where: { $0.id == profileID }) else { return }

        profiles.removeAll { $0.id == profileID }
        save(profiles)

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: healingFocusKey(for: profileID))
        defaults.removeObject(forKey: profileImageKey(for: profileID))

        defaults.removeObject(forKey: NoContactTracker.isActiveKey(for: profileID))
        defaults.removeObject(forKey: NoContactTracker.startDateKey(for: profileID))
        defaults.removeObject(forKey: NoContactTracker.goalKey(for: profileID))

        PanicRoomViewModel.clearDrawings(for: profileID)
        defaults.removeObject(forKey: PanicRoomViewModel.enabledKey(for: profileID))

        if activeProfileID == profileID {
            activeProfileID = ""
            defaults.set(false, forKey: "isLoggedIn")
            defaults.set("", forKey: "userName")
            defaults.set("", forKey: "healingFocus")
            defaults.set(Data(), forKey: "profileImageData")
            NoContactTracker.clearSessionKeys()
        }
    }

    /// Deletes mood and journal entries stored for this profile.
    static func purgeSwiftData(for profileID: String, context: ModelContext) {
        do {
            let moodDescriptor = FetchDescriptor<MoodEntry>(
                predicate: #Predicate { $0.userID == profileID }
            )
            let moods = try context.fetch(moodDescriptor)
            for entry in moods {
                context.delete(entry)
            }

            let journalDescriptor = FetchDescriptor<JournalEntry>(
                predicate: #Predicate { $0.userID == profileID }
            )
            let journals = try context.fetch(journalDescriptor)
            for entry in journals {
                context.delete(entry)
            }

            try context.save()
        } catch {
            MuneLog.debug("[LocalProfileStore] purgeSwiftData failed for \(profileID): \(error)")
        }
    }

    // MARK: - Session

    /// Loads this profile into the shared session AppStorage keys used by the UI.
    static func activate(_ profile: Profile, signIn: Bool = true) {
        migrateLegacyIfNeeded()

        // Persist any previous session prefs back to its profile first.
        if !activeProfileID.isEmpty, activeProfileID != profile.id {
            persistActiveSessionToScopedStorage()
        }

        activeProfileID = profile.id
        UserDefaults.standard.set(profile.displayName, forKey: "userName")
        UserDefaults.standard.set(profile.healingFocus, forKey: "healingFocus")

        let imageData = UserDefaults.standard.data(forKey: profileImageKey(for: profile.id)) ?? Data()
        UserDefaults.standard.set(imageData, forKey: "profileImageData")

        NoContactTracker.loadScopedIntoSession(for: profile.id)

        if signIn {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
        }
    }

    /// Saves session prefs for the active profile, then clears the session.
    static func signOut() {
        persistActiveSessionToScopedStorage()
        activeProfileID = ""
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set("", forKey: "userName")
        UserDefaults.standard.set("", forKey: "healingFocus")
        UserDefaults.standard.set(Data(), forKey: "profileImageData")
        NoContactTracker.clearSessionKeys()
    }

    static func persistActiveSessionToScopedStorage() {
        let profileID = activeProfileID
        guard !profileID.isEmpty else { return }

        let name = UserDefaults.standard.string(forKey: "userName") ?? "Friend"
        let focus = UserDefaults.standard.string(forKey: "healingFocus") ?? ""
        updateDisplayName(name, for: profileID)
        updateHealingFocus(focus, for: profileID)

        let imageData = UserDefaults.standard.data(forKey: "profileImageData") ?? Data()
        UserDefaults.standard.set(imageData, forKey: profileImageKey(for: profileID))

        NoContactTracker.persistSessionIntoScoped(for: profileID)
    }

    // MARK: - Migration

    /// Keeps existing journal/mood rows on `app-user` by creating a matching local profile once.
    static func migrateLegacyIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: didMigrateKey) else { return }

        let existingData = UserDefaults.standard.data(forKey: profilesKey)
        let alreadyHasProfiles = (existingData?.isEmpty == false)

        if !alreadyHasProfiles {
            let legacyName = UserDefaults.standard.string(forKey: "userName")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let legacyFocus = UserDefaults.standard.string(forKey: "healingFocus") ?? ""
            let wasLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
            let hasLegacyNoContact = UserDefaults.standard.object(forKey: NoContactTracker.legacyIsActiveKey) != nil

            if wasLoggedIn || !legacyName.isEmpty || hasLegacyNoContact {
                let profile = Profile(
                    id: legacyUserID,
                    displayName: legacyName.isEmpty ? "Friend" : legacyName,
                    healingFocus: legacyFocus,
                    createdAt: .now
                )
                save([profile])
                UserDefaults.standard.set(legacyFocus, forKey: healingFocusKey(for: profile.id))

                if let image = UserDefaults.standard.data(forKey: "profileImageData") {
                    UserDefaults.standard.set(image, forKey: profileImageKey(for: profile.id))
                }

                NoContactTracker.migrateLegacyKeysIfNeeded(into: profile.id)

                if wasLoggedIn {
                    activeProfileID = profile.id
                }
            }
        }

        UserDefaults.standard.set(true, forKey: didMigrateKey)
    }

    // MARK: - Private

    private static func save(_ profiles: [Profile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }
}
