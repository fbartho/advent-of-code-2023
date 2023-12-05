import Foundation

/*
 --- Day 00: Title?? ---
 */
struct DayTemplate00Part1: AdventDayPart, TestData {
	var data: String

	static var day: Int = 0
	static var part: Int = 1

	func run() async throws {
		let lines = Array(
			data.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) })
				.filter({ !$0.isEmpty }))
		guard lines.count >= 1 else {
			fatalError("Not enough data \(lines)")
		}

		print("You can do this!")
	}
}
