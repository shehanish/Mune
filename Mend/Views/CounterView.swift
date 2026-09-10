//
//  CounterView.swift
//  Mend
//
//  Created by Shehani Hansika on 07.05.26.
//

import SwiftUI
import Combine

struct CounterView: View {
    var showsDismissButton: Bool = false

    @Environment(\.dismiss) private var dismiss

    @AppStorage(NoContactTracker.isActiveKey) private var isTrackerActive = false
    @AppStorage(NoContactTracker.startDateKey) private var startDateInterval: Double = 0
    @AppStorage(NoContactTracker.goalKey) private var storedGoal: String = ""

    @State private var showSetupSheet = false
    @State private var selectedDate: Date = .now
    @State private var selectedPeriod: String?

    private var startDate: Date {
        NoContactTracker.startDate(from: startDateInterval) ?? .now
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()

                if isTrackerActive {
                    ActiveTrackerView(startDate: startDate, goal: storedGoal.isEmpty ? nil : storedGoal) {
                        NoContactTracker.reset()
                        selectedPeriod = nil
                        selectedDate = .now
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            BlobAvatarView(width: 170, height: 120)

                            Text("Ready for a little space?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.textOnPrimary)

                            Text("Healing days give you quiet room to come back to yourself — one gentle day at a time.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.textOnPrimary.opacity(0.8))
                                .padding(.horizontal, 30)

                            Button(action: {
                                selectedDate = .now
                                selectedPeriod = nil
                                showSetupSheet = true
                            }) {
                                Text("Begin healing days gently")
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
            NoContactSetupSheet(
                selectedDate: $selectedDate,
                selectedPeriod: $selectedPeriod,
                onSave: {
                    let goal = selectedPeriod ?? NoContactTracker.defaultGoal
                    NoContactTracker.activate(startDate: selectedDate, goal: goal)
                    showSetupSheet = false
                }
            )
            .presentationDetents([.fraction(0.6), .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if isTrackerActive, let savedDate = NoContactTracker.startDate(from: startDateInterval) {
                selectedDate = savedDate
                selectedPeriod = storedGoal.isEmpty ? NoContactTracker.defaultGoal : storedGoal
            }
        }
    }
}

#Preview {
    CounterView()
}
