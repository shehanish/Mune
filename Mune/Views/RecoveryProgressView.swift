//
//  RecoveryProgressView.swift
//  Mune
//

import SwiftUI
import SwiftData

struct RecoveryProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @State private var vm: RecoveryProgressViewModel?
    @State private var showHistory = false

    private var userID: String {
        activeProfileID.isEmpty ? LocalProfileStore.legacyUserID : activeProfileID
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
            Text("A weekly check on how you’re really doing, not just the day count.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("This is different from today’s check-in on Home. Here you look at the week.")
                                .font(.caption)
                                .foregroundStyle(Color.brandPrimary.opacity(0.45))

                            compactDashboard(vm)

                            Text("A bad day doesn’t erase your progress.")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(Color.brandPrimary.opacity(0.65))
                                .padding(.horizontal, 2)

                            groupCard(title: "Heart", subtitle: "Pain, thoughts, urge") {
                                slider("Pain intensity", value: bindable(vm).painIntensity, range: 1...10) {
                                    "\(Int(vm.painIntensity.rounded())) / 10"
                                }
                                slider("How often you think about them", value: bindable(vm).thoughtFrequency, range: 1...5) {
                                    RecoveryProgressViewModel.thoughtLabel(for: Int(vm.thoughtFrequency.rounded()))
                                }
                                slider("Urge to contact them", value: bindable(vm).contactUrge, range: 1...10) {
                                    "\(Int(vm.contactUrge.rounded())) / 10"
                                }
                            }

                            groupCard(title: "Body", subtitle: "Rest") {
                                slider("Sleep", value: bindable(vm).sleepQuality, range: 1...3) {
                                    RecoveryProgressViewModel.sleepLabel(for: Int(vm.sleepQuality.rounded()))
                                }
                            }

                            groupCard(title: "You", subtitle: "Connection and self") {
                                slider("Loneliness", value: bindable(vm).loneliness, range: 1...3) {
                                    RecoveryProgressViewModel.lonelinessLabel(for: Int(vm.loneliness.rounded()))
                                }
                                slider("Sense of self", value: bindable(vm).senseOfSelf, range: 1...3) {
                                    RecoveryProgressViewModel.selfLabel(for: Int(vm.senseOfSelf.rounded()))
                                }
                            }

                            Button {
                                vm.save()
                            } label: {
                                Text("Save this week’s snapshot")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.brandFill)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            if let statusMessage = vm.statusMessage {
                                Text(statusMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            historySection(vm)
                        }
                        .padding(22)
                    }
                } else {
                    ProgressView()
                }
            }
            .background(Color.appBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Recovery progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .onAppear {
                if vm == nil {
                    vm = RecoveryProgressViewModel(context: modelContext, userID: userID)
                } else {
                    vm?.load()
                }
            }
        }
    }

    private func compactDashboard(_ vm: RecoveryProgressViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Your snapshot")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                Spacer()
                Text(vm.snapshots.isEmpty ? "No saves yet" : "\(vm.snapshots.count) saved")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary.opacity(0.45))
            }

            if let latest = vm.latest {
                HStack(spacing: 10) {
                    miniStat(title: "Pain", value: "\(latest.painIntensity)/10")
                    miniStat(title: "Urge", value: "\(latest.contactUrge)/10")
                    miniStat(title: "Self", value: RecoveryProgressViewModel.selfLabel(for: latest.senseOfSelf))
                }

                if let previous = vm.previous {
                    Text(comparisonLine(previous: previous, latest: latest))
                        .font(.caption)
                        .foregroundStyle(Color.brandPrimary.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Save again next week to see how things move.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(vm.summaryLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.brandPrimary.opacity(0.4))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.brandPrimary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func comparisonLine(previous: RecoverySnapshot, latest: RecoverySnapshot) -> String {
        var parts: [String] = []
        if latest.painIntensity != previous.painIntensity {
            parts.append("Pain \(previous.painIntensity) → \(latest.painIntensity)")
        }
        if latest.contactUrge != previous.contactUrge {
            parts.append("Urge \(previous.contactUrge) → \(latest.contactUrge)")
        }
        if parts.isEmpty {
            return "Compared with last time, things are holding steady."
        }
        return "Compared with last time: " + parts.joined(separator: " · ")
    }

    private func groupCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.brandPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.brandPrimary.opacity(0.45))
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func historySection(_ vm: RecoveryProgressViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showHistory.toggle()
                }
            } label: {
                HStack {
                    Text("Earlier snapshots")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.35))
                        .rotationEffect(.degrees(showHistory ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            Text("Saved only on this device.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if showHistory {
                if vm.snapshots.isEmpty {
                    Text("Your weekly snapshots will show up here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.snapshots.prefix(8), id: \.persistentModelID) { shot in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shot.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.brandPrimary.opacity(0.5))
                            Text("Pain \(shot.painIntensity) · Urge \(shot.contactUrge) · Sleep \(RecoveryProgressViewModel.sleepLabel(for: shot.sleepQuality))")
                                .font(.caption)
                                .foregroundStyle(Color.brandPrimary.opacity(0.75))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.fieldSurface, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func bindable(_ vm: RecoveryProgressViewModel) -> Bindable<RecoveryProgressViewModel> {
        Bindable(vm)
    }

    private func slider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        label: () -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                Spacer()
                Text(label())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary.opacity(0.65))
            }
            Slider(value: value, in: range, step: 1)
                .tint(Color.brandPrimary)
        }
        .padding(12)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 14))
    }
}
