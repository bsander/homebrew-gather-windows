import Testing
import CoreGraphics
@testable import gather_windows

@Suite("ScreenNumbering")
struct ScreenNumberingTests {

    @Test func mainDisplayAlwaysGetsNumber1() {
        let screens: [(frame: CGRect, isMain: Bool)] = [
            (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true)
        ]
        let result = ScreenNumbering.assignNumbers(screens)

        #expect(result.count == 1)
        #expect(result[0].index == 1)
        #expect(result[0].isMain == true)
    }

    @Test func mainIsFirst_othersLeftToRight() {
        let screens: [(frame: CGRect, isMain: Bool)] = [
            (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true),
            (frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), isMain: false),
            (frame: CGRect(x: 3360, y: 0, width: 2560, height: 1440), isMain: false),
        ]
        let result = ScreenNumbering.assignNumbers(screens)

        #expect(result.count == 3)
        #expect(result[0].index == 1)
        #expect(result[0].isMain == true)
        #expect(result[1].index == 2)
        #expect(result[1].frame.origin.x == 1440)
        #expect(result[2].index == 3)
        #expect(result[2].frame.origin.x == 3360)
    }

    @Test func mainNotFirstInArray_stillGetsNumber1() {
        // Main display is second in the array but should still be 1
        let screens: [(frame: CGRect, isMain: Bool)] = [
            (frame: CGRect(x: -1920, y: 0, width: 1920, height: 1080), isMain: false),
            (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true),
        ]
        let result = ScreenNumbering.assignNumbers(screens)

        #expect(result.count == 2)
        // Main should be index 1
        let main = result.first { $0.isMain }!
        #expect(main.index == 1)
        // External on the left should be index 2
        let external = result.first { !$0.isMain }!
        #expect(external.index == 2)
        #expect(external.frame.origin.x == -1920)
    }

    @Test func externalsOrderedByXPosition() {
        let screens: [(frame: CGRect, isMain: Bool)] = [
            (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true),
            (frame: CGRect(x: 3000, y: 0, width: 1920, height: 1080), isMain: false),
            (frame: CGRect(x: -2560, y: 0, width: 2560, height: 1440), isMain: false),
        ]
        let result = ScreenNumbering.assignNumbers(screens)

        #expect(result[0].index == 1) // main
        #expect(result[0].isMain == true)
        // External sorted by x: -2560 first, then 3000
        #expect(result[1].index == 2)
        #expect(result[1].frame.origin.x == -2560)
        #expect(result[2].index == 3)
        #expect(result[2].frame.origin.x == 3000)
    }

    @Test func emptyScreens_returnsEmpty() {
        let result = ScreenNumbering.assignNumbers([])
        #expect(result.isEmpty)
    }

    @Test func namesAreCorrect() {
        let screens: [(frame: CGRect, isMain: Bool)] = [
            (frame: CGRect(x: 0, y: 0, width: 1440, height: 900), isMain: true),
            (frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080), isMain: false),
        ]
        let result = ScreenNumbering.assignNumbers(screens)

        #expect(result[0].name == "Main Display")
        #expect(result[1].name == "Display 2")
    }
}
