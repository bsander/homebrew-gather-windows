import Testing
@testable import gather_windows

@Suite("Integration")
struct IntegrationTests {

    @Test func realDisplayEnumeration_returnsAtLeastOneDisplay() {
        let dm = DisplayManager()
        let displays = dm.getAllDisplays()

        #expect(!displays.isEmpty)
        #expect(displays.contains { $0.isMain })
    }

    @Test func realDisplayHasSafeArea_smallerThanFrame() {
        let dm = DisplayManager()
        let displays = dm.getAllDisplays()

        for display in displays {
            let safe = display.safeArea
            #expect(safe.width < display.width)
            #expect(safe.height < display.height)
        }
    }
}
