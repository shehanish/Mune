//
//  RebuildView.swift
//  Mune
//

import SwiftUI
import SwiftData

struct RebuildView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @State private var vm: RebuildViewModel?

    private var userID: String {
        activeProfileID.isEmpty ? LocalProfileStore.legacyUserID : activeProfileID
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pick anything that helps you build a life that feels like yours. Tap when you’ve done it. Tomorrow this list starts fresh.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            compactDashboard(vm)

                            if let celebration = vm.celebrationMessage {
                                Text(celebration)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(Color.brandPrimary.opacity(0.7))
                                    .padding(.horizontal, 4)
                            }

                            pickSection(vm)
                        }
                        .padding(22)
                    }
                } else {
                    ProgressView()
                }
            }
            .background(Color.appBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Rebuild yourself")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .onAppear {
                if vm == nil {
                    vm = RebuildViewModel(context: modelContext, userID: userID)
                }
                vm?.refreshForToday()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    vm?.refreshForToday()
                }
            }
        }
    }

    private func compactDashboard(_ vm: RebuildViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Days you showed up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)

                Spacer(minLength: 8)

                Text(vm.showedUpDaysThisWeek == 0
                      ? "0 of 7"
                      : "\(vm.showedUpDaysThisWeek) of 7")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary.opacity(0.5))
            }

            HStack(spacing: 0) {
                ForEach(vm.lastSevenDays) { day in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(day.didShowUp
                                      ? Color.sageGreen.opacity(0.55)
                                      : Color.brandPrimary.opacity(0.08))
                                .frame(width: 28, height: 28)

                            if day.didShowUp {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.brandPrimary)
                            } else if day.isToday {
                                Circle()
                                    .stroke(Color.brandPrimary.opacity(0.35), lineWidth: 1.5)
                                    .frame(width: 28, height: 28)
                            }
                        }

                        Text(day.weekdayLetter)
                            .font(.caption2.weight(day.isToday ? .bold : .medium))
                            .foregroundStyle(
                                day.isToday
                                    ? Color.brandPrimary
                                    : Color.brandPrimary.opacity(0.45)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(dayAccessibilityLabel(day))
                }
            }

            Text(vm.statusLine)
                .font(.caption)
                .foregroundStyle(Color.brandPrimary.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func dayAccessibilityLabel(_ day: RebuildShowUpDay) -> String {
        let when = day.isToday ? "Today" : day.weekdayLetter
        if day.didShowUp {
            return "\(when), showed up"
        }
        return "\(when), not yet"
    }

    private func pickSection(_ vm: RebuildViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose what fits today")
                    .font(.headline)
                    .foregroundStyle(Color.brandPrimary)

                Text("Nothing is pre-selected. Tap what you’ve done today.")
                    .font(.caption)
                    .foregroundStyle(Color.brandPrimary.opacity(0.55))
            }

            ForEach(RebuildCategory.allCases) { category in
                VStack(alignment: .leading, spacing: 8) {
                    Label(category.rawValue, systemImage: category.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.55))

                    ChipFlowLayout(spacing: 8) {
                        ForEach(category.suggestions, id: \.self) { title in
                            let done = vm.isDoneToday(title: title, category: category)
                            Button {
                                withAnimation(.snappy) {
                                    vm.toggle(title: title, category: category)
                                }
                            } label: {
                                MuneChipLabel(
                                    title: title,
                                    isSelected: done,
                                    showsCheckmark: true,
                                    selectedForeground: .brandPrimary,
                                    unselectedForeground: .brandPrimary,
                                    selectedFill: Color.sageGreen.opacity(0.38),
                                    unselectedFill: Color.white
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(title)
                            .accessibilityHint(done ? "Removes today’s check" : "Marks that you showed up")
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
