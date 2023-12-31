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
					assignments: [.unknown, .unknown], brokenRunLengths: [1])))

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
					assignments: [.unknown, .unknown], brokenRunLengths: [1])))

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

		XCTAssertEqual(
			String(
				describing: CacheKey(
					assignments: [.broken, .broken, .broken, .broken, .broken, .broken, .unknown],
					brokenRunLengths: [6]
				)
				.simplified()),
			String(describing: CacheKey.onlyOnePathKey))

		XCTAssertEqual(
			String(
				describing: CacheKey(
					// ##?##?.???      - 5,1
					assignments: [
						.broken, .broken, .unknown, .broken, .broken, .unknown, .working,
						.unknown, .unknown, .unknown,
					],
					brokenRunLengths: [5, 1]
				)
				.injecting(.broken, at: 2)),
			String(
				describing: CacheKey(
					assignments: [.unknown, .unknown, .unknown], brokenRunLengths: [1])))

		XCTAssertEqual(
			String(
				describing: CacheKey(
					// Strings of ? and . with no broken-run-lengths remaining is trivially exactly 1 outcome: all-gears-working
					// ?.??.???
					assignments: [
						.unknown,
						.working,
						.unknown, .unknown,
						.working,
						.unknown, .unknown, .unknown,
						.working,
						.unknown, .unknown, .unknown,
					],
					brokenRunLengths: []
				)
				.simplified()),
			String(
				describing: CacheKey.onlyOnePathKey))

		XCTAssertEqual(
			String(
				describing: CacheKey(
					// ##.? 2
					assignments: [
						.broken, .broken, .working, .unknown,
					],
					brokenRunLengths: [2]
				)
				.simplified()),
			String(
				describing: CacheKey.onlyOnePathKey))

		XCTAssertEqual(
			String(
				describing: CacheKey(
					// ?#?.##.?
					assignments: [
						.unknown, .broken, .unknown, .working, .broken, .broken, .working,
						.unknown,
					],
					brokenRunLengths: [2, 2]
				)
				.injecting(.broken, at: 0)),
			String(
				describing: CacheKey.onlyOnePathKey))
	}
	func testAssignmentCacheKey2() {

	}
	func testSpringConditionRecordParse() {
		let record = Day12Part1.SpringConditionRecord("# 12,2")
		let expected = Day12Part1.SpringConditionRecord([.broken], [12, 2])
		XCTAssertEqual(String(describing: record), String(describing: expected))
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
	func testButVerify() {
		let puzzleLines = Day12Part1.loadData().splitAndTrim(separator: "\n")
		let verifiedLines = Day12Part1.loadData(testDataSuffix: ".verify").splitAndTrim(separator: "\n")
			.dropLast().map({ Int($0)! })

		var newTestCases: [String] = []
		for (puzzle, solution) in zip(puzzleLines, verifiedLines) {
			let calculated = Record(puzzle).possibleArrangements
			XCTAssertEqual(
				calculated, solution, "\(puzzle) should have been \(solution) but was \(calculated)")
			if calculated != solution {
				newTestCases.append(
					"XCTAssertEqual(\(solution), Record(\"\(puzzle)\").possibleArrangements)")
			}
		}
		print(newTestCases.joined(separator: "\n"))
	}
	func testExtras1() {
		XCTAssertEqual(4, Record("?.?.??#?.##.?. 1,1,2,2").possibleArrangements)
	}
	func testExtras2() {
		XCTAssertEqual(4, Record("?.?.??#?.##.?. 1,1,2,2").possibleArrangements)
		XCTAssertEqual(1, Record("#?.#.#?.????##.? 1,1,1,5,1").possibleArrangements)
		XCTAssertEqual(3, Record("..????##?.#? 1,4,1").possibleArrangements)
		XCTAssertEqual(3, Record("?.??##??#?..#? 4,2,1").possibleArrangements)
		XCTAssertEqual(2, Record("?#??????#??####?.#? 15,1").possibleArrangements)
		XCTAssertEqual(1, Record(".##????#?##?.#?. 10,1").possibleArrangements)
		XCTAssertEqual(5, Record("#??????#?..#? 2,1,2,1").possibleArrangements)
		XCTAssertEqual(6, Record("??###?.#.???? 4,1,1,1").possibleArrangements)
		XCTAssertEqual(2, Record("?#???#??#?.#.????.. 5,2,1,4").possibleArrangements)
		XCTAssertEqual(4, Record("#?..#..??.?? 1,1,1,1").possibleArrangements)
		XCTAssertEqual(72, Record("???#?.#.???????.?.? 4,1,1,1,1,1").possibleArrangements)
	}
}
