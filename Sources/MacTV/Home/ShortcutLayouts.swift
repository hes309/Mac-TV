import SwiftUI

struct CircularShortcutRow: View {
    @EnvironmentObject private var store: AppStore
    var focusedID: FocusState<UUID?>.Binding

    var body: some View {
        GeometryReader { geometry in
            let iconSize = store.appearance.iconSize.points
            let visibleCount = maximumVisibleCount(width: geometry.size.width, iconSize: iconSize)

            HStack(spacing: 30) {
                ForEach(visibleShortcuts(limit: visibleCount)) { shortcut in
                    shortcutButton(shortcut)
                        .id(shortcut.id)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 56)
            .padding(.vertical, 28)
            .clipped()
            .animation(.snappy(duration: 0.24, extraBounce: 0.05), value: focusedID.wrappedValue)
        }
    }

    private func maximumVisibleCount(width: CGFloat, iconSize: CGFloat) -> Int {
        let safeWidth = max(0, width - 112)
        let rawCount = max(1, Int((safeWidth + 30) / (iconSize + 30)))
        let oddCount = rawCount.isMultiple(of: 2) ? rawCount - 1 : rawCount
        return max(1, min(oddCount, store.shortcuts.count))
    }

    private func visibleShortcuts(limit: Int) -> [ShortcutItem] {
        let items = store.shortcuts
        guard !items.isEmpty else { return [] }
        let center = items.firstIndex(where: { $0.id == focusedID.wrappedValue }) ?? 0
        let count = min(limit, items.count)
        let leading = count / 2
        return (0..<count).map { offset in
            let rawIndex = center - leading + offset
            let index = (rawIndex % items.count + items.count) % items.count
            return items[index]
        }
    }

    private func shortcutButton(_ shortcut: ShortcutItem) -> some View {
        Button { store.launch(shortcut) } label: {
            ShortcutIconView(shortcut: shortcut, size: store.appearance.iconSize.points, focused: focusedID.wrappedValue == shortcut.id)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .focused(focusedID, equals: shortcut.id)
        .onMoveCommand { direction in
            guard direction == .left || direction == .right else { return }
            move(direction == .right ? 1 : -1)
        }
        .draggable(shortcut.id.uuidString)
        .dropDestination(for: String.self) { values, _ in
            guard let value = values.first, let sourceID = UUID(uuidString: value) else { return false }
            store.moveShortcut(id: sourceID, before: shortcut.id)
            return true
        }
    }

    private func move(_ delta: Int) {
        let items = store.shortcuts
        guard !items.isEmpty else { return }
        let current = items.firstIndex(where: { $0.id == focusedID.wrappedValue }) ?? 0
        guard let next = NavigationMath.circularIndex(current: current, delta: delta, count: items.count) else { return }
        focusedID.wrappedValue = items[next].id
    }
}

struct ShortcutGrid: View {
    @EnvironmentObject private var store: AppStore
    var focusedID: FocusState<UUID?>.Binding

    var body: some View {
        GeometryReader { geometry in
            let size = store.appearance.iconSize.points
            let count = max(2, Int(geometry.size.width / (size + 42)))
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: count), spacing: 30) {
                    ForEach(store.shortcuts) { shortcut in
                        Button { store.launch(shortcut) } label: {
                            ShortcutIconView(shortcut: shortcut, size: size, focused: focusedID.wrappedValue == shortcut.id)
                        }
                        .buttonStyle(.plain)
                        .focusEffectDisabled()
                        .focused(focusedID, equals: shortcut.id)
                        .onMoveCommand { direction in move(direction, columns: count) }
                        .draggable(shortcut.id.uuidString)
                        .dropDestination(for: String.self) { values, _ in
                            guard let value = values.first, let sourceID = UUID(uuidString: value) else { return false }
                            store.moveShortcut(id: sourceID, before: shortcut.id)
                            return true
                        }
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 28)
            }
        }
    }

    private func move(_ direction: MoveCommandDirection, columns: Int) {
        let items = store.shortcuts
        guard let current = items.firstIndex(where: { $0.id == focusedID.wrappedValue }) else { return }
        let delta: Int
        switch direction {
        case .left: delta = -1
        case .right: delta = 1
        case .up: delta = -columns
        case .down: delta = columns
        default: return
        }
        guard let target = NavigationMath.gridIndex(current: current, delta: delta, count: items.count) else { return }
        focusedID.wrappedValue = items[target].id
    }
}
