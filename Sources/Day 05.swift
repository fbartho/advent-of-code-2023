import Foundation

/*
 --- Day 5: If You Give A Seed A Fertilizer ---

 You take the boat and find the gardener right where you were told he would be: managing a giant "garden" that looks more to you like a farm.

 "A water source? Island Island is the water source!" You point out that Snow Island isn't receiving any water.

 "Oh, we had to stop the water because we ran out of sand to filter it with! Can't make snow with dirty water. Don't worry, I'm sure we'll get more sand soon; we only turned off the water a few days... weeks... oh no." His face sinks into a look of horrified realization.

 "I've been so busy making sure everyone here has food that I completely forgot to check why we stopped getting more sand! There's a ferry leaving soon that is headed over in that direction - it's much faster than your boat. Could you please go check it out?"

 You barely have time to agree to this request when he brings up another. "While you wait for the ferry, maybe you can help us with our food production problem. The latest Island Island Almanac just arrived and we're having trouble making sense of it."

 The almanac (your puzzle input) lists all of the seeds that need to be planted. It also lists what type of soil to use with each kind of seed, what type of fertilizer to use with each kind of soil, what type of water to use with each kind of fertilizer, and so on. Every type of seed, soil, fertilizer and so on is identified with a number, but numbers are reused by each category - that is, soil 123 and fertilizer 123 aren't necessarily related to each other.

 For example:

 seeds: 79 14 55 13

 seed-to-soil map:
 50 98 2
 52 50 48

 soil-to-fertilizer map:
 0 15 37
 37 52 2
 39 0 15

 fertilizer-to-water map:
 49 53 8
 0 11 42
 42 0 7
 57 7 4

 water-to-light map:
 88 18 7
 18 25 70

 light-to-temperature map:
 45 77 23
 81 45 19
 68 64 13

 temperature-to-humidity map:
 0 69 1
 1 0 69

 humidity-to-location map:
 60 56 37
 56 93 4
 The almanac starts by listing which seeds need to be planted: seeds 79, 14, 55, and 13.

 The rest of the almanac contains a list of maps which describe how to convert numbers from a source category into numbers in a destination category. That is, the section that starts with seed-to-soil map: describes how to convert a seed number (the source) to a soil number (the destination). This lets the gardener and his team know which soil to use with which seeds, which water to use with which fertilizer, and so on.

 Rather than list every source number and its corresponding destination number one by one, the maps describe entire ranges of numbers that can be converted. Each line within a map contains three numbers: the destination range start, the source range start, and the range length.

 Consider again the example seed-to-soil map:

 50 98 2
 52 50 48
 The first line has a destination range start of 50, a source range start of 98, and a range length of 2. This line means that the source range starts at 98 and contains two values: 98 and 99. The destination range is the same length, but it starts at 50, so its two values are 50 and 51. With this information, you know that seed number 98 corresponds to soil number 50 and that seed number 99 corresponds to soil number 51.

 The second line means that the source range starts at 50 and contains 48 values: 50, 51, ..., 96, 97. This corresponds to a destination range starting at 52 and also containing 48 values: 52, 53, ..., 98, 99. So, seed number 53 corresponds to soil number 55.

 Any source numbers that aren't mapped correspond to the same destination number. So, seed number 10 corresponds to soil number 10.

 So, the entire list of seed numbers and their corresponding soil numbers looks like this:

 seed  soil
 0     0
 1     1
 ...   ...
 48    48
 49    49
 50    52
 51    53
 ...   ...
 96    98
 97    99
 98    50
 99    51
 With this map, you can look up the soil number required for each initial seed number:

 - Seed number 79 corresponds to soil number 81.
 - Seed number 14 corresponds to soil number 14.
 - Seed number 55 corresponds to soil number 57.
 - Seed number 13 corresponds to soil number 13.
 The gardener and his team want to get started as soon as possible, so they'd like to know the closest location that needs a seed. Using these maps, find the lowest location number that corresponds to any of the initial seeds. To do this, you'll need to convert each seed number through other categories until you can find its corresponding location number. In this example, the corresponding types are:

 - Seed 79, soil 81, fertilizer 81, water 81, light 74, temperature 78, humidity 78, location 82.
 - Seed 14, soil 14, fertilizer 53, water 49, light 42, temperature 42, humidity 43, location 43.
 - Seed 55, soil 57, fertilizer 57, water 53, light 46, temperature 82, humidity 82, location 86.
 - Seed 13, soil 13, fertilizer 52, water 41, light 34, temperature 34, humidity 35, location 35.
 So, the lowest location number in this example is 35.

 What is the lowest location number that corresponds to any of the initial seed numbers?
 */
struct Day05Part1: AdventDayPart {
	var data: String

	static var day: Int = 05
	static var part: Int = 1

	func run() async throws {
		let almanac = Almanac(data)
		print("Almanac:\n\(almanac)")
		print("-----")
		let seedToLocations = almanac.seedToLocations
		print("seed-to-location map: \(seedToLocations)")
		print("-----")
		let loc = seedToLocations.values.min()
		print("Min seed location: \(loc ?? -1)")
	}

	struct Almanac: CustomDebugStringConvertible {
		let seeds: [Int]
		/// Keyed by 'source'
		let mappings: [String: Map]

		init(_ str: String) {
			let firstBits = str.splitAndTrim(separator: "\n", maxSplits: 1)
			guard firstBits.count == 2 else {
				fatalError("Invalid Almanac Definition: expected seeds and mappings\n\(str)")
			}
			guard firstBits[0].hasPrefix("seeds: ") else {
				fatalError("Invalid Almanac Definition: first line should start with 'seeds:'\n\(str)")
			}
			let seedNums = firstBits[0].trimmingPrefix("seeds:")

			seeds = parse(from: seedNums, separator: " ")

			let mapChunks: [Map] = parse(from: firstBits[1], separator: "\n\n")
			mappings = mapChunks.reduce(into: [:], { $0[$1.from] = $1 })
		}

		/// Start Point
		private static let startMapKey = "seed"
		/// Terminus Mapping
		private static let locationMapKey = "location"

		public func lookupLocation(for seed: Int) -> Int {
			return continueLookup(for: seed, source: Self.startMapKey, finalNumType: Self.locationMapKey)
		}
		private func continueLookup(for currentNum: Int, source: String, finalNumType: String) -> Int {
			guard let map = mappings[source] else {
				fatalError("No mapping for source: '\(source)'")
			}
			let (numType, num) = map.lookup(num: currentNum)
			if numType == finalNumType {
				return num
			}
			return continueLookup(for: num, source: numType, finalNumType: finalNumType)
		}
		var seedToLocations: [Int: Int] {
			return seeds.reduce(into: [:], { $0[$1] = lookupLocation(for: $1) })
		}

		var debugDescription: String {
			let mapsStr = mappings.values.map({ "\($0)" }).joined(separator: "\n\n")
			return "seeds: \(seeds.map({"\($0)"}).joined(separator: " "))\n\n\(mapsStr)"
		}

		struct Map: CustomDebugStringConvertible, HasInitFromString {
			let from: String
			let to: String

			let entries: [Entry]

			init(_ str: String) {
				let lines = str.splitAndTrim(separator: "\n")
				guard lines.count >= 1 else {
					fatalError("Invalid map, needs a source-to-destination label. \(str)")
				}
				// First line: looks like 'foo-to-bar map:'
				guard lines[0].hasSuffix(" map:") else {
					fatalError(
						"Invalid map, needs a source-to-destination label, was not properly terminated. \(str)"
					)
				}
				let mappingHeaderBits = lines[0].splitAndTrim(separator: " ")
				guard mappingHeaderBits.count == 2 else {
					fatalError(
						"Invalid map, needs a source-to-destination label, wrong number of components. \(str)"
					)
				}
				let fromTo = mappingHeaderBits[0].split(separator: "-to-")
				guard fromTo.count == 2 else {
					fatalError(
						"Invalid map, needs a source-to-destination label, no '-to-' found. \(str)"
					)
				}
				from = String(fromTo[0])
				to = String(fromTo[1])

				let remaining = lines.dropFirst()
				entries = remaining.map(Entry.init)
			}

			func lookup(num: Int) -> (numType: String, num: Int) {
				guard
					case .success(let destCoord) = entries.lazy.map({ $0.lookup(source: num) })
						.first(where: { lookupResult in
							guard case .success(_) = lookupResult else {
								return false
							}
							return true
						})
				else {
					// Any source numbers that aren't mapped correspond to the same destination number.
					return (numType: to, num: num)
				}
				return (numType: to, num: destCoord)
			}

			var debugDescription: String {
				let entriesStr = entries.map({ "\($0)" }).joined(separator: "\n")
				return "\(from)-to-\(to) map:\n\(entriesStr)"
			}
			enum MappingError: Error {
				case notFound
			}
			struct Entry: CustomDebugStringConvertible, HasInitFromString {
				let destination: ClosedRange<Int>
				let source: ClosedRange<Int>
				let length: Int

				init(_ line: String) {
					let bits: [Int] = parse(from: line, separator: " ")
					guard bits.count == 3 else {
						fatalError(
							"Invalid Map.Entry description, expected 3 Integer components: \(line)"
						)
					}
					length = bits[2]
					destination = bits[0] ... bits[0] + length - 1
					source = bits[1] ... bits[1] + length - 1
				}
				func lookup(source search: Int) -> Result<Int, MappingError> {
					guard source.contains(search) else {
						return .failure(.notFound)
					}
					return .success(search - source.lowerBound + destination.lowerBound)
				}
				var debugDescription: String {
					return
						"\(destination.lowerBound) \(source.lowerBound) \(length) [d: \(destination) s: \(source)]"
				}
			}
		}
	}
}

/*
 --- Part Two ---

 Everyone will starve if you only plant such a small number of seeds. Re-reading the almanac, it looks like the seeds: line actually describes ranges of seed numbers.

 The values on the initial seeds: line come in pairs. Within each pair, the first value is the start of the range and the second value is the length of the range. So, in the first line of the example above:

 seeds: 79 14 55 13
 This line describes two ranges of seed numbers to be planted in the garden. The first range starts with seed number 79 and contains 14 values: 79, 80, ..., 91, 92. The second range starts with seed number 55 and contains 13 values: 55, 56, ..., 66, 67.

 Now, rather than considering four seed numbers, you need to consider a total of 27 seed numbers.

 In the above example, the lowest location number can be obtained from seed number 82, which corresponds to soil 84, fertilizer 84, water 84, light 77, temperature 45, humidity 46, and location 46. So, the lowest location number is 46.

 Consider all of the initial seed numbers listed in the ranges on the first line of the almanac. What is the lowest location number that corresponds to any of the initial seed numbers?
 */
struct Day05Part2: AdventDayPart {
	var data: String

	static var day: Int = 5
	static var part: Int = 2

	func run() async throws {
		let almanac = Almanac(data)
		print("Almanac:\n\(almanac)")
		print("-----")
		/// Single-threaded Range-based approach
		///  Instead of iterating over the components, we try to thread a whole range through
		///    This sometimes causes the need to split a range so it can be fullfilled by two different map entries.
		let loc = almanac.lowestSeedLocation()
		// Expected Test Result: 46
		// Expected Prod Result: 99751240

		// Time to beat:    (multi-threaded) 4603.94931525 seconds
		// Final approach: (single-threaded)    0.01363404 seconds
		print("Min seed location: \(loc)")
	}

	final class Almanac: CustomDebugStringConvertible {
		/// Ranges describing a bunch of sequential seeds
		let seeds: [ClosedRange<Int>]
		/// Keyed by 'source'
		let mappings: [String: Map]

		init(_ str: String) {
			let firstBits = str.splitAndTrim(separator: "\n", maxSplits: 1)
			guard firstBits.count == 2 else {
				fatalError("Invalid Almanac Definition: expected seeds and mappings\n\(str)")
			}
			guard firstBits[0].hasPrefix("seeds: ") else {
				fatalError("Invalid Almanac Definition: first line should start with 'seeds:'\n\(str)")
			}
			let seedNums = firstBits[0].trimmingPrefix("seeds:")
			let seedRangeBits: [Int] = parse(from: seedNums, separator: " ")
			guard seedRangeBits.count % 2 == 0 else {
				fatalError(
					"Invalid Almanac Definition: expected even number elements to form ranges 'seeds:'\n\(str)"
				)
			}

			// 'seeds' now contains seed-ranges!
			seeds = stride(from: 0, to: seedRangeBits.count, by: 2)
				.reduce(
					into: [],
					{ result, i in
						let start = seedRangeBits[i]
						let length = seedRangeBits[i + 1]
						result.append(start ... (start + length - 1))
					})

			let mapChunks: [Map] = parse(from: firstBits[1], separator: "\n\n")
			mappings = mapChunks.reduce(into: [:], { $0[$1.from] = $1 })
		}

		/// Start Point
		private static let startMapKey = "seed"
		/// Terminus Mapping
		private static let locationMapKey = "location"

		public func lookupLocations(for ranges: [ClosedRange<Int>]) -> [ClosedRange<Int>] {
			return continueLookup(for: ranges, source: Self.startMapKey, finalNumType: Self.locationMapKey)
		}
		private func continueLookup(for initialRanges: [ClosedRange<Int>], source: String, finalNumType: String)
			-> [ClosedRange<Int>]
		{
			guard let map = mappings[source] else {
				fatalError("No mapping for source: '\(source)'")
			}
			let nextSource = map.to
			let nextRanges = Array(initialRanges.map({ map.lookup(range: $0) }).joined())
			// print("from: \(source) ranges: \(initialRanges.map(\.alternateDescription)) to: \(nextSource) nextRanges: \(nextRanges.map(\.alternateDescription))")

			if nextSource == finalNumType {
				return nextRanges
			}
			return continueLookup(for: nextRanges, source: nextSource, finalNumType: finalNumType)
		}

		/// Single-threaded Range-based approach
		///  Instead of iterating over the components, we try to thread a whole range through
		///    This sometimes causes the need to split a range so it can be fullfilled by two different map entries.
		func lowestSeedLocation() -> Int {
			let locations = lookupLocations(for: seeds)
			guard locations.count > 0 else {
				fatalError("No locations found")
			}
			// debugPrint(seeds.map(\.alternateDescription)," becomes ", locations.map({$0.alternateDescription}))
			let lowestLocation = locations.map({ $0.lowerBound }).min()!
			return lowestLocation
		}

		var debugDescription: String {
			let mapsStr = mappings.values.map({ "\($0)" }).joined(separator: "\n\n")
			return "seeds: \(seeds.map({"\($0)"}).joined(separator: " "))\n\n\(mapsStr)"
		}

		final class Map: CustomDebugStringConvertible, HasInitFromString {
			let from: String
			let to: String

			let entries: [Entry]

			init(_ str: String) {
				let lines = str.splitAndTrim(separator: "\n")
				guard lines.count >= 1 else {
					fatalError("Invalid map, needs a source-to-destination label. \(str)")
				}
				// First line: looks like 'foo-to-bar map:'
				guard lines[0].hasSuffix(" map:") else {
					fatalError(
						"Invalid map, needs a source-to-destination label, was not properly terminated. \(str)"
					)
				}
				let mappingHeaderBits = lines[0].splitAndTrim(separator: " ")
				guard mappingHeaderBits.count == 2 else {
					fatalError(
						"Invalid map, needs a source-to-destination label, wrong number of components. \(str)"
					)
				}
				let fromTo = mappingHeaderBits[0].split(separator: "-to-")
				guard fromTo.count == 2 else {
					fatalError(
						"Invalid map, needs a source-to-destination label, no '-to-' found. \(str)"
					)
				}
				from = String(fromTo[0])
				to = String(fromTo[1])

				let remaining = lines.dropFirst()
				entries = remaining.map(Entry.init)
			}

			func lookup(range firstRange: ClosedRange<Int>) -> [ClosedRange<Int>] {
				var ranges: [ClosedRange<Int>] = []
				var unprocessed = [firstRange]

				unprocessedLoop: while unprocessed.count > 0 {
					let range = unprocessed.removeLast()
					entryLoop: for entry in entries {
						let eResult = entry.lookup(range: range)
						switch eResult {
						case .notFound:
							// Continue iterating entries
							continue entryLoop
						case .perfect(let finalRange):
							ranges.append(finalRange)
							continue unprocessedLoop
						case .partial(let tuple):
							ranges.append(tuple.processed)
							unprocessed.append(contentsOf: tuple.remainder.reversed())
							continue unprocessedLoop
						}
					}
					// if there are no matched entries, then you pass the range through unmodified
					ranges.append(range)
				}
				// debugPrint("from: \(from) to: \(to) range \(firstRange) mapped to: ", ranges)
				return ranges
			}

			var debugDescription: String {
				let entriesStr = entries.map({ "\($0)" }).joined(separator: "\n")
				return "\(from)-to-\(to) map:\n\(entriesStr)"
			}

			enum RangeLookupResult {
				case notFound
				/// Perfectly within
				case perfect(ClosedRange<Int>)
				/// A partial match, this range produces new ranges that need to be processed in a different entry
				case partial((processed: ClosedRange<Int>, remainder: [ClosedRange<Int>]))
			}
			struct Entry: CustomDebugStringConvertible, HasInitFromString {
				let destination: ClosedRange<Int>
				let source: ClosedRange<Int>
				let length: Int

				init(_ line: String) {
					let bits: [Int] = parse(from: line, separator: " ")
					guard bits.count == 3 else {
						fatalError(
							"Invalid Map.Entry description, expected 3 Integer components: \(line)"
						)
					}
					length = bits[2]
					destination = bits[0] ... bits[0] + length - 1
					source = bits[1] ... bits[1] + length - 1
				}
				func lookup(range: ClosedRange<Int>) -> RangeLookupResult {
					if !source.overlaps(range) {
						return .notFound
					}
					if source.lowerBound <= range.lowerBound
						&& source.upperBound >= range.upperBound
					{
						// Target range is fully within source, transform our range
						let startOffset = range.lowerBound - source.lowerBound
						let newLower = destination.lowerBound + startOffset
						let newUpper = newLower + range.count - 1
						return .perfect(newLower ... newUpper)
					}

					var remainder: [ClosedRange<Int>] = []
					let outputRange: ClosedRange<Int>

					let rangeExistsBelow = source.lowerBound > range.lowerBound
					let rangeExistsAbove = range.upperBound > source.upperBound

					var unprocessedItems = range.count

					if rangeExistsBelow {
						// continue processing the part of the range that is below this source-range
						let remainingRange = range.lowerBound ... (source.lowerBound - 1)

						unprocessedItems -= remainingRange.count

						remainder.append(remainingRange)
					}
					if rangeExistsAbove {
						// continue processing the part of the range that is above this source-range
						let remainingRange = (source.upperBound + 1) ... range.upperBound

						unprocessedItems -= remainingRange.count

						remainder.append(remainingRange)
					}

					if rangeExistsAbove && rangeExistsBelow {
						// Range covers the source
						outputRange = destination
					} else {
						let matchedStart = max(source.lowerBound, range.lowerBound)
						let matchedEnd = min(source.upperBound, range.upperBound)

						let startOffset = matchedStart - source.lowerBound
						let span = matchedEnd - matchedStart

						let finalStart = destination.lowerBound + startOffset
						outputRange = (finalStart) ... (finalStart + span)
					}

					guard unprocessedItems - outputRange.count == 0 else {
						fatalError(
							"Lost some items \(range.alternateDescription) \(source.alternateDescription) \(destination.alternateDescription) \(outputRange.alternateDescription) \(remainder.map(\.alternateDescription))"
						)
					}

					return .partial((processed: outputRange, remainder: remainder))
				}

				var debugDescription: String {
					return
						"\(destination.lowerBound) \(source.lowerBound) \(length) [d: \(destination) s: \(source)]"
				}
			}
		}
	}
}
