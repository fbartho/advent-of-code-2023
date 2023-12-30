import XCTest

@testable import AdventOfCode

// Make a copy of this file for every day to ensure the provided smoke tests
// pass.
final class Day15Tests: XCTestCase {
	func testPart1() {
		typealias InitSeqEntry = Day15Part1.InitSeqEntry
		XCTAssertEqual(52, InitSeqEntry("HASH").hash)
	}
}
