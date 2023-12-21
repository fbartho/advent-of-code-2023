import XCTest

@testable import AdventOfCode

final class Day12Tests: XCTestCase {
	typealias Record = Day12Part1.SpringConditionRecord
	typealias CacheKey = Record.BucketAssignmentCacheKey
	func testBasic1() {
		XCTAssertEqual(0, Record("# 0").possibleArrangements)
		XCTAssertEqual(0, Record("# 2").possibleArrangements)

		XCTAssertEqual(1, Record("# 1").possibleArrangements)

		XCTAssertEqual(1, Record("## 2").possibleArrangements)
		XCTAssertEqual(1, Record("#.# 1,1").possibleArrangements)
		XCTAssertEqual(1, Record(".#.# 1,1").possibleArrangements)
	}
	func testBasic2() {
		XCTAssertEqual(1, Record("? 1").possibleArrangements)
		XCTAssertEqual(1, Record("#? 1").possibleArrangements)
		XCTAssertEqual(1, Record("#?# 3").possibleArrangements)
		XCTAssertEqual(1, Record("#?# 1,1").possibleArrangements)
	}
	func test1() {
		XCTAssertEqual(4, Record("??.?? 1,1").possibleArrangements)
	}
	func test2() {
		XCTAssertEqual(3, Record("??? 1").possibleArrangements)
		XCTAssertEqual(2, Record("?.? 1").possibleArrangements)
		XCTAssertEqual(1, Record("?.? 1,1").possibleArrangements)
		XCTAssertEqual(1, Record("??? 3").possibleArrangements)
	}
	func test3() {
		XCTAssertEqual(1, Record("..? 1").possibleArrangements)
		XCTAssertEqual(2, Record(".?? 1").possibleArrangements)
		XCTAssertEqual(1, Record(".?? 2").possibleArrangements)
		XCTAssertEqual(1, Record("#?? 2").possibleArrangements)
		XCTAssertEqual(2, Record("??? 2").possibleArrangements)
	}
	func test20() {
		XCTAssertEqual(1, Record("???.### 1,1,3").possibleArrangements)
	}
}
