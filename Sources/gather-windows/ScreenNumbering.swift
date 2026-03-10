import CoreGraphics

/// Assigns stable screen numbers: main display = 1, others sorted left-to-right
enum ScreenNumbering {
    /// Takes raw screen data, returns numbered DisplayInfo list.
    /// Main display always gets index 1. Remaining screens are numbered 2, 3, ...
    /// sorted by frame.origin.x (left-to-right).
    static func assignNumbers(_ screens: [(frame: CGRect, isMain: Bool)]) -> [DisplayInfo] {
        guard !screens.isEmpty else { return [] }

        var result: [DisplayInfo] = []

        // Main display is always #1
        if let main = screens.first(where: { $0.isMain }) {
            result.append(DisplayInfo(
                index: 1,
                frame: main.frame,
                isMain: true,
                name: "Main Display"
            ))
        }

        // Others sorted left-to-right by x origin
        let externals = screens
            .filter { !$0.isMain }
            .sorted { $0.frame.origin.x < $1.frame.origin.x }

        let startIndex = result.count + 1
        for (i, screen) in externals.enumerated() {
            let number = startIndex + i
            result.append(DisplayInfo(
                index: number,
                frame: screen.frame,
                isMain: false,
                name: "Display \(number)"
            ))
        }

        return result
    }
}
