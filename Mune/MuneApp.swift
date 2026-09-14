//
//  MuneApp.swift
//  Mune
//
//  Created by Shehani Hansika on 05.05.26.
//

import SwiftUI
import SwiftData

@main
struct MuneApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    RootTabView()
                } else {
                    WelcomeView()
                }
            }
            .preferredColorScheme(.light)
            .onAppear {
                LocalProfileStore.migrateLegacyIfNeeded()
            }
        }
        .modelContainer(for: [
            MoodEntry.self,
            JournalEntry.self,
            RealityCheckEntry.self,
            RebuildGoal.self,
            RecoverySnapshot.self
        ])
        
    }
}
