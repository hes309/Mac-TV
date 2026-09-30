import Testing
@testable import MacTVCore

@Test func circularNavigationWrapsAtBothEnds() {
    #expect(NavigationMath.circularIndex(current: 4, delta: 1, count: 5) == 0)
    #expect(NavigationMath.circularIndex(current: 0, delta: -1, count: 5) == 4)
}

@Test func gridNavigationClampsToAvailableItems() {
    #expect(NavigationMath.gridIndex(current: 0, delta: -3, count: 5) == 0)
    #expect(NavigationMath.gridIndex(current: 3, delta: 3, count: 5) == 4)
}
