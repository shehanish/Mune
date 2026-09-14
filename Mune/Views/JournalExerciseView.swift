//
//  JournalExerciseView.swift
//  Mune
//

import SwiftUI
import SwiftData

struct JournalExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("activeProfileID") private var activeProfileID = ""

    let exercise: GuidedJournalExercise
    @State private var answers: [String: String] = [:]
    @State private var statusMessage: String?

    init(exerciseID: String) {
        self.exercise = RecoveryExerciseCatalog.guided(id: exerciseID)
            ?? RecoveryExerciseCatalog.guided[0]
    }

    init(exercise: GuidedJournalExercise) {
        self.exercise = exercise
    }

    private var userID: String {
        activeProfileID.isEmpty ? LocalProfileStore.legacyUserID : activeProfileID
    }

    private var canSave: Bool {
        exercise.fields.contains { field in
            !(answers[field.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(exercise.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(exercise.fields) { field in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(field.prompt)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.brandPrimary)
                            TextField("Write here…", text: binding(for: field.id), axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(Color.fieldSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    if let closingLine = exercise.closingLine {
                        Text(closingLine)
                            .font(.subheadline.italic())
                            .foregroundStyle(Color.brandPrimary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.sageGreen.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
                    }

                    Button(action: save) {
                        Text("Save this exercise")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(canSave ? Color.brandFill : Color.brandFill.opacity(0.35))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(22)
            }
            .background(Color.appBackgroundGradient.ignoresSafeArea())
            .navigationTitle(exercise.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
        }
    }

    private func binding(for id: String) -> Binding<String> {
        Binding(
            get: { answers[id] ?? "" },
            set: { answers[id] = $0 }
        )
    }

    private func save() {
        let body = exercise.fields.map { field in
            let answer = (answers[field.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(field.prompt)\n\(answer.isEmpty ? "(blank)" : answer)"
        }
        .joined(separator: "\n\n")

        let closing = exercise.closingLine.map { "\n\n\($0)" } ?? ""
        let entry = JournalEntry(
            userID: userID,
            journalText: body + closing,
            transcript: nil,
            gratitudeOne: "",
            gratitudeTwo: "",
            gratitudeThree: "",
            exerciseID: exercise.id
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .journalEntriesDidChange, object: nil)
            statusMessage = "Saved. I’m holding this with you."
        } catch {
            statusMessage = "I couldn’t save that just now."
        }
    }
}
