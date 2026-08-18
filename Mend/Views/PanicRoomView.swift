//
//  PanicRoomView.swift
//  Mend
//

import SwiftUI

struct PanicRoomView: View {
    @State private var vm = PanicRoomViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showContactPicker = false
    @State private var showDrawingPad = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Header with Affirmation and Exit Button
                        HStack(alignment: .top) {
                            Text(vm.currentQuote)
                                .font(.title3.italic())
                                .foregroundColor(.brandPrimary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .onTapGesture {
                                    vm.nextQuote()
                                }
                            
                       
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // Breathing Section
                        VStack(spacing: 16) {
                            Text("Guided Breathing")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)
                            
                            BreathingCircleView()
                            
                            // Music Button
                            Button(action: {
                                vm.toggleMusic()
                            }) {
                                HStack {
                                    Image(systemName: vm.isPlayingMusic ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                    Text(vm.isPlayingMusic ? "Playing Calming Sound" : "Play Soundscape")
                                }
                                .font(.footnote.bold())
                                .foregroundColor(.brandPrimary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.5))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)
                        
                        // Grounding Exercise Card 
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Grounding Technique (5-4-3-2-1)")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)
                            
                            Text("Look around your environment and find:")
                                .font(.subheadline)
                                .foregroundColor(.brandPrimary.opacity(0.8))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                GroundingRow(number: "5", text: "Things you can see", icon: "eye.fill")
                                GroundingRow(number: "4", text: "Things you can touch", icon: "hand.tap.fill")
                                GroundingRow(number: "3", text: "Things you can hear", icon: "ear.fill")
                                GroundingRow(number: "2", text: "Things you can smell", icon: "nose.fill")
                                GroundingRow(number: "1", text: "Thing you can taste", icon: "mouth.fill")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)
                        
                        // Doodle Pad
                        Button(action: {
                            showDrawingPad = true
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Tap to draw what you feel")
                                            .font(.headline)
                                            .foregroundColor(.brandPrimary)

                                        Text(vm.saveDrawingsEnabled
                                             ? "Saved on this device. You can turn this off in Settings."
                                             : "Open the page and let it out. Enable Save drawings in Settings to keep it.")
                                            .font(.caption)
                                            .foregroundColor(.brandPrimary.opacity(0.7))
                                    }

                                    Spacer()

                                    Image(systemName: "pencil.tip.crop.circle.badge.plus")
                                        .font(.title3)
                                        .foregroundColor(.sageGreen)
                                }

                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.7))
                                    .frame(height: 96)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "scribble.variable")
                                                .font(.title2)
                                                .foregroundColor(.brandPrimary.opacity(0.75))
                                            Text("Open Drawing Pad")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.brandPrimary)
                                        }
                                    )
                            }
                            .padding()
                            .background(Color.white.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                        // Vent Text Box
                        @Bindable var bindableVM = vm
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Private Vent Space")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)
                            Text("Type whatever is on your mind. This won't be saved or read by anyone.")
                                .font(.caption)
                                .foregroundColor(.brandPrimary.opacity(0.7))
                            
                            TextEditor(text: $bindableVM.ventText)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .environment(\.colorScheme, .light)
                                .scrollContentBackground(.hidden)

                            if !bindableVM.ventText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                HStack {
                                    Spacer()

                                    Button(action: {
                                        vm.clearVentText()
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "flame.fill")
                                            Text("Burn It Down")
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.brandPrimary, Color.sageGreen],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(Capsule())
                                        .shadow(color: Color.brandPrimary.opacity(0.18), radius: 8, x: 0, y: 4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                        }
                        .padding()
                        .background(Color.white.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            Text("Need someone right now?")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // 988 Crisis Line
                            Button(action: {
                                if let url = URL(string: "tel://988"),
                                   UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red.opacity(0.12))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.red.opacity(0.80))
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("988 Suicide & Crisis Lifeline")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Call or text 988 · Free, confidential, 24/7")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.red.opacity(0.40))
                                }
                                .padding()
                                .background(Color.red.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Call 988 Suicide and Crisis Lifeline")

                            Button(action: {
                                showContactPicker = true
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.sageGreen.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.brandPrimary)
                                            .font(.system(size: 20, weight: .semibold))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Call a Friend")
                                            .font(.headline)
                                            .foregroundColor(.textOnPrimary)
                                        Text("Pick someone from your contacts")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.brandPrimary.opacity(0.5))
                                }
                                .padding()
                                .background(Color.white.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(Color.white.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
            .onAppear {
                vm.syncDrawingPreference()
            }
            .sheet(isPresented: $showDrawingPad, onDismiss: {
                vm.persistDoodlesIfNeeded()
            }) {
                DrawingPadSheet(vm: vm)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
                    }
                }
            }
        }
    }
}

#Preview {
    PanicRoomView()
}

private struct DrawingPadSheet: View {
    @State var vm: PanicRoomViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Draw what you feel")
                        .font(.headline)
                        .foregroundColor(.brandPrimary)

                    Canvas { context, size in
                        for line in vm.doodleLines {
                            var path = Path()
                            path.addLines(line.points)
                            context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                let isNew = (value.translation.width + value.translation.height == 0)
                                vm.addDoodlePoint(value.location, isNew: isNew)
                            }
                            .onEnded { _ in
                                vm.persistDoodlesIfNeeded()
                            }
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 420)
                    .padding()
                    .background(Color.white.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)

                    Button("Clear Canvas") {
                        vm.clearDoodles()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())

                    Text(vm.saveDrawingsEnabled
                         ? "Saved on this device only. You can turn this off in Settings."
                         : "Drawings stay temporary unless you enable Save drawings in Settings.")
                        .font(.caption)
                        .foregroundColor(.brandPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        vm.persistDoodlesIfNeeded()
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}
