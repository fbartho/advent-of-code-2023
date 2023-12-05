import Foundation

/*
 --- Day 00: Title?? ---
 */
struct DayTemplate00Part1: AdventDayPart, TestData {
	var data: String

	static var day: Int = 0
	static var part: Int = 1

	func run() async throws {
		let lines = data.splitAndTrim(separator: "\n")
		guard lines.count >= 1 else {
			fatalError("Not enough data \(lines)")
		}
		guard lines.count >= 1 else {
			fatalError("Not enough data \(lines)")
		}

		print("You can do this!")
	}
}
