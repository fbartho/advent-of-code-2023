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
struct Day12Part1: AdventDayPart {
	var data: String

	static var day: Int = 12
	static var part: Int = 1

	func run() async throws {
		var cache: [SpringConditionRecord.AssignmentCacheKey: Int] = [:]

		let records: [SpringConditionRecord] = parse(from: data, separator: "\n")
		let arrangements = records.map({ $0.possibleArrangements(cache: &cache) })

		//		let tmp = [records.first!]
		//		let arrangements = tmp.map({$0.possibleArrangements(cache: &cache)})

		print("---------")
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
			brokenRunLengths = parse(from: bits[1], separator: ",")
		}
		init(_ initialState: [SpringStatus], _ brokenRunLengths: [Int]) {
			self.initialState = initialState
			self.brokenRunLengths = brokenRunLengths
		}
		var possibleArrangements: Int {
			var cache = Self.emptyCache
			return possibleArrangements(cache: &cache)
		}
		func possibleArrangements(cache: inout [AssignmentCacheKey: Int]) -> Int {
			let state = AssignmentCacheKey(assignments: initialState, brokenRunLengths: brokenRunLengths)
			let simplifiedState = state.simplified()
			let result = Self.countArrangements(cache: &cache, cacheKey: simplifiedState)
			return result
		}

		static func countArrangements(
			cache: inout [AssignmentCacheKey: Int],
			cacheKey: AssignmentCacheKey
		) -> Int {
			if let cached = cache[cacheKey] {
				info("cache: \(cacheKey)")
				return cached
			}
			info("calc:  \(cacheKey)")

			guard !cacheKey.isFullyValidated else {
				let result: Int = 1
				cache[cacheKey] = result
				info("Result \(result) for \(cacheKey)")
				return result
			}
			guard cacheKey.hasEnoughPotentialSlots() else {
				let result: Int = 0
				cache[cacheKey] = result
				info("Result \(result) for \(cacheKey)")
				return result
			}

			guard let nextUnknownIndex = cacheKey.assignments.nextUnknownIndex() else {
				let result: Int
				if cacheKey.assignments.contains(.broken)
					&& (cacheKey.brokenRunLengths.isEmpty || cacheKey.brokenRunLengths.contains(0))
				{
					// If there's a broken predicted, but we processed all the broken run lengths
					// then this is not a valid prediction.
					result = 0
				} else {
					result = 1
				}
				cache[cacheKey] = result
				info("Result \(result) for \(cacheKey)")
				return result
			}
			guard cacheKey.isValid(before: nextUnknownIndex) else {
				let result = 0
				cache[cacheKey] = result
				info("Result \(result) for \(cacheKey)")
				return result
			}

			// At this point, the index is definitely pointing to a `.unknown`

			var result: Int = 0
			// Case 1: Place a broken gear
			let brokenSuggestion = cacheKey.injecting(.broken, at: nextUnknownIndex)

			result += countArrangements(
				cache: &cache,
				cacheKey: brokenSuggestion)

			// Case 2: Place a working gear
			let workingSuggestion = cacheKey.injecting(.working, at: nextUnknownIndex)

			result += countArrangements(
				cache: &cache,
				cacheKey: workingSuggestion)

			cache[cacheKey] = result
			info("Result \(result) for \(cacheKey)")
			return result
		}

		enum SpringStatus: Character, HasFailableInitFromString, Hashable, CustomDebugStringConvertible {
			case unknown = "?"
			case working = "."
			case broken = "#"
			init?(_ str: String) {
				self.init(rawValue: str.first!)
			}
			var debugDescription: String {
				return "\(rawValue)"
			}
		}
		struct AssignmentCacheKey: Hashable, CustomDebugStringConvertible {
			let assignments: [SpringStatus]
			let brokenRunLengths: [Int]

			func bucketizedAssignments() -> [[SpringStatus]] {
				var canStart = false
				let trimmed = assignments.trimming(while: { $0 == .working })
				let tmp: [[SpringStatus]] =
					trimmed.reduce(
						into: [[]],
						{ stateGroups, entry in
							switch entry {
							case .unknown, .broken:
								stateGroups[stateGroups.count - 1].append(entry)
								canStart = true
							case .working:
								if canStart {
									stateGroups.append([])
									canStart = false
								}
							}
						}
					)
					.filter({ $0.count > 0 })
				return tmp
			}
			func simplified() -> AssignmentCacheKey {
				var tmp = bucketizedAssignments()
				var tmpRunLengths = brokenRunLengths
				while let firstBucket = tmp.first, let expectedBucketLength = tmpRunLengths.first,
					expectedBucketLength > 0
				{
					let bucketSubset: [SpringStatus].SubSequence
					if expectedBucketLength < firstBucket.count {
						bucketSubset = firstBucket[0 ..< expectedBucketLength]
					} else {
						bucketSubset = firstBucket[0...]
					}
					let subsetConsumesBucket = firstBucket.count == bucketSubset.count
					if subsetConsumesBucket && firstBucket.allDefined
						&& expectedBucketLength > firstBucket.count
					{
						// Bucket has no unknowns, but we needed more entries in the bucket
						return Self.invalidKey
					}
					if !bucketSubset.isEmpty
						&& bucketSubset.allSatisfy({ $0 == .broken })
						&& expectedBucketLength == bucketSubset.count
						&& (subsetConsumesBucket || firstBucket[bucketSubset.count] != .broken)
					{

						if bucketSubset.count == firstBucket.count {
							tmp = Array(tmp.dropFirst())
						} else {
							let dropCount: Int
							if bucketSubset.count + 1 <= firstBucket.count {
								// Drop the next assignment too, because it *must* be a '.working' to be valid,
								// so even if it's currently unknown, we can skip checking invalid paths!
								dropCount = expectedBucketLength + 1
							} else {
								dropCount = expectedBucketLength
							}
							let newFirstBucket = Array(firstBucket.dropFirst(dropCount))
							tmp = tmp.swapping(newFirstBucket, at: 0)
						}
						tmpRunLengths = Array(tmpRunLengths.dropFirst())
					} else {
						break
					}
				}
				let newAssignments = tmp.joined(by: .working).trimming(while: { $0 == .working })
				if tmpRunLengths.isEmpty && !newAssignments.contains(.broken) {
					// We are comprised of a string of .unknown & .working gears
					// but no expected broken gears remains
					// So there's only 1 outcome possible
					return Self.onlyOnePathKey
				}
				return Self(
					assignments: Array(newAssignments),
					brokenRunLengths: tmpRunLengths)
			}

			/// Replace a .unknown at a specified index with either .working or .broken
			func injecting(_ assignment: SpringStatus, at index: [SpringStatus].Index) -> AssignmentCacheKey
			{
				guard assignment != .unknown else {
					fatalError("Misuse: Can't be injecting .unknown")
				}
				guard assignments.indices.contains(index) else {
					fatalError("Out-of-bounds assignment index")
				}
				let buckets = bucketizedAssignments()
				guard let firstBucket = buckets.first, !firstBucket.isEmpty else {
					fatalError("Can't inject assigment into empty/absent bucket")
				}
				guard index < firstBucket.count else {
					// fatalError("When injecting to replace an unknown, the index is expected to be in the first bucket. (Did you forget to simplify the cache key?)")
					print("Invalid: \(self)")
					return Self.invalidKey
				}

				let newAssignments: [SpringStatus]
				if assignment == .broken {
					// If we're placing something in a bucket, check if this would consume the run length
					// If it does, then we need to ensure there's a .working after it!
					let firstBrokenRunLength = brokenRunLengths.first ?? 0

					let hypotheticalNewBucket = firstBucket.swapping(assignment, at: index)
					let wouldConsumeBrokenRun =
						hypotheticalNewBucket.countPrefix(of: .broken) >= firstBrokenRunLength
					if wouldConsumeBrokenRun {
						let isWithinCandidateRun = index < firstBucket.count - 1
						if isWithinCandidateRun {
							let nextIndex = index + 1
							let nextIsUnknown =
								nextIndex < firstBucket.count
								&& firstBucket[nextIndex] == .unknown
							let nextIsBroken =
								nextIndex < firstBucket.count
								&& firstBucket[nextIndex] == .broken

							if nextIsUnknown {
								// Inject 2 entries because we need a .working to follow a .broken when we would drop the broken-run-length
								newAssignments = assignments.replacingSubrange(
									index ..< (nextIndex + 1),
									with: [.broken, .working])
							} else {
								// Next is not .unknown, and it's probably not .working
								// So this is either an invalid assignment, or a sequence of brokens
								let postRunIndex = firstBrokenRunLength
								let postRunNextIsBroken =
									postRunIndex < firstBucket.count
									&& firstBucket[postRunIndex] == .broken
								if nextIsBroken && postRunNextIsBroken {
									return Self.invalidKey
								} else {
									newAssignments = assignments.swapping(
										.broken, at: index)
								}
							}
						} else {
							// Inserting last (this is great, we needed a .working to follow!)
							newAssignments = assignments.swapping(.broken, at: index)
						}
					} else {
						// More brokens are necessary for this run
						newAssignments = assignments.swapping(.broken, at: index)
					}

				} else {
					// assigment == .working
					newAssignments = assignments.swapping(.working, at: index)
				}
				let result = Self(assignments: newAssignments, brokenRunLengths: brokenRunLengths)
					.simplified()

				info("\(assignment) => \(self) -> \(result)")
				return result
			}

			func hasEnoughPotentialSlots() -> Bool {
				return brokenRunLengths.reduce(0, +) + brokenRunLengths.count - 1 <= assignments.count
			}

			func isValid() -> Bool {
				return isValid(before: assignments.endIndex)
			}

			func isValid(before endIndex: [SpringStatus].Index) -> Bool {
				var inBucket = false
				var bucketSize = 0
				var bucketIndex = brokenRunLengths.startIndex
				for i in 0 ..< endIndex {
					switch assignments[i] {
					case .unknown:
						return false
					case .broken:
						if !inBucket {
							inBucket = true
							guard brokenRunLengths.endIndex != bucketIndex else {
								// Ran out of buckets to assign this to!
								return false
							}
							bucketSize = brokenRunLengths[bucketIndex]
						}
						bucketSize -= 1
						if bucketSize < 0 {
							return false
						}
					case .working:
						if inBucket {
							if bucketSize != 0 {
								return false
							}
							inBucket = false
							brokenRunLengths.formIndex(after: &bucketIndex)
						}
					}
				}
				return true
			}

			/// If you've simplified your cache key, and it's fully valid, then
			/// 	- there will be empty assignments
			/// 	- there will be empty brokenRunLengths
			var isFullyValidated: Bool {
				return brokenRunLengths.isEmpty && assignments.isEmpty
			}

			var debugDescription: String {
				let rBase: String
				if assignments.isEmpty {
					rBase = "<empty>"
				} else {
					rBase = assignments.map({ "\($0.rawValue)" }).joined(separator: "")
				}
				let rStr = rBase.padding(toLength: 15, withPad: " ", startingAt: 0)
				return "\(rStr) - \(brokenRunLengths.map({"\($0)"}).joined(separator:","))"
			}

			static var invalidKey: Self {
				return Self(assignments: [], brokenRunLengths: [1])
			}
			/// Any solution that can be shown to have exactly 1 valid assignment
			static var onlyOnePathKey: Self {
				return Self(assignments: [], brokenRunLengths: [])
			}
		}
		typealias AssignmentCache = [SpringConditionRecord.AssignmentCacheKey: Int]
		static var emptyCache: [AssignmentCacheKey: Int] {
			return [:]
		}
	}
}
extension Array where Element == Day12Part1.SpringConditionRecord.SpringStatus {
	var allDefined: Bool {
		return !isEmpty && !contains(.unknown)
	}
	func nextUnknownIndex() -> Index? {
		return firstIndex(of: .unknown)
	}
}
