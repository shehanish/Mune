//
//  ChatView.swift
//  Mune
//
//  Created by Shehani Hansika on 18.05.26.
//

import SwiftUI

struct ChatView: View {
    @Environment(\.recoveryNavigator) private var navigator
    @State private var vm: ChatViewModel
    @FocusState private var isInputFocused: Bool

    init(vm: ChatViewModel) {
        _vm = State(initialValue: vm)
    }

    var body: some View {
        ZStack {
            Color.appBackgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(vm.messages) { message in
                                MessageBubble(message: message) { exercise in
                                    navigator.handle(exercise.destination)
                                }
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: vm.messages.count) { _, _ in
                        scrollToBottom(using: proxy, animated: true)
                    }
                    .onChange(of: isInputFocused) { _, isFocused in
                        if isFocused {
                            scrollToBottom(using: proxy, animated: true)
                        }
                    }
                    .onAppear {
                        scrollToBottom(using: proxy, animated: false)
                        Task {
                            await vm.sendPendingSeedMessageIfNeeded()
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                chatInputBar
            }
        }
    }

    private var chatHeader: some View {
        VStack(spacing: 3) {
            Text("Recovery coach")
                .font(.headline.bold())
                .foregroundStyle(Color.brandPrimary)
            Text("Not therapy. Chat may use AI. If you’re in danger, call emergency services.")
                .font(.caption2)
                .foregroundStyle(Color.brandPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.18)
        }
    }

    private var chatInputBar: some View {
        VStack(spacing: 0) {
            if vm.isThinking {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.cardSurfaceStrong)
                            .overlay(
                                Circle()
                                    .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
                            )
                            .frame(width: 42, height: 42)

                        BlobAvatarView(width: 22, height: 18, showShadow: false)
                            .frame(width: 42, height: 42, alignment: .center)
                            .offset(y: -1)
                    }

                    Text("thinking…")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChatViewModel.starterChips, id: \.self) { chip in
                        Button {
                            vm.applyStarterChip(chip)
                        } label: {
                            Text(chip)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.brandPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.brandPrimary.opacity(0.10), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .blocksTabSwipe()
            .padding(.top, 8)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("What’s the loudest thing right now?", text: $vm.inputText, axis: .vertical)
                    .focused($isInputFocused)
                    .padding(14)
                    .background(Color.cardSurfaceStrong)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...5)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.send)
                    .onSubmit {
                        Task { await sendAndKeepFocus() }
                    }

                Button(action: {
                    Task { await sendAndKeepFocus() }
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.brandFill.opacity(0.3)
                            : Color.brandFill
                        )
                        .clipShape(Circle())
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
    }

    private func sendAndKeepFocus() async {
        await vm.sendMessage()
        isInputFocused = true
    }

    private func scrollToBottom(using proxy: ScrollViewProxy, animated: Bool) {
        guard let last = vm.messages.last else { return }

        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

#Preview {
    struct PreviewService: AIInsightService {
        func generateMoodInsight(from input: MoodInsightInput, userName: String) async throws -> String { "Stub" }
        func generateChatResponse(conversation: [(isUser: Bool, text: String)], userName: String, context: ChatInsightContext?) async throws -> String { "Stub reply" }
    }

    let vm = ChatViewModel(aiService: PreviewService(), userName: "Friend")
    return ChatView(vm: vm)
}
