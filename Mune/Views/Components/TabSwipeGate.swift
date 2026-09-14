//
//  TabSwipeGate.swift
//  Mune
//
//  Lets a horizontally scrolling row veto the swipe-between-tabs gesture,
//  so flicking chips sideways scrolls the row instead of changing tabs.
//

import SwiftUI

/// Deliberately not observable: this is read inside a gesture callback and
/// must not trigger view updates while a drag is in flight.
final class TabSwipeGate {
    private var blockedUntil: Date = .distantPast

    var isBlocked: Bool { Date() < blockedUntil }

    func block(for seconds: TimeInterval = 0.45) {
        blockedUntil = Date().addingTimeInterval(seconds)
    }
}

private struct TabSwipeGateKey: EnvironmentKey {
    static let defaultValue = TabSwipeGate()
}

extension EnvironmentValues {
    var tabSwipeGate: TabSwipeGate {
        get { self[TabSwipeGateKey.self] }
        set { self[TabSwipeGateKey.self] = newValue }
    }
}

extension View {
    /// Mark a horizontally scrolling row so sideways drags there never change tabs.
    func blocksTabSwipe() -> some View {
        modifier(BlocksTabSwipeModifier())
    }
}

private struct BlocksTabSwipeModifier: ViewModifier {
    @Environment(\.tabSwipeGate) private var gate

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 6)
                .onChanged { _ in gate.block() }
                .onEnded { _ in gate.block() }
        )
    }
}
