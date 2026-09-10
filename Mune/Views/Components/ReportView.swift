//
//  ReportView.swift
//  Mend
//
//  Created by Shehani Hansika on 11.05.26.
//


import SwiftUI

struct ReportView: View {
    @State private var vm: ReportViewModel

    init(vm: ReportViewModel) {
        _vm = State(initialValue: vm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly mood totals")
                .font(.title2)
                .bold()

            if vm.isLoading {
                ProgressView()
            } else if let err = vm.lastError {
                Text("Error: \(err)").foregroundStyle(.red)
            } else if vm.weeklyMoodCounts.isEmpty {
                Text("No data for the last 7 days.")
                    .foregroundStyle(.secondary)
            } else {
                List(vm.weeklyMoodCounts) { item in
                    HStack {
                        Text(item.mood)
                        Spacer()
                        Text("\(item.count)")
                            .monospacedDigit()
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .task {
            await vm.loadWeekly()
        }
    }
}