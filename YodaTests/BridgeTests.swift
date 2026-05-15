import XCTest
@testable import Yoda

final class BridgeTests: XCTestCase {
    func testGenerateMarkdown_structuresEntriesByProjectAndDate() {
        let bridge = Bridge()
        let data: [String: Any] = [
            "macrotasks": ["Inbox", "ProjectA"],
            "entries": [
                ["text": "regular note", "type": "note", "checked": false,
                 "date": "2026-05-15", "macrotask": "ProjectA"],
                ["text": "done task", "type": "todo", "checked": true,
                 "date": "2026-05-15", "macrotask": "ProjectA"],
                ["text": "open task", "type": "todo", "checked": false,
                 "date": "2026-05-14", "macrotask": "ProjectA"]
            ]
        ]
        let result = bridge.generateMarkdown(from: data)

        XCTAssertTrue(result.hasPrefix("# yoda\n"))
        XCTAssertTrue(result.contains("## ProjectA"))
        XCTAssertFalse(result.contains("## Inbox"), "Empty macrotasks should be skipped")
        XCTAssertTrue(result.contains("### 2026-05-15"))
        XCTAssertTrue(result.contains("### 2026-05-14"))
        XCTAssertTrue(result.contains("- regular note"))
        XCTAssertTrue(result.contains("- [x] done task"))
        XCTAssertTrue(result.contains("- [ ] open task"))

        let idx14 = result.range(of: "### 2026-05-14")!.lowerBound
        let idx15 = result.range(of: "### 2026-05-15")!.lowerBound
        XCTAssertLessThan(idx15, idx14, "Newer dates should appear before older ones")
    }
}
