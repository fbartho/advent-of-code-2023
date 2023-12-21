import Foundation

/*
 --- Day 12: Hot Springs ---

 You finally reach the hot springs! You can see steam rising from secluded areas attached to the primary, ornate building.

 As you turn to enter, the researcher stops you. "Wait - I thought you were looking for the hot springs, weren't you?" You indicate that this definitely looks like hot springs to you.

 "Oh, sorry, common mistake! This is actually the onsen! The hot springs are next door."

 You look in the direction the researcher is pointing and suddenly notice the massive metal helixes towering overhead. "This way!"

 It only takes you a few more steps to reach the main gate of the massive fenced-off area containing the springs. You go through the gate and into a small administrative building.

 "Hello! What brings you to the hot springs today? Sorry they're not very hot right now; we're having a lava shortage at the moment." You ask about the missing machine parts for Desert Island.

 "Oh, all of Gear Island is currently offline! Nothing is being manufactured at the moment, not until we get more lava to heat our forges. And our springs. The springs aren't very springy unless they're hot!"

 "Say, could you go up and see why the lava stopped flowing? The springs are too cold for normal operation, but we should be able to find one springy enough to launch you up there!"

 There's just one problem - many of the springs have fallen into disrepair, so they're not actually sure which springs would even be safe to use! Worse yet, their condition records of which springs are damaged (your puzzle input) are also damaged! You'll need to help them repair the damaged records.

 In the giant field just outside, the springs are arranged into rows. For each row, the condition records show every spring and whether it is operational (.) or damaged (#). This is the part of the condition records that is itself damaged; for some springs, it is simply unknown (?) whether the spring is operational or damaged.

 However, the engineer that produced the condition records also duplicated some of this information in a different format! After the list of springs for a given row, the size of each contiguous group of damaged springs is listed in the order those groups appear in the row. This list always accounts for every damaged spring, and each number is the entire size of its contiguous group (that is, groups are always separated by at least one operational spring: #### would always be 4, never 2,2).

 So, condition records with no unknown spring conditions might look like this:

 #.#.### 1,1,3
 .#...#....###. 1,1,3
 .#.###.#.###### 1,3,1,6
 ####.#...#... 4,1,1
 #....######..#####. 1,6,5
 .###.##....# 3,2,1
 However, the condition records are partially damaged; some of the springs' conditions are actually unknown (?). For example:

 ???.### 1,1,3
 .??..??...?##. 1,1,3
 ?#?#?#?#?#?#?#? 1,3,1,6
 ????.#...#... 4,1,1
 ????.######..#####. 1,6,5
 ?###???????? 3,2,1
 Equipped with this information, it is your job to figure out how many different arrangements of operational and broken springs fit the given criteria in each row.

 In the first line (???.### 1,1,3), there is exactly one way separate groups of one, one, and three broken springs (in that order) can appear in that row: the first three unknown springs must be broken, then operational, then broken (#.#), making the whole row #.#.###.

 The second line is more interesting: .??..??...?##. 1,1,3 could be a total of four different arrangements. The last ? must always be broken (to satisfy the final contiguous group of three broken springs), and each ?? must hide exactly one of the two broken springs. (Neither ?? could be both broken springs or they would form a single contiguous group of two; if that were true, the numbers afterward would have been 2,3 instead.) Since each ?? can either be #. or .#, there are four possible arrangements of springs.

 The last line is actually consistent with ten different arrangements! Because the first number is 3, the first and second ? must both be . (if either were #, the first number would have to be 4 or higher). However, the remaining run of unknown spring conditions have many different ways they could hold groups of two and one broken springs:

 ?###???????? 3,2,1
 .###.##.#...
 .###.##..#..
 .###.##...#.
 .###.##....#
 .###..##.#..
 .###..##..#.
 .###..##...#
 .###...##.#.
 .###...##..#
 .###....##.#
 In this example, the number of possible arrangements for each row is:

 ???.### 1,1,3 - 1 arrangement
 .??..??...?##. 1,1,3 - 4 arrangements
 ?#?#?#?#?#?#?#? 1,3,1,6 - 1 arrangement
 ????.#...#... 4,1,1 - 1 arrangement
 ????.######..#####. 1,6,5 - 4 arrangements
 ?###???????? 3,2,1 - 10 arrangements
 Adding all of the possible arrangement counts together produces a total of 21 arrangements.

 For each row, count all of the different arrangements of operational and broken springs that meet the given criteria. What is the sum of those counts?
 */
struct Day12Part1: AdventDayPart, TestData {
	var data: String

	static var day: Int = 12
	static var part: Int = 1

	func run() async throws {
		let records: [SpringConditionRecord] = parse(from: data, separator: "\n")
		//		let arrangements = records.map(\.possibleArrangements)
		let tmp = [records.first!]
		var cache: [SpringConditionRecord.BucketAssignmentCacheKey: Int] = [:]
		let arrangements = tmp.map({$0.possibleArrangements(cache: &cache)})

		print(arrangements.map(String.init(describing:)).joined(separator: "\n"))
		print("---------")
		let sum = arrangements.reduce(0, +)
		print("Sum: \(sum)")
	}

	struct SpringConditionRecord: HasInitFromString, Hashable {
		let initialState: [SpringStatus]
		/// a series of lengths of runs of broken items
		let brokenRunLengths: [Int]

		init(_ str: String) {
			let bits = str.splitAndTrim(separator: " ")
			guard bits.count == 2 else {
				fatalError("ValidationError: Condition Description invalid \(str)")
			}
			initialState = parse(from: bits[0], separator: "")
			brokenRunLengths = parse(from: bits[1], separator: "")
		}
		init(_ initialState: [SpringStatus], _ brokenRunLengths: [Int]) {
			self.initialState = initialState
			self.brokenRunLengths = brokenRunLengths
		}
		var possibleArrangements: Int {
			var cache: [BucketAssignmentCacheKey: Int] = [:]
			return possibleArrangements(cache: &cache)
		}
		func possibleArrangements(cache: inout [BucketAssignmentCacheKey: Int]) -> Int {
			var canStart = false
			let buckets: [[SpringStatus]] = initialState.trimmingPrefix(while: {$0 == .working}).reduce(into: [[]], {stateGroups, entry in
				switch entry {
				case .unknown, .broken:
					stateGroups[stateGroups.count-1].append(entry)
					canStart = true
				case .working:
					if canStart {
						stateGroups.append([])
						canStart = false
					}
				}
			}).filter({$0.count > 0})
			let result = Self.countArrangements(cache: &cache,
												buckets: buckets,
												brokenRunLengths: brokenRunLengths,
												brokenRunHasStarted: false
			)
			return result
		}

		static func countArrangements(cache: inout [BucketAssignmentCacheKey: Int],
									  buckets: [[SpringStatus]],
									  brokenRunLengths: [Int],
									  brokenRunHasStarted: Bool) -> Int {

			let cacheKey = BucketAssignmentCacheKey(buckets: buckets,
													brokenRunLengths: brokenRunLengths,
													brokenRunStarted: brokenRunHasStarted)
			if let cached = cache[cacheKey] {
				print("cache: \(cacheKey)")
				return cached
			}
			print("calc:  \(cacheKey)")

			var result: Int = 0

			guard !buckets.isEmpty else {
				if brokenRunLengths.isEmpty {
					result += 1
				} else {
					result = 0
				}
				cache[cacheKey] = result
				return result
			}
			guard !brokenRunLengths.isEmpty else {
				if buckets.contains(where: {$0.contains(.broken)}) {
					// If there's a broken predicted, but we processed all the broken run lengths
					// then this is not a valid prediction.
					result = 0
				} else {
					result += 1
				}
				cache[cacheKey] = result
				return result
			}


			let currentRun = buckets.first!
			let desiredRunLength = brokenRunLengths.first!
			let numExpectedBuckets = brokenRunLengths.count

			//			let minNeededSpace = buckets.map(\.count).reduce(0, +) + buckets.count - 1
			//			let checksumExpectedSpace = brokenRunLengths.reduce(0, +) + numExpectedBuckets - 1
			//			if minNeededSpace > checksumExpectedMinimumSpace {
			//				// not enough space remains
			//				result = 0
			//				cache[cacheKey] = result
			//				return result
			//			}

			let allBroken = !currentRun.isEmpty && currentRun.allSatisfy({$0 == .broken})
			if allBroken {
				if currentRun.count != desiredRunLength {
					// Invalid number of broken items
					result = 0
					cache[cacheKey] = result
					return result
				} else {
					let newBuckets = Array(buckets.dropFirst())
					let newBrokenRuns = Array(brokenRunLengths.dropFirst())
					if newBuckets.isEmpty && newBrokenRuns.isEmpty {
						result = 1
						cache[cacheKey] = result
						return result
					} else {
						result += countArrangements(cache: &cache,
													buckets: newBuckets,
													brokenRunLengths: newBrokenRuns,
													brokenRunHasStarted: false)
						cache[cacheKey] = result
						return result
					}
				}
			}

			switch currentRun.first! {
			case .working:
				if brokenRunHasStarted && desiredRunLength != 0 {
					// Uh oh, expected more broken ones
					result = 0
					cache[cacheKey] = result
					return result
				}
				// Skip over working gears by treating them as a separator before this bucket
				let newRun = Array(currentRun.dropFirst())
				if newRun.isEmpty {
					let newBuckets = Array(buckets.dropFirst())
					if newBuckets.isEmpty {
						if brokenRunLengths.isEmpty {
							// Nothing left to process! valid arrangement
							result += 1
						} else {
							// Uh oh, expected more broken ones
							result = 0
							cache[cacheKey] = result
							return result
						}
					} else {
						result += countArrangements(cache: &cache,
													buckets: newBuckets,
													brokenRunLengths: brokenRunLengths,
													brokenRunHasStarted: brokenRunHasStarted)
					}
				} else {
					result += countArrangements(cache: &cache,
												buckets: buckets.swapping(newRun, at: 0),
												brokenRunLengths: brokenRunLengths,
												brokenRunHasStarted: brokenRunHasStarted)
				}
			case .broken:
				let newRun = Array(currentRun.dropFirst())
				// subtract 1 from our broken run length, and slice forwards
				let newRunLength = desiredRunLength - 1
				if newRun.isEmpty {
					let newBuckets = Array(buckets.dropFirst())
					if newRunLength == 0 {
						// Drop both
						let newBroken = Array(brokenRunLengths.dropFirst())
						if newBroken.isEmpty {
							if newBuckets.isEmpty {
								// Nothing more to process! Valid arrangement
								result += 1
							} else {
								// Invalid arrangement
								result = 0
								cache[cacheKey] = result
								return result
							}
						}
					} else {
						// Invalid arrangement, newRunLength == 0, but newRun is not empty
						result = 0
						cache[cacheKey] = result
						return result
					}
				} else {
					let newBuckets = buckets.swapping(newRun, at: 0)
					if newRunLength == 0 {
						let newBroken = Array(brokenRunLengths.dropFirst())
						result += countArrangements(cache: &cache,
													buckets: newBuckets,
													brokenRunLengths: newBroken,
													brokenRunHasStarted: false)

					} else {
						let newBroken = brokenRunLengths.swapping(newRunLength, at: 0)
						result += countArrangements(cache: &cache,
													buckets: newBuckets,
													brokenRunLengths: newBroken,
													brokenRunHasStarted: true)
					}
				}

			case .unknown:
				// Case 1: Place a broken gear
				let runWithBroken = currentRun.swapping(.broken, at: 0)
				result += countArrangements(cache: &cache,
											buckets: buckets.swapping(runWithBroken, at: 0),
											brokenRunLengths: brokenRunLengths,
											brokenRunHasStarted: brokenRunHasStarted)
				// Case 2: Place a working gear
				let runWithWorking = currentRun.swapping(.working, at: 0)
				result += countArrangements(cache: &cache,
											buckets: buckets.swapping(runWithWorking, at: 0),
											brokenRunLengths: brokenRunLengths, 
											brokenRunHasStarted: brokenRunHasStarted)
			}


			//			var result: Int = 0
			//
			//			let run = buckets.first!
			//			let desiredRunLength = brokenRunLengths.first!
			//			let currentRunLength = run.count
			//
			//			if desiredRunLength > currentRunLength && run.contains(.broken) {
			//				// We need to split this sub-run, so skip executing
			//				return 0
			//			}
			//			// Iterate through the cluster splitting it into subclusters if needed
			//			for i in 0..<run.count {
			//				let leftChunk = run[0...i]
			//				// Check if we already have a broken gear
			//				if leftChunk.contains(.broken) {
			//					// advance until all the broken gears are on the left
			//					continue
			//				}
			//				let rightChunk: [SpringStatus]
			//				if i + desiredRunLength <= currentRunLength {
			//					rightChunk = Array(run[(i + desiredRunLength)...])
			//				} else {
			//					rightChunk = []
			//				}
			//
			//				if let rightFirst = rightChunk.first, rightFirst == .broken {
			//					// advance until all the broken gears are on the left
			//					continue
			//				}
			//				if rightChunk.count > 1 {
			//					// If we have at least 2 things, then we recurse
			//					var newBuckets = Array(buckets[1...])
			//					newBuckets.insert(Array(rightChunk[1...]), at: 0)
			//					let newRunLengths = Array(brokenRunLengths[1...])
			//					result += countArrangements(cache: &cache, buckets: newBuckets, brokenRunLengths: newRunLengths)
			//				}
			//			}
			//			if !run.contains(.broken) {
			//				// Recurse to count remaining runs
			//				let newRunLengths = Array(brokenRunLengths[1...])
			//				result += countArrangements(cache: &cache, buckets: Array(buckets[1...]), brokenRunLengths: newRunLengths)
			//			}


			//			let currentSubrunExpectedLength = brokenRunLengths.first!
			//
			//			let searchNum = brokenRunLengths.first!
			//			if hasNBrokenOrUnknownFollowedByWorkingOrUnknown(state: s, n: searchNum) {
			//				if brokenRunLengths.count == 1 {
			//					// Perfect match for the search num, so we're done here
			//					result += 1
			//				} else {
			//					let hasEnoughFuturePotentialUnknowns = s.count > currentSubrunExpectedLength + 1
			//					if hasEnoughFuturePotentialUnknowns {
			//						// Next sub-run!
			//						result += countArrangements(cache: &cache,
			//													state: Array(s[currentSubrunExpectedLength...]),
			//													brokenRunLengths: Array(brokenRunLengths[1...]))
			//					}
			//				}
			//			}
			//			let minimumBrokenSprings = brokenRunLengths.reduce(0, +)
			//			let nextSpringIsUnknown = s.first! == .unknown
			//			let springRunNeedsFurtherUnknownProcessing = s.count > minimumBrokenSprings - 1
			//			if springRunNeedsFurtherUnknownProcessing && nextSpringIsUnknown {
			//				// Recurse to capture the subtree
			//				result += countArrangements(cache: &cache, state: Array(s[1...]), brokenRunLengths: brokenRunLengths)
			//			}

			cache[cacheKey] = result
			print("Result \(result) for \(cacheKey)")
			return result
		}
		static func hasNBrokenOrUnknownFollowedByWorkingOrUnknown(state: [SpringStatus], n: Int) -> Bool {
			var remaining = n
			for entry in state {
				let isWorkingOrUnknown: Bool
				let isBrokenOrUnknown: Bool
				switch entry {
				case .working:
					isWorkingOrUnknown = true
					isBrokenOrUnknown = false
				case .unknown:
					isWorkingOrUnknown = true
					isBrokenOrUnknown = true
				case .broken:
					isWorkingOrUnknown = false
					isBrokenOrUnknown = true
				}

				if remaining == 0 {
					if isWorkingOrUnknown {
						return true
					} else {
						return false
					}
				} else {
					if isBrokenOrUnknown {
						remaining -= 1
						continue
					} else {
						// Abort: Found a working gear with 'remaining' broken gears, but were told there would be 'n'
						return false
					}
				}
			}
			// We processed all the entries, if the last one subtracted from remaining, then we're good
			return remaining == 0
		}

		enum SpringStatus: Character, HasFailableInitFromString, Hashable, CustomDebugStringConvertible {
			case unknown = "?"
			case working = "."
			case broken = "#"
			init?(_ str: String){
				self.init(rawValue: str.first!)
			}
			var debugDescription: String {
				return "\(rawValue)"
			}
		}
		struct BucketAssignmentCacheKey: Hashable, CustomDebugStringConvertible {
			let buckets: [[SpringStatus]]
			let brokenRunLengths: [Int]
			let brokenRunStarted: Bool

			var debugDescription: String {
				let rStr = String(describing:buckets).padding(toLength: 50, withPad: " ", startingAt: 0)
				let startedStr: String = switch brokenRunStarted {
				case true: " [+]"
				case false: ""
				}
				return "\(rStr) - \(brokenRunLengths)\(startedStr)"
			}
		}
	}
}
