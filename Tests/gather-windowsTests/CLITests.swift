import Testing
import Foundation
@testable import gather_windows

@Suite("CLI")
struct CLITests {

    @Test func listFlag_printsDisplayList() {
        let displays = [
            makeDisplay(index: 1, frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true, name: "Built-in"),
            makeDisplay(index: 2, frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), isMain: false, name: "External"),
        ]

        let output = CLI.formatDisplayList(displays)

        #expect(output.contains("1: Built-in"))
        #expect(output.contains("1440x900"))
        #expect(output.contains("2: External"))
        #expect(output.contains("1920x1080"))
        #expect(output.contains("(main)"))
    }

    @Test func listFlag_singleDisplay() {
        let displays = [
            makeDisplay(index: 1, frame: CGRect(x: 0, y: 0, width: 2560, height: 1440), isMain: true, name: "Studio Display"),
        ]

        let output = CLI.formatDisplayList(displays)

        #expect(output.contains("1: Studio Display"))
        #expect(output.contains("2560x1440"))
        #expect(output.contains("(main)"))
    }
}
