import Foundation

/*
 --- Day 3: Gear Ratios ---

 You and the Elf eventually reach a gondola lift station; he says the gondola lift will take you up to the water source, but this is as far as he can bring you. You go inside.

 It doesn't take long to find the gondolas, but there seems to be a problem: they're not moving.

 "Aaah!"

 You turn around to see a slightly-greasy Elf with a wrench and a look of surprise. "Sorry, I wasn't expecting anyone! The gondola lift isn't working right now; it'll still be a while before I can fix it." You offer to help.

 The engineer explains that an engine part seems to be missing from the engine, but nobody can figure out which one. If you can add up all the part numbers in the engine schematic, it should be easy to work out which part is missing.

 The engine schematic (your puzzle input) consists of a visual representation of the engine. There are lots of numbers and symbols you don't really understand, but apparently any number adjacent to a symbol, even diagonally, is a "part number" and should be included in your sum. (Periods (.) do not count as a symbol.)

 Here is an example engine schematic:

 467..114..
 ...*......
 ..35..633.
 ......#...
 617*......
 .....+.58.
 ..592.....
 ......755.
 ...$.*....
 .664.598..
 In this schematic, two numbers are not part numbers because they are not adjacent to a symbol: 114 (top right) and 58 (middle right). Every other number is adjacent to a symbol and so is a part number; their sum is 4361.

 Of course, the actual engine schematic is much larger. What is the sum of all of the part numbers in the engine schematic?
 */

struct Day03Part1: AdventDayPart {
	var data: String

	static var day: Int = 3
	static var part: Int = 1

	func run() async throws {
		let lines = Array(
			data.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) })
				.filter({ !$0.isEmpty }))
		guard lines.count >= 1 else {
			fatalError("Not enough data \(lines)")
		}

		let schematic = Schematic(lines: lines)

		print(schematic)

		print("-------")
		schematic.tagPartNumbers()
		print("-------")

		let partNumbers = schematic.allPartNumbers.map { $0.num }
		print("Part Numbers: \(partNumbers)")

		let sumOfPartNumbers = partNumbers.reduce(0, +)
		print("Sum: \(sumOfPartNumbers)")
	}

	class SchematicNumber: Equatable, Hashable, Identifiable, CustomDebugStringConvertible {
		let id = UUID()

		let num: Int
		let range: SchematicRange

		var isPartNumber: Bool = false

		init(num: Int, range: SchematicRange) {
			self.num = num
			self.range = range
		}

		static func == (lhs: SchematicNumber, rhs: SchematicNumber) -> Bool {
			return lhs.id == rhs.id
		}
		func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}
		var debugDescription: String {
			return "\(num)\(range)"
		}
	}

	struct SchematicRange: Equatable, Hashable, CustomDebugStringConvertible {
		var x: ClosedRange<Int>
		var y: ClosedRange<Int>

		func adjacentRange(clampedTo box: SchematicRange) -> SchematicRange {
			return SchematicRange(
				x: ((x.lowerBound - 1) ... (x.upperBound + 1)).clamped(to: box.x),
				y: ((y.lowerBound - 1) ... (y.upperBound + 1)).clamped(to: box.y))
		}

		var debugDescription: String {
			return "[\(x) \(y)]"
		}
	}

	enum SchematicEntry: CustomDebugStringConvertible {
		case blank
		case symbol(String)
		case num(SchematicNumber)

		var debugDescription: String {
			return switch self {
			case .blank: "."
			case .symbol(let sym): sym
			case .num(let num): "\(num)"
			}
		}
	}

	struct Schematic: CustomDebugStringConvertible {
		let boundingBox: SchematicRange
		/// Numbers are stored at multiple slots in the grid (if they're multiple digits)
		let entries: [[SchematicEntry]]

		static var digitStrings: [String] = {
			return Array(repeating: 0, count: 10).enumerated()
				.map({ (index, _) in
					return "\(index)"
				})
		}()
		static var digitStringSet: Set<String> = { Set(digitStrings) }()

		init(lines: [String]) {
			guard lines.count > 0 else { fatalError("Insufficient lines in schematic") }
			boundingBox = SchematicRange(
				x: 0 ... (lines[0].count - 1), y: 0 ... (lines.count - 1))
			var ents: [[SchematicEntry]] = []
			var lineIndex = 0
			var baseRange = SchematicRange(x: 0 ... 0, y: 0 ... 0)
			for line in lines {
				var entryLine: [SchematicEntry] = []
				var pendingNum: String? = nil
				var pendingRange: SchematicRange = baseRange

				func flushPendingNum() {
					if let pending = pendingNum {
						guard let num = Int(pending) else {
							fatalError(
								"Couldn't parse a number! \(pending)"
							)
						}
						let schematicNum = SchematicNumber(
							num: num, range: pendingRange)
						for _ in pendingRange.x {
							entryLine.append(.num(schematicNum))
						}
						pendingNum = nil
					}
				}

				var charIndex = 0
				for char in line {
					let charStr = String(char)

					switch char {
					case ".":
						flushPendingNum()
						entryLine.append(.blank)
					case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
						if let pendingNumTemp = pendingNum {
							// Continue accumulating a number
							pendingNum = pendingNumTemp + charStr
							pendingRange.x =
								pendingRange.x.lowerBound
								... (pendingRange.x.upperBound + 1)
						}
						else {
							// Start accumulating number
							pendingNum = charStr
							pendingRange.x = charIndex ... charIndex
						}
					default:
						flushPendingNum()
						entryLine.append(.symbol(charStr))
					}
					charIndex += 1
				}
				flushPendingNum()
				ents.append(entryLine)
				lineIndex += 1
				baseRange.y = lineIndex ... lineIndex
			}
			entries = ents
		}
		/// Trusts you're only passing a range inside the bounding box!
		func symbolExistsInRange(range: SchematicRange) -> Bool {
			guard range.y.upperBound - range.y.lowerBound <= 2 else {
				fatalError("Unimplemented bounding box height")
			}

			var y = 0
			// Above Row
			y = range.y.lowerBound
			for x in range.x {
				if case .symbol(_) = entries[y][x] {
					return true
				}
			}
			// Below Row
			y = range.y.upperBound
			for x in range.x {
				if case .symbol(_) = entries[y][x] {
					return true
				}
			}

			var x = 0
			// Left
			x = range.x.lowerBound
			y = min(range.y.lowerBound + 1, boundingBox.y.upperBound)
			if case .symbol(_) = entries[y][x] {
				return true
			}
			// Right
			x = range.x.upperBound
			print("Checking (\(x), \(y))")
			y = min(range.y.lowerBound + 1, boundingBox.y.upperBound)
			if case .symbol(_) = entries[y][x] {
				return true
			}
			return false
		}
		func tagPartNumbers() {
			for num in allSchematicNumbers {
				if num.isPartNumber { continue }
				let adjacentRange = num.range.adjacentRange(clampedTo: boundingBox)
				//				print("Adjacent Range for \(num) \(adjacentRange)")
				let isPartNumber = symbolExistsInRange(range: adjacentRange)
				num.isPartNumber = isPartNumber
			}
		}
		var allSchematicNumbers: [SchematicNumber] {
			var seenNumbers: Set<SchematicNumber> = Set()
			return Array(
				entries.map({ row in
					let uniquePartNumbersRow = row.compactMap({ entry in
						if case .num(let num) = entry {
							if !seenNumbers.contains(num) {
								seenNumbers.insert(num)
								return num
							}
						}
						return nil
					})
					return uniquePartNumbersRow
				})
				.joined())
		}
		var allPartNumbers: [SchematicNumber] {
			return allSchematicNumbers.filter(\.isPartNumber)
		}
		var debugDescription: String {
			let entriesStr =
				entries.map({ row in
					return row.map({ "\($0)" }).joined(separator: "")
				})
				.joined(separator: "\n")

			return "Schematic \(boundingBox):\n\(entriesStr)"
		}
	}
}
/*
 --- Part Two ---

 The engineer finds the missing part and installs it in the engine! As the engine springs to life, you jump in the closest gondola, finally ready to ascend to the water source.

 You don't seem to be going very fast, though. Maybe something is still wrong? Fortunately, the gondola has a phone labeled "help", so you pick it up and the engineer answers.

 Before you can explain the situation, she suggests that you look out the window. There stands the engineer, holding a phone in one hand and waving with the other. You're going so slowly that you haven't even left the station. You exit the gondola.

 The missing part wasn't the only issue - one of the gears in the engine is wrong. A gear is any * symbol that is adjacent to exactly two part numbers. Its gear ratio is the result of multiplying those two numbers together.

 This time, you need to find the gear ratio of every gear and add them all up so that the engineer can figure out which gear needs to be replaced.

 Consider the same engine schematic again:

 467..114..
 ...*......
 ..35..633.
 ......#...
 617*......
 .....+.58.
 ..592.....
 ......755.
 ...$.*....
 .664.598..
 In this schematic, there are two gears. The first is in the top left; it has part numbers 467 and 35, so its gear ratio is 16345. The second gear is in the lower right; its gear ratio is 451490. (The * adjacent to 617 is not a gear because it is only adjacent to one part number.) Adding up all of the gear ratios produces 467835.

 What is the sum of all of the gear ratios in your engine schematic?
 */

struct Day03Part2: AdventDayPart {
	var data: String

	static var day: Int = 3
	static var part: Int = 2

	func run() async throws {
		let lines = Array(
			data.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) })
				.filter({ !$0.isEmpty }))
		guard lines.count >= 1 else {
			fatalError("Not enough data \(lines)")
		}

		let schematic = Schematic(lines: lines)

		print(schematic)

		print("-------")
		schematic.tagPartNumbers()
		print("-------")

		let gearRatios = schematic.allGearRatios
		print("Gear Ratios: \(gearRatios)")

		let sumOfGearRatios = gearRatios.reduce(0, +)
		print("Sum: \(sumOfGearRatios)")
	}

	class SchematicNumber: Equatable, Hashable, Identifiable, CustomDebugStringConvertible {
		let id = UUID()

		let num: Int
		let range: SchematicRange

		var isPartNumber: Bool = false

		init(num: Int, range: SchematicRange) {
			self.num = num
			self.range = range
		}

		static func == (lhs: SchematicNumber, rhs: SchematicNumber) -> Bool {
			return lhs.id == rhs.id
		}
		func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}
		var debugDescription: String {
			return "\(num)\(range)"
		}
	}

	struct SchematicRange: Equatable, Hashable, CustomDebugStringConvertible {
		var x: ClosedRange<Int>
		var y: ClosedRange<Int>

		func adjacentRange(clampedTo box: SchematicRange) -> SchematicRange {
			return SchematicRange(
				x: ((x.lowerBound - 1) ... (x.upperBound + 1)).clamped(to: box.x),
				y: ((y.lowerBound - 1) ... (y.upperBound + 1)).clamped(to: box.y))
		}

		var debugDescription: String {
			return "[\(x) \(y)]"
		}
	}

	enum SchematicEntry: CustomDebugStringConvertible {
		case blank
		case symbol(String)
		case num(SchematicNumber)

		var debugDescription: String {
			return switch self {
			case .blank: "."
			case .symbol(let sym): sym
			case .num(let num): "\(num)"
			}
		}
	}

	struct Schematic: CustomDebugStringConvertible {
		let boundingBox: SchematicRange
		/// Numbers are stored at multiple slots in the grid (if they're multiple digits)
		let entries: [[SchematicEntry]]

		static var digitStrings: [String] = {
			return Array(repeating: 0, count: 10).enumerated()
				.map({ (index, _) in
					return "\(index)"
				})
		}()
		static var digitStringSet: Set<String> = { Set(digitStrings) }()

		init(lines: [String]) {
			guard lines.count > 0 else { fatalError("Insufficient lines in schematic") }
			boundingBox = SchematicRange(
				x: 0 ... (lines[0].count - 1), y: 0 ... (lines.count - 1))
			var ents: [[SchematicEntry]] = []
			var lineIndex = 0
			var baseRange = SchematicRange(x: 0 ... 0, y: 0 ... 0)
			for line in lines {
				var entryLine: [SchematicEntry] = []
				var pendingNum: String? = nil
				var pendingRange: SchematicRange = baseRange

				func flushPendingNum() {
					if let pending = pendingNum {
						guard let num = Int(pending) else {
							fatalError(
								"Couldn't parse a number! \(pending)"
							)
						}
						let schematicNum = SchematicNumber(
							num: num, range: pendingRange)
						for _ in pendingRange.x {
							entryLine.append(.num(schematicNum))
						}
						pendingNum = nil
					}
				}

				var charIndex = 0
				for char in line {
					let charStr = String(char)

					switch char {
					case ".":
						flushPendingNum()
						entryLine.append(.blank)
					case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
						if let pendingNumTemp = pendingNum {
							// Continue accumulating a number
							pendingNum = pendingNumTemp + charStr
							pendingRange.x =
								pendingRange.x.lowerBound
								... (pendingRange.x.upperBound + 1)
						}
						else {
							// Start accumulating number
							pendingNum = charStr
							pendingRange.x = charIndex ... charIndex
						}
					default:
						flushPendingNum()
						entryLine.append(.symbol(charStr))
					}
					charIndex += 1
				}
				flushPendingNum()
				ents.append(entryLine)
				lineIndex += 1
				baseRange.y = lineIndex ... lineIndex
			}
			entries = ents
		}
		/// Trusts you're only passing a range inside the bounding box!
		func symbolExistsInRange(range: SchematicRange) -> Bool {
			guard range.y.upperBound - range.y.lowerBound <= 2 else {
				fatalError("Unimplemented bounding box height")
			}

			var y = 0
			// Above Row
			y = range.y.lowerBound
			for x in range.x {
				if case .symbol(_) = entries[y][x] {
					return true
				}
			}
			// Below Row
			y = range.y.upperBound
			for x in range.x {
				if case .symbol(_) = entries[y][x] {
					return true
				}
			}

			var x = 0
			// Left
			x = range.x.lowerBound
			y = min(range.y.lowerBound + 1, boundingBox.y.upperBound)
			if case .symbol(_) = entries[y][x] {
				return true
			}
			// Right
			x = range.x.upperBound
			print("Checking (\(x), \(y))")
			y = min(range.y.lowerBound + 1, boundingBox.y.upperBound)
			if case .symbol(_) = entries[y][x] {
				return true
			}
			return false
		}
		func tagPartNumbers() {
			for num in allSchematicNumbers {
				if num.isPartNumber { continue }
				let adjacentRange = num.range.adjacentRange(clampedTo: boundingBox)
				//				print("Adjacent Range for \(num) \(adjacentRange)")
				let isPartNumber = symbolExistsInRange(range: adjacentRange)
				num.isPartNumber = isPartNumber
			}
		}
		var allSchematicNumbers: [SchematicNumber] {
			var seenNumbers: Set<SchematicNumber> = Set()
			return Array(
				entries.map({ row in
					let uniquePartNumbersRow = row.compactMap({ entry in
						if case .num(let num) = entry {
							if !seenNumbers.contains(num) {
								seenNumbers.insert(num)
								return num
							}
						}
						return nil
					})
					return uniquePartNumbersRow
				})
				.joined())
		}
		var allPartNumbers: [SchematicNumber] {
			return allSchematicNumbers.filter(\.isPartNumber)
		}

		/// Assumes the partNumbers have been tagged already!
		var allGearRatios: [Int] {
			var results: [Int] = []
			var rowIndex = 0
			for row in entries {
				var colIndex = 0

				for entry in row {
					if case .symbol(let sym) = entry, sym == "*" {
						// If the entry we're inspecting is potentially a gear
						let coord = SchematicRange(
							x: colIndex ... colIndex,
							y: rowIndex ... rowIndex)

						// Scan the adjacent locations for parts
						let partLocations = coord.adjacentRange(clampedTo: boundingBox)

						var foundParts: Set<SchematicNumber> = Set()
						for y in partLocations.y {
							for x in partLocations.x {
								if case .num(let num) = entries[y][x], num.isPartNumber
								{
									foundParts.insert(num)
								}
							}
						}
						if foundParts.count == 2 {
							let twoPartsArray = Array(foundParts)
							let ratio = twoPartsArray[0].num * twoPartsArray[1].num
							print("Found a gear! (\(rowIndex), \(colIndex)) r: \(ratio)")
							results.append(ratio)
						}
					}
					colIndex += 1
				}
				rowIndex += 1
			}
			return results
		}
		var debugDescription: String {
			let entriesStr =
				entries.map({ row in
					return row.map({ "\($0)" }).joined(separator: "")
				})
				.joined(separator: "\n")

			return "Schematic \(boundingBox):\n\(entriesStr)"
		}
	}
}
