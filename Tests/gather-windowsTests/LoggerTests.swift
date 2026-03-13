import Testing
import Foundation
@testable import gather_windows

@Suite("Logger")
struct LoggerTests {

    private func temporaryLogPath() -> String {
        NSTemporaryDirectory() + "GatherWindows-test-\(UUID().uuidString).log"
    }

    @Test @MainActor func fileLogging_writesToFile() throws {
        let path = temporaryLogPath()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let logger = FileLogger(path: path)
        logger.write("hello from test")

        let contents = try String(contentsOfFile: path, encoding: .utf8)
        #expect(contents.contains("hello from test"))
    }

    @Test @MainActor func fileLogging_includesTimestamp() throws {
        let path = temporaryLogPath()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let logger = FileLogger(path: path)
        logger.write("timestamped message")

        let contents = try String(contentsOfFile: path, encoding: .utf8)
        // ISO 8601 timestamps start with a year like 2026-
        #expect(contents.contains("202"))
        #expect(contents.contains("] timestamped message"))
    }

    @Test @MainActor func fileLogging_appendsMultipleLines() throws {
        let path = temporaryLogPath()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let logger = FileLogger(path: path)
        logger.write("line one")
        logger.write("line two")

        let contents = try String(contentsOfFile: path, encoding: .utf8)
        let lines = contents.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 2)
        #expect(lines[0].contains("line one"))
        #expect(lines[1].contains("line two"))
    }

    @Test @MainActor func logVerbose_writesToFileInDebug() throws {
        #if VERBOSE_LOGGING
        let path = temporaryLogPath()
        defer { try? FileManager.default.removeItem(atPath: path) }

        setFileLogger(FileLogger(path: path))
        defer { setFileLogger(nil) }

        logVerbose("verbose file test")

        let contents = try String(contentsOfFile: path, encoding: .utf8)
        #expect(contents.contains("verbose file test"))
        #else
        // In release builds, this test is a no-op
        #endif
    }
}
