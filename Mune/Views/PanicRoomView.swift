//
//  PanicRoomView.swift
//  Mend
//

import SwiftUI

struct PanicRoomView: View {
    @State private var vm = PanicRoomViewModel()
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @Environment(\.dismiss) var dismiss
    @State private var showContactPicker = false
    @State private var showDrawingPad = false
    @State private var showDrawingFolder = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

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

                        VStack(spacing: 16) {
                            Text("Breathe with me")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)
                                .frame(maxWidth: .infinity, alignment: .center)

                            BreathingCircleView()

                            Button(action: {
                                vm.toggleMusic()
                            }) {
                                HStack {
                                    Image(systemName: vm.isPlayingMusic ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                    Text(vm.isPlayingMusic ? "Soft sound is playing" : "Play a soft sound")
                                }
                                .font(.footnote.bold())
                                .foregroundColor(.brandPrimary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.cardSurfaceMuted)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .background(Color.cardSurfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Come back to this moment (5-4-3-2-1)")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)

                            Text("Gently look around and notice:")
                                .font(.subheadline)
                                .foregroundColor(.brandPrimary.opacity(0.8))

                            VStack(alignment: .leading, spacing: 8) {
                                GroundingRow(number: "5", text: "Things your eyes can find", icon: "eye.fill")
                                GroundingRow(number: "4", text: "Things your hands can feel", icon: "hand.tap.fill")
                                GroundingRow(number: "3", text: "Sounds around you", icon: "ear.fill")
                                GroundingRow(number: "2", text: "Scents you notice", icon: "nose.fill")
                                GroundingRow(number: "1", text: "Something you can taste", icon: "mouth.fill")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.cardSurfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Draw it out")
                                        .font(.headline)
                                        .foregroundColor(.brandPrimary)

                                    Text(vm.saveDrawingsEnabled
                                         ? "Draw, name, and keep pieces in your private folder."
                                         : "Draw to let it out. To keep drawings: go to Home, tap the profile icon, open Settings, and turn on Save drawings.")
                                        .font(.caption)
                                        .foregroundColor(.brandPrimary.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                Image(systemName: "pencil.tip.crop.circle.badge.plus")
                                    .font(.title3)
                                    .foregroundColor(.sageGreen)
                            }

                            Button(action: {
                                vm.clearCanvas()
                                showDrawingPad = true
                            }) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.cardSurfaceSoft)
                                    .frame(height: 96)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "scribble.variable")
                                                .font(.title2)
                                                .foregroundColor(.brandPrimary.opacity(0.75))
                                            Text("Start a blank page")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.brandPrimary)
                                        }
                                    )
                            }
                            .buttonStyle(.plain)

                            if vm.saveDrawingsEnabled {
                                Button(action: {
                                    showDrawingFolder = true
                                }) {
                                    HStack {
                                        Label("My drawings", systemImage: "folder.fill")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text("\(vm.savedDrawings.count)")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.brandPrimary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.brandPrimary.opacity(0.12))
                                            .clipShape(Capsule())
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.brandPrimary.opacity(0.5))
                                    }
                                    .foregroundColor(.brandPrimary)
                                    .padding(14)
                                    .background(Color.cardSurfaceMuted)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .background(Color.cardSurfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)

                        @Bindable var bindableVM = vm
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Say it here, not to them")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)
                            Text("Say what you’d send them, without sending it. Nothing here is saved or shared. I’m holding the space.")
                                .font(.caption)
                                .foregroundColor(.brandPrimary.opacity(0.7))

                            TextEditor(text: $bindableVM.ventText)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color.cardSurfaceSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                                .scrollContentBackground(.hidden)

                            if !bindableVM.ventText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                HStack {
                                    Spacer()

                                    Button(action: {
                                        vm.clearVentText()
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "flame.fill")
                                            Text("Let it go")
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
                        .background(Color.cardSurfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            Text("Need a real person right now?")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

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
                                        Text("Call someone you trust")
                                            .font(.headline)
                                            .foregroundColor(.textOnPrimary)
                                        Text("Choose someone from your contacts")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.brandPrimary.opacity(0.5))
                                }
                                .padding()
                                .background(Color.fieldSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)

                            Text("If talking to a friend isn’t enough, or you feel unsafe, these lines are here for you too.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 4)

                            Button {
                                UIApplication.shared.open(CrisisResources.findHelplineURL)
                            } label: {
                                crisisResourceRow(
                                    icon: "globe",
                                    iconColor: .red.opacity(0.80),
                                    iconBackground: Color.red.opacity(0.12),
                                    title: "Find a helpline near you",
                                    subtitle: "Local crisis lines worldwide · IASP",
                                    chevronColor: Color.red.opacity(0.40),
                                    background: Color.red.opacity(0.06),
                                    stroke: Color.red.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Find a helpline near you")

                            if let emergencyURL = CrisisResources.emergencyTelURL {
                                Button {
                                    UIApplication.shared.open(emergencyURL)
                                } label: {
                                    crisisResourceRow(
                                        icon: "cross.circle.fill",
                                        iconColor: .red.opacity(0.80),
                                        iconBackground: Color.red.opacity(0.12),
                                        title: "Call \(CrisisResources.emergencyNumber)",
                                        subtitle: "Emergency services in your region",
                                        chevronColor: Color.red.opacity(0.40),
                                        background: Color.red.opacity(0.06),
                                        stroke: Color.red.opacity(0.15)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Call emergency services \(CrisisResources.emergencyNumber)")
                            }

                            if CrisisResources.isUSRegion, let callURL = CrisisResources.usLifelineCallURL {
                                Button {
                                    UIApplication.shared.open(callURL)
                                } label: {
                                    crisisResourceRow(
                                        icon: "phone.fill",
                                        iconColor: .red.opacity(0.80),
                                        iconBackground: Color.red.opacity(0.12),
                                        title: "Call or text 988",
                                        subtitle: "Suicide & Crisis Lifeline · United States",
                                        chevronColor: Color.red.opacity(0.40),
                                        background: Color.red.opacity(0.06),
                                        stroke: Color.red.opacity(0.15)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Call 988 Suicide and Crisis Lifeline")
                            }
                        }
                        .padding()
                        .background(Color.cardSurfaceMuted)
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
            .onChange(of: activeProfileID) { _, _ in
                vm.loadForActiveProfile()
            }
            .sheet(isPresented: $showDrawingPad) {
                DrawingPadSheet(vm: vm)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showDrawingFolder) {
                SavedDrawingsFolderSheet(vm: vm, onOpenDrawing: {
                    showDrawingFolder = false
                    showDrawingPad = true
                })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker()
            }
        }
    }

    private func crisisResourceRow(
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        title: String,
        subtitle: String,
        chevronColor: Color,
        background: Color,
        stroke: Color
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(chevronColor)
        }
        .padding()
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(stroke, lineWidth: 1)
        )
    }
}

#Preview {
    PanicRoomView()
}

private struct DrawingPadSheet: View {
    @State var vm: PanicRoomViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var canvasSize: CGSize = .zero
    @State private var showSaveAlert = false
    @State private var drawingName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Draw what you’re feeling")
                        .font(.headline)
                        .foregroundColor(.brandPrimary)

                    ZStack {
                        Color.cardSurfaceSoft

                        DoodleCanvasView(lines: vm.doodleLines)
                            .gesture(
                                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                    .onChanged { value in
                                        let isNew = (value.translation.width + value.translation.height == 0)
                                        vm.addDoodlePoint(value.location, isNew: isNew)
                                    }
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 420)
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear { canvasSize = geometry.size }
                                .onChange(of: geometry.size) { _, newSize in
                                    canvasSize = newSize
                                }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)

                    HStack(spacing: 10) {
                        Button("Clear this page") {
                            vm.clearCanvas()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.brandPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.cardSurfaceSoft)
                        .clipShape(Capsule())

                        if vm.saveDrawingsEnabled {
                            Button("Keep this drawing") {
                                drawingName = defaultDrawingName
                                showSaveAlert = true
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(vm.canSaveCurrentDrawing ? Color.brandFill : Color.brandFill.opacity(0.35))
                            .clipShape(Capsule())
                            .disabled(!vm.canSaveCurrentDrawing)
                        }
                    }

                    Text(vm.saveDrawingsEnabled
                         ? "Clearing only wipes this page. Saved drawings stay in My drawings."
                         : "This page is temporary. To keep your drawings: Home → profile icon → Settings → turn on Save drawings.")
                        .font(.caption)
                        .foregroundColor(.brandPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 12)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
            .alert("Name this drawing", isPresented: $showSaveAlert) {
                TextField("Drawing name", text: $drawingName)
                Button("Save") {
                    let size = canvasSize == .zero ? CGSize(width: 350, height: 420) : canvasSize
                    _ = vm.saveCurrentDrawing(name: drawingName, canvasSize: size)
                    vm.clearCanvas()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give it a name so you can find it again when you need it.")
            }
        }
    }

    private var defaultDrawingName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Drawing · \(formatter.string(from: .now))"
    }
}

private struct SavedDrawingsFolderSheet: View {
    @State var vm: PanicRoomViewModel
    var onOpenDrawing: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var drawingToRename: SavedDrawing?
    @State private var renameText = ""
    @State private var drawingToDelete: SavedDrawing?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()

                if vm.savedDrawings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundColor(.brandPrimary.opacity(0.6))
                        Text("No saved drawings yet. That’s okay")
                            .font(.headline)
                            .foregroundColor(.brandPrimary)
                        Text("Draw something, keep it, and it will gather here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                } else {
                    List {
                        ForEach(vm.savedDrawings) { drawing in
                            SavedDrawingRow(drawing: drawing) {
                                vm.loadDrawingIntoCanvas(drawing)
                                dismiss()
                                onOpenDrawing()
                            } onRename: {
                                drawingToRename = drawing
                                renameText = drawing.name
                            } onDelete: {
                                drawingToDelete = drawing
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("My drawings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.brandPrimary)
                }
            }
            .alert("Rename drawing", isPresented: Binding(
                get: { drawingToRename != nil },
                set: { if !$0 { drawingToRename = nil } }
            )) {
                TextField("Drawing name", text: $renameText)
                Button("Save") {
                    if let drawing = drawingToRename {
                        vm.renameDrawing(id: drawing.id, name: renameText)
                    }
                    drawingToRename = nil
                }
                Button("Cancel", role: .cancel) {
                    drawingToRename = nil
                }
            }
            .alert("Delete drawing?", isPresented: Binding(
                get: { drawingToDelete != nil },
                set: { if !$0 { drawingToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let drawing = drawingToDelete {
                        vm.deleteDrawing(id: drawing.id)
                    }
                    drawingToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    drawingToDelete = nil
                }
            } message: {
                Text("This removes the drawing from your folder on this device.")
            }
        }
    }
}

private struct SavedDrawingRow: View {
    let drawing: SavedDrawing
    var onOpen: () -> Void
    var onRename: () -> Void
    var onDelete: () -> Void

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: drawing.createdAt)
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                DoodleCanvasView(
                    lines: drawing.doodleLines,
                    sourceSize: CGSize(width: drawing.canvasWidth, height: drawing.canvasHeight),
                    lineWidthScale: 0.8
                )
                .frame(width: 72, height: 72)
                .background(Color.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(drawing.name)
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                        .lineLimit(1)
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button("Open on canvas", systemImage: "pencil.and.outline", action: onOpen)
            Button("Rename", systemImage: "pencil", action: onRename)
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
}
