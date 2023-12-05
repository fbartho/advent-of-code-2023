/*
 --- Day 1: Trebuchet?! ---

 Something is wrong with global snow production, and you've been selected to take a look. The Elves have even given you a map; on it, they've used stars to mark the top fifty locations that are likely to be having problems.

 You've been doing this long enough to know that to restore snow operations, you need to check all fifty stars by December 25th.

 Collect stars by solving puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants one star. Good luck!

 You try to ask why they can't just use a weather machine ("not powerful enough") and where they're even sending you ("the sky") and why your map looks mostly blank ("you sure ask a lot of questions") and hang on did you just say the sky ("of course, where do you think snow comes from") when you realize that the Elves are already loading you into a trebuchet ("please hold still, we need to strap you in").

 As they're making the final adjustments, they discover that their calibration document (your puzzle input) has been amended by a very young Elf who was apparently just excited to show off her art skills. Consequently, the Elves are having trouble reading the values on the document.

 The newly-improved calibration document consists of lines of text; each line originally contained a specific calibration value that the Elves now need to recover. On each line, the calibration value can be found by combining the first digit and the last digit (in that order) to form a single two-digit number.

 For example:

 1abc2
 pqr3stu8vwx
 a1b2c3d4e5f
 treb7uchet
 In this example, the calibration values of these four lines are 12, 38, 15, and 77. Adding these together produces 142.

 Consider your entire calibration document. What is the sum of all of the calibration values?
 */
struct Day01Part1: AdventDayPart {
	var data: String

	static var day: Int = 1
	static var part: Int = 1

	func run() async throws {
		let lines = data.split(separator: "\n")

		let numLines = lines.map { $0.filter(\.isNumber) }

		let firstLastNumLines = numLines.map { "\($0.first!)\($0.last!)" }

		let parsedNums = firstLastNumLines.map { Int($0)! }

		let summedNums = parsedNums.reduce(0, +)

		print(summedNums)
	}
}

/*
 --- Part Two ---

 Your calculation isn't quite right. It looks like some of the digits are actually spelled out with letters: one, two, three, four, five, six, seven, eight, and nine also count as valid "digits".

 Equipped with this new information, you now need to find the real first and last digit on each line. For example:

 two1nine
 eightwothree
 abcone2threexyz
 xtwone3four
 4nineeightseven2
 zoneight234
 7pqrstsixteen
 In this example, the calibration values are 29, 83, 13, 24, 42, 14, and 76. Adding these together produces 281.

 What is the sum of all of the calibration values?
 */
struct Day01Part2: AdventDayPart {
	var data: String

	static var day: Int = 1
	static var part: Int = 2

	func run() async throws {

		let lines = data.split(separator: "\n").map { String($0) }

		let replacedLines = lines.map { line in
			var findings: [Int: String] = [:]
			for (regex, repl) in replacements {
				let matches = line.matches(of: regex)
				for match in matches {
					let matchOutput = match.1
					let replacement = repl ?? String(matchOutput)

					let findingIndex = line.distance(
						from: line.startIndex, to: match.1.startIndex)

					findings[findingIndex] = replacement
					print(
						"\(line) \(findingIndex) \(matchOutput) \(repl ?? "nil") becomes \(replacement) \(match.range.lowerBound)"
					)
				}
			}
			let sortedKeys = Array(findings.keys).sorted(by: <)
			let orderedValues = sortedKeys.map { findings[$0]! }

			return orderedValues.reduce("", +)
		}

		let firstLastNumLines = replacedLines.map { "\($0.first!)\($0.last!)" }

		let parsedNums = firstLastNumLines.map { Int($0)! }

		let summedNums = parsedNums.reduce(0, +)

		print("Result: \(summedNums)")
	}
}
private let replacements: [(Regex<(Substring, Substring)>, String?)] = {
	do {
		return [
			(try Regex("([0-9])"), nil),  // strip non-digits (keep newlines)
			(try Regex("(one)"), "1"),
			(try Regex("(two)"), "2"),
			(try Regex("(three)"), "3"),
			(try Regex("(four)"), "4"),
			(try Regex("(five)"), "5"),
			(try Regex("(six)"), "6"),
			(try Regex("(seven)"), "7"),
			(try Regex("(eight)"), "8"),
			(try Regex("(nine)"), "9"),
		]
	}
	catch let localError {  // 1
		print(type(of: localError))
		fatalError("These are legit expressions!, \(localError)")
	}
}()
