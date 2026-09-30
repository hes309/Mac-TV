import Foundation

enum NavigationMath {
    static func circularIndex(current: Int, delta: Int, count: Int) -> Int? {
        guard count > 0 else { return nil }
        return (current + delta % count + count) % count
    }

    static func gridIndex(current: Int, delta: Int, count: Int) -> Int? {
        guard count > 0 else { return nil }
        return min(max(current + delta, 0), count - 1)
    }
}
