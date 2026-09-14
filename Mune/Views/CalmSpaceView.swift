//
//  CalmSpaceView.swift
//  Mune
//

import SwiftUI

struct CalmSpaceView: View {
    @State private var vm = CalmSpaceViewModel()
    @AppStorage("activeProfileID") private var activeProfileID = ""
    @Environment(\.dismiss) var dismiss
    @State private var showContactPicker = false
    @State private var showDrawingPad = false
    @State private var showDrawingFolder = false
    @Environment(\.recoveryNavigator) private var navigator

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundGradient
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        Text(vm.currentQuote)
                            .font(.footnote.italic())
                            .foregroundColor(.brandPrimary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .onTapGesture { vm.nextQuote() }

                        Button {
                            navigator.openContactUrge()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.heart.fill")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("I want to text them")
                                        .font(.headline)
                                    Text("Slow down before you send")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.footnote.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(Color.brandFill)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .accessibilityLabel("I want to text them. Slow down before you send.")

                        callAFriendCard
                        breatheCard
                        rideTheWaveCard
                        groundCard
                        drawCard
                        writeInJournalCard
                        peopleCard

                        Spacer(minLength: 24)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    scrollToCalmFocus(proxy)
                }
                .onChange(of: navigator.calmFocus) { _, _ in
                    scrollToCalmFocus(proxy)
                }
                }
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
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-open-urge-wave") {
                    navigator.openUrgeWave()
                }
            }
        }
    }

    private var rideTheWaveCard: some View {
        calmCard {
            Text("2 quiet minutes")
                .font(.headline)
                .foregroundColor(.brandPrimary)

            Text("For when the feeling spikes. Sit with it until it softens. No texting decisions here.")
                .font(.subheadline)
                .foregroundColor(.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                navigator.openUrgeWave()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "water.waves")
                        .font(.title3)
                    Text("Start the 2 minutes")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(Color.brandPrimary)
                .padding(14)
                .background(Color.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("2 quiet minutes. Sit with the feeling until it softens.")
        }
    }

    private var callAFriendCard: some View {
        calmCard {
            Text("Call a friend")
                .font(.headline)
                .foregroundColor(.brandPrimary)

            Text("A real voice can help when this feels too big alone.")
                .font(.subheadline)
                .foregroundColor(.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showContactPicker = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.sageGreen.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "phone.fill")
                            .foregroundColor(.brandPrimary)
                            .font(.system(size: 18, weight: .semibold))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pick someone you trust")
                            .font(.headline)
                            .foregroundColor(.textOnPrimary)
                        Text("Opens your contacts")
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
            .accessibilityLabel("Call a friend. Pick someone you trust.")
        }
    }

    private var breatheCard: some View {
        calmCard {
            Text("Breathe with me")
                .font(.headline)
                .foregroundColor(.brandPrimary)

            Text("Slow breaths can quiet the rush in your chest.")
                .font(.subheadline)
                .foregroundColor(.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                BreathingCircleView()
                    .id(CalmSpaceFocus.breathe)
                Button(action: { vm.toggleMusic() }) {
                    HStack {
                        Image(systemName: vm.isPlayingMusic ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        Text(vm.isPlayingMusic ? "Sound is on" : "Play a sound")
                    }
                    .font(.footnote.bold())
                    .foregroundColor(.brandPrimary)
                }
            }
        }
    }

    private var groundCard: some View {
        calmCard {
            Text("Come back to your senses")
                .font(.headline)
                .foregroundColor(.brandPrimary)

            Text("Look around and name what is here with you. It helps when your mind is far away.")
                .font(.subheadline)
                .foregroundColor(.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                GroundingRow(number: "5", text: "Things your eyes can find", icon: "eye.fill")
                GroundingRow(number: "4", text: "Things your hands can feel", icon: "hand.tap.fill")
                GroundingRow(number: "3", text: "Sounds around you", icon: "ear.fill")
                GroundingRow(number: "2", text: "Scents you notice", icon: "nose.fill")
                GroundingRow(number: "1", text: "Something you can taste", icon: "mouth.fill")
            }
            .id(CalmSpaceFocus.ground)
        }
    }

    private var drawCard: some View {
        calmCard {
            Text("Scribble for a minute")
                .font(.headline)
                .foregroundColor(.brandPrimary)

            Text("No art needed. Just put something on the page.")
                .font(.subheadline)
                .foregroundColor(.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
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
                                Text("Open a blank page")
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
                        .background(Color.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .id(CalmSpaceFocus.draw)
        }
    }

    private var writeInJournalCard: some View {
        calmCard {
            Text("Need to write it out?")
                .font(.headline)
                .foregroundColor(.brandPrimary)

            Text("Journal is where words get saved. Come back here when you need calm tools.")
                .font(.subheadline)
                .foregroundColor(.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                navigator.openJournal()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "book.pages.fill")
                        .font(.title3)
                    Text("Open Journal")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(Color.brandPrimary)
                .padding(14)
                .background(Color.fieldSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Journal to write it out")
        }
    }

    private var peopleCard: some View {
        calmCard {
            Text("If you need more help")
                .font(.headline)
                .foregroundColor(.brandPrimary)

            Text("If a friend isn’t enough, or you feel unsafe, these lines are here.")
                .font(.subheadline)
                .foregroundColor(.brandPrimary.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                Button {
                    UIApplication.shared.open(CrisisResources.findHelplineURL)
                } label: {
                    crisisResourceRow(
                        icon: "globe",
                        iconColor: .red.opacity(0.80),
                        iconBackground: Color.red.opacity(0.12),
                        title: "Find a helpline near you",
                        subtitle: "Local crisis lines worldwide, IASP",
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
                            subtitle: "Suicide and Crisis Lifeline, United States",
                            chevronColor: Color.red.opacity(0.40),
                            background: Color.red.opacity(0.06),
                            stroke: Color.red.opacity(0.15)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Call 988 Suicide and Crisis Lifeline")
                }
            }
        }
    }

    private func calmCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardSurfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func scrollToCalmFocus(_ proxy: ScrollViewProxy) {
        guard let focus = navigator.calmFocus else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(focus, anchor: .center)
            }
            navigator.calmFocus = nil
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
    CalmSpaceView()
}

private struct DrawingPadSheet: View {
    @State var vm: CalmSpaceViewModel
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
                    Text("Draw whatever is here")
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

                    Toggle(isOn: Binding(
                        get: { vm.saveDrawingsEnabled },
                        set: { vm.saveDrawingsEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save drawings")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.brandPrimary)
                            Text(vm.saveDrawingsEnabled
                                 ? "Turned on. Use Keep this drawing to save to My drawings."
                                 : "Turn on to keep drawings instead of only drawing for the moment.")
                                .font(.caption)
                                .foregroundColor(.brandPrimary.opacity(0.65))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Color.brandPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.cardSurfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
    @State var vm: CalmSpaceViewModel
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
                        Text("Draw something, keep it, and it’ll show up here.")
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
