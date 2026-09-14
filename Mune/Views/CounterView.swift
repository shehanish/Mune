//
//  CounterView.swift
//  Mune
//
//  Created by Shehani Hansika on 07.05.26.
//

import SwiftUI
import Combine

struct CounterView: View {
    var showsDismissButton: Bool = false

    @Environment(\.dismiss) private var dismiss

    @AppStorage(HealingDaysTracker.isActiveKey) private var isTrackerActive = false
    @AppStorage(HealingDaysTracker.startDateKey) private var startDateInterval: Double = 0
    @AppStorage(HealingDaysTracker.goalKey) private var storedGoal: String = ""

    @State private var showSetupSheet = false
    @State private var selectedDate: Date = .now
    @State private var selectedPeriod: String?

    private var startDate: Date {
        HealingDaysTracker.startDate(from: startDateInterval) ?? .now
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()

                if isTrackerActive {
                    ActiveTrackerView(startDate: startDate, goal: storedGoal.isEmpty ? nil : storedGoal) {
                        HealingDaysTracker.reset()
                        selectedPeriod = nil
                        selectedDate = .now
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            BlobAvatarView(width: 170, height: 120)

                            Text("Days since last contact")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.textOnPrimary)

                            Text("Healing days is a simple count of how long you’ve gone without reaching out. Start from the last time you contacted them.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.textOnPrimary.opacity(0.8))
                                .padding(.horizontal, 30)

                            Button(action: {
                                selectedDate = .now
                                selectedPeriod = nil
                                showSetupSheet = true
                            }) {
                                Text("Start counting")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.brandFill)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        }
                        .padding(.top, 24)
                    }
                }
            }
            .toolbar {
                if showsDismissButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showSetupSheet) {
            HealingDaysSetupSheet(
                selectedDate: $selectedDate,
                selectedPeriod: $selectedPeriod,
                onSave: {
                    let goal = selectedPeriod ?? HealingDaysTracker.defaultGoal
                    HealingDaysTracker.activate(startDate: selectedDate, goal: goal)
                    showSetupSheet = false
                }
            )
            .presentationDetents([.fraction(0.6), .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if isTrackerActive, let savedDate = HealingDaysTracker.startDate(from: startDateInterval) {
                selectedDate = savedDate
                selectedPeriod = storedGoal.isEmpty ? HealingDaysTracker.defaultGoal : storedGoal
            }
        }
    }
}

#Preview {
    CounterView()
}
