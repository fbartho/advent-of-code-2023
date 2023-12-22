import XCTest

@testable import AdventOfCode

final class Day12Tests: XCTestCase {
	typealias Record = Day12Part1.SpringConditionRecord
	typealias CacheKey = Record.AssignmentCacheKey
	func testAssignmentCacheKey1() {
		XCTAssertTrue(CacheKey(assignments: [], brokenRunLengths: []).simplified().isFullyValidated)
		XCTAssertTrue(CacheKey(assignments: [.working], brokenRunLengths: []).simplified().isFullyValidated)
		XCTAssertTrue(
			CacheKey(assignments: [.working, .working], brokenRunLengths: []).simplified().isFullyValidated)

		XCTAssertTrue(CacheKey(assignments: [.broken], brokenRunLengths: [1]).simplified().isFullyValidated)
		XCTAssertTrue(
			CacheKey(assignments: [.broken, .broken], brokenRunLengths: [2]).simplified().isFullyValidated)
		XCTAssertTrue(
			CacheKey(assignments: [.broken, .working, .broken], brokenRunLengths: [1, 1]).simplified()
				.isFullyValidated)
		XCTAssertFalse(CacheKey(assignments: [.broken], brokenRunLengths: []).simplified().isFullyValidated)
		XCTAssertFalse(CacheKey(assignments: [], brokenRunLengths: [1]).simplified().isFullyValidated)

		XCTAssertEqual(
			String(describing: CacheKey(assignments: [.broken], brokenRunLengths: [1, 1]).simplified()),
			String(describing: CacheKey(assignments: [], brokenRunLengths: [1])))

		XCTAssertEqual(
			String(
				describing: CacheKey(
					assignments: [.broken, .unknown, .working, .unknown, .unknown],
					brokenRunLengths: [1, 1]
				)
				.simplified()),
			String(
				describing: CacheKey(
					assignments: [.unknown, .working, .unknown, .unknown], brokenRunLengths: [1])))

		XCTAssertEqual(
			String(
				describing: CacheKey(
					assignments: [
						.working, .broken, .unknown, .working, .unknown, .unknown, .working,
					], brokenRunLengths: [1, 1]
				)
				.simplified()),
			String(
				describing: CacheKey(
					assignments: [.unknown, .working, .unknown, .unknown], brokenRunLengths: [1])))

		XCTAssertEqual(
			String(describing: CacheKey(assignments: [.broken], brokenRunLengths: [2]).simplified()),
			String(describing: CacheKey.invalidKey))

		XCTAssertEqual(
			String(
				describing: CacheKey(assignments: [.broken, .broken], brokenRunLengths: [1])
					.simplified()),
			String(describing: CacheKey(assignments: [.broken, .broken], brokenRunLengths: [1])))

		XCTAssertEqual(
			String(
				describing: CacheKey(
					assignments: [.broken, .working, .broken, .broken, .broken],
					brokenRunLengths: [1, 3]
				)
				.simplified()),
			String(describing: CacheKey(assignments: [], brokenRunLengths: [])))

		XCTAssertFalse(
			CacheKey(
				assignments: [
					.broken, .broken, .working, .broken, .unknown, .broken, .unknown, .broken,
					.unknown, .broken, .unknown, .broken, .unknown,
				], brokenRunLengths: [3, 1, 6]
			)
			.isValid(before: 4))
	}
	func testAssignmentCacheKey2() {
		XCTAssertEqual(
			String(
				describing: CacheKey(
					assignments: [.broken, .broken, .broken, .broken, .broken, .broken, .unknown],
					brokenRunLengths: [6]
				)
				.simplified()),
			String(describing: CacheKey(assignments: [.unknown], brokenRunLengths: [])))
	}
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
		XCTAssertEqual(1, Record([.unknown, .unknown], []).possibleArrangements)
		XCTAssertEqual(1, Record([.unknown], [1]).possibleArrangements)
		XCTAssertEqual(0, Record("?? 1,1").possibleArrangements)
		XCTAssertEqual(0, Record("#.? 2").possibleArrangements)
		XCTAssertEqual(0, Record("?.? 2").possibleArrangements)
		XCTAssertEqual(3, Record("??? 1").possibleArrangements)
		XCTAssertEqual(2, Record("??? 2").possibleArrangements)
		XCTAssertEqual(1, Record("#?# 1,1").possibleArrangements)
		XCTAssertEqual(1, Record("### 3").possibleArrangements)
		XCTAssertEqual(1, Record("#?# 3").possibleArrangements)
	}
	func testBasic3() {
	}
	func test1() {
		XCTAssertEqual(1, Record("?.### 1,3").possibleArrangements)
		XCTAssertEqual(1, Record("???.### 1,1,3").possibleArrangements)
		XCTAssertEqual(4, Record("??.?? 1,1").possibleArrangements)
		XCTAssertEqual(2, Record("?.? 1").possibleArrangements)
		XCTAssertEqual(1, Record("?.? 1,1").possibleArrangements)
		XCTAssertEqual(1, Record("??? 3").possibleArrangements)
		XCTAssertEqual(1, Record("????.#...#... 4,1,1").possibleArrangements)
	}
	func test2() {
		XCTAssertEqual(1, Record("#?#?#? 6").possibleArrangements)
		XCTAssertEqual(1, Record("#?#?#?#? 1,6").possibleArrangements)
		XCTAssertEqual(1, Record("?#?#?#?#? 1,6").possibleArrangements)
		XCTAssertEqual(0, Record("#?#?#?#?#? 1,6").possibleArrangements)
		XCTAssertEqual(1, Record("#?#?#?#?#?#? 3,1,6").possibleArrangements)
		XCTAssertEqual(1, Record("?#?#?#?#?#?#? 3,1,6").possibleArrangements)
		XCTAssertEqual(0, Record("#?#?#?#?#?#?#? 3,1,6").possibleArrangements)
		XCTAssertEqual(1, Record("?#?#?#?#?#?#?#? 1,3,1,6").possibleArrangements)
	}
	func test3() {
		XCTAssertEqual(4, Record("????.######..#####. 1,6,5").possibleArrangements)
	}
	func test4() {
		XCTAssertEqual(10, Record("?###???????? 3,2,1").possibleArrangements)
		XCTAssertEqual(1, Record("..? 1").possibleArrangements)
		XCTAssertEqual(2, Record(".?? 1").possibleArrangements)
		XCTAssertEqual(1, Record(".?? 2").possibleArrangements)
		XCTAssertEqual(1, Record("#?? 2").possibleArrangements)
	}
	func test20() {
	}
}
