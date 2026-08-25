import SwiftUI
import PhotosUI
import MessageUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName = "Friend"

    @State private var message = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var attachedImages: [UIImage] = []
    @State private var showSentAlert = false
    @State private var errorMessage: String?
    @State private var showShareHint = false
    @State private var showErrorAlert = false
    @FocusState private var isMessageFocused: Bool

    private let maxPhotos = 5

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        !trimmedMessage.isEmpty || !attachedImages.isEmpty
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Feedback")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { trailingToolbar }
                .onChange(of: selectedItems) { _, newItems in
                    Task { await loadImages(from: newItems) }
                }
            .alert("Opened Gmail", isPresented: $showShareHint) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Check that To is \(AppConfig.feedbackEmail), then tap Send.")
            }
                .alert("Sent", isPresented: $showSentAlert) {
                    Button("OK") { dismiss() }
                } message: {
                    Text("Thank you. I’m listening.")
                }
                .alert("Couldn’t send", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "")
                }
        }
    }

    private var content: some View {
        ZStack {
            Color.appBackgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    introCard
                    messageCard
                    photosCard
                    sendButtons
                    helpText
                }
                .padding()
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively) 
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") { dismiss() }
                .foregroundStyle(Color.brandPrimary)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Feedback")
                .font(.title2.bold())
                .foregroundStyle(Color.brandPrimary)

            Text("Tell me what’s helping, what’s confusing, or what would feel kinder next. Screenshots help a lot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your message")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            messageEditor
        }
        .padding(18)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var messageEditor: some View {
        ZStack(alignment: .topLeading) {
            if trimmedMessage.isEmpty {
                Text("What would help you feel more supported?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
            }

            TextEditor(text: $message)
                .focused($isMessageFocused)
                .frame(minHeight: 150)
                .padding(12)
                .scrollContentBackground(.hidden)
        }
        .background(Color.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
        )
    }

    private var photosCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            Text("Optional. Add up to \(maxPhotos) screenshots or photos.")
                .font(.caption)
                .foregroundStyle(.secondary)

            photoStrip
        }
        .padding(18)
        .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                addPhotoButton

                ForEach(Array(attachedImages.enumerated()), id: \.offset) { index, image in
                    photoThumbnail(image, index: index)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    private var addPhotoButton: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxPhotos,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.plus")
                    .font(.title3)
                Text("Add")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.brandPrimary)
            .frame(width: 88, height: 88)
            .background(Color.brandPrimary.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(attachedImages.count >= maxPhotos)
    }

    private func photoThumbnail(_ image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                attachedImages.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.brandPrimary)
            }
            .offset(x: 6, y: -6)
            .accessibilityLabel("Remove photo")
        }
    }

    private var sendButtons: some View {
        VStack(spacing: 8) {
            Button(action: sendFeedback) {
                Text("Send this thought")
                    .font(.headline)
                    .foregroundStyle(Color.buttonText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSend ? Color.brandFill : Color.brandFill.opacity(0.4), in: Capsule())
            }
            .disabled(!canSend)

            Button(action: shareFeedback) {
                Text("Share with photos")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .disabled(!canSend || attachedImages.isEmpty)
        }
    }

    private var helpText: some View {
        Text("Opens Gmail with To already set to \(AppConfig.feedbackEmail). Use Share with photos if you need to attach screenshots.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emailBody: String {
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = name.isEmpty ? "Friend" : name
        let text = trimmedMessage.isEmpty ? "(No written message. See attached photos.)" : trimmedMessage
        let photoNote: String = {
            guard !attachedImages.isEmpty else { return "" }
            let count = attachedImages.count
            let label = count == 1 ? "1 photo attached" : "\(count) photos attached"
            return "\n\n---\n\(label)"
        }()

        return """
        Mend app feedback

        From: \(displayName)

        Message:
        \(text)\(photoNote)
        """
    }

    private func sendFeedback() {
        dismissKeyboard()
        guard canSend else { return }

        FeedbackSender.send(
            recipient: AppConfig.feedbackEmail,
            subject: "Mend feedback",
            body: emailBody,
            images: attachedImages,
            onMailFinished: { result in
                if result == .sent {
                    showSentAlert = true
                }
            },
            onShareFinished: {
                showShareHint = true
            },
            onUnavailable: { message in
                errorMessage = message
                showErrorAlert = true
            }
        )
    }

    private func shareFeedback() {
        dismissKeyboard()
        guard canSend else { return }
        UIPasteboard.general.string = AppConfig.feedbackEmail
        FeedbackSender.presentShare(
            body: emailBody,
            images: attachedImages,
            onFinished: {
                showShareHint = true
            }
        )
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items.prefix(maxPhotos) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        await MainActor.run {
            attachedImages = images
        }
    }
}

#Preview {
    FeedbackView()
}
