//
//  RealityCheckView.swift
//  Mune
//

import SwiftUI
import SwiftData

struct RealityCheckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @State private var vm: RealityCheckViewModel
    @State private var showHistory = true

    init(thought: String = "") {
        _vm = State(initialValue: RealityCheckViewModel(thought: thought))
    }

    private var userID: String {
        activeProfileID.isEmpty ? LocalProfileStore.legacyUserID : activeProfileID
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Write the looping thought. Answer one better question. That’s it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    stepLabel("1", "The thought")
                    TextField("Example: I’ll never find anyone like them.", text: $vm.thought, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(14)
                        .background(Color.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    stepLabel("2", "A better question")
                    Text(vm.challenge)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.brandPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16))

                    stepLabel("3", "Your honest answer")
                    TextField("Write one true thing…", text: $vm.answer, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Color.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button {
                        vm.save(userID: userID, context: modelContext)
                    } label: {
                        Text("Save this check")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(vm.canSave ? Color.brandFill : Color.brandFill.opacity(0.35))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!vm.canSave)

                    if let statusMessage = vm.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    historySection
                }
                .padding(22)
            }
            .background(Color.appBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Reality Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .onAppear {
                vm.loadHistory(userID: userID, context: modelContext)
            }
        }
    }

    private func stepLabel(_ number: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandPrimary.opacity(0.45))
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showHistory.toggle()
                }
            } label: {
                HStack {
                    Text("Earlier checks")
                        .font(.headline)
                        .foregroundStyle(Color.brandPrimary)
                    Spacer()
                    Text(vm.pastChecks.isEmpty ? "" : "\(vm.pastChecks.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.45))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary.opacity(0.35))
                        .rotationEffect(.degrees(showHistory ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            Text("Saved only on this device. Private to you.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if showHistory {
                if vm.pastChecks.isEmpty {
                    Text("Your saved checks will show up here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    ForEach(vm.pastChecks, id: \.persistentModelID) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.brandPrimary.opacity(0.5))
                            Text(entry.thought)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.brandPrimary)
                            Text(entry.challenge)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.answer)
                                .font(.footnote)
                                .foregroundStyle(Color.brandPrimary.opacity(0.75))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.fieldSurface, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}
