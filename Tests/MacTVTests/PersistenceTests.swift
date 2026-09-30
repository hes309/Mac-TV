import Foundation
import Testing
@testable import MacTVCore

@Test func stateRoundTripsAtomically() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let url = directory.appending(path: "state.json")
    let store = JSONStateStore(fileURL: url)
    var state = AppState()
    state.profile.name = "客厅"
    state.appearance.layout = .grid

    try store.save(state)
    let loaded = try store.load()

    #expect(loaded.profile.name == "客厅")
    #expect(loaded.appearance.layout == .grid)
    #expect(loaded.shortcuts == state.shortcuts)
}
