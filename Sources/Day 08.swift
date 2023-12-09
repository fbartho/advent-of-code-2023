import Foundation

/*
 --- Day 8: Haunted Wasteland ---

 You're still riding a camel across Desert Island when you spot a sandstorm quickly approaching. When you turn to warn the Elf, she disappears before your eyes! To be fair, she had just finished warning you about ghosts a few minutes ago.

 One of the camel's pouches is labeled "maps" - sure enough, it's full of documents (your puzzle input) about how to navigate the desert. At least, you're pretty sure that's what they are; one of the documents contains a list of left/right instructions, and the rest of the documents seem to describe some kind of network of labeled nodes.

 It seems like you're meant to use the left/right instructions to navigate the network. Perhaps if you have the camel follow the same instructions, you can escape the haunted wasteland!

 After examining the maps for a bit, two nodes stick out: AAA and ZZZ. You feel like AAA is where you are now, and you have to follow the left/right instructions until you reach ZZZ.

 This format defines each node of the network individually. For example:

 RL

 AAA = (BBB, CCC)
 BBB = (DDD, EEE)
 CCC = (ZZZ, GGG)
 DDD = (DDD, DDD)
 EEE = (EEE, EEE)
 GGG = (GGG, GGG)
 ZZZ = (ZZZ, ZZZ)
 Starting with AAA, you need to look up the next element based on the next left/right instruction in your input. In this example, start with AAA and go right (R) by choosing the right element of AAA, CCC. Then, L means to choose the left element of CCC, ZZZ. By following the left/right instructions, you reach ZZZ in 2 steps.

 Of course, you might not find ZZZ right away. If you run out of left/right instructions, repeat the whole sequence of instructions as necessary: RL really means RLRLRLRLRLRLRLRL... and so on. For example, here is a situation that takes 6 steps to reach ZZZ:

 LLR

 AAA = (BBB, BBB)
 BBB = (AAA, ZZZ)
 ZZZ = (ZZZ, ZZZ)
 Starting at AAA, follow the left/right instructions. How many steps are required to reach ZZZ?
 */
struct Day08Part1: AdventDayPart {
	var data: String

	static var day: Int = 8
	static var part: Int = 1

	func run() async throws {
		let graph = Graph(data: data)
		print("------")
		let stepCount = graph.countSteps(from: "AAA", to: "ZZZ")
		print("Num steps: \(stepCount)")
	}

	struct Graph {
		let navigation: [Direction]
		let leftLinks: [String: String]
		let rightLinks: [String: String]

		func countSteps(from: String, to: String) -> Int {
			guard from != to else { return 0 }
			var navigator = LoopIterator(collection: navigation)
			var count = 0
			var currentLocation = from
			while let dir = navigator.next() {
				if currentLocation == to {
					return count
				}

				guard let nextLocation = switch dir {
				case .left: leftLinks[currentLocation]
				case .right: rightLinks[currentLocation]
				} else {
					fatalError("LostError: No location for \(currentLocation) after \(count) steps -- Map not fully described?")
				}
				currentLocation = nextLocation
				count += 1
			}
			fatalError("CodeFlowError: Expected earlier exit above.")
		}

		init(data: String) {
			let chunks = data.splitAndTrim(separator: "\n", maxSplits: 1)
			guard chunks.count == 2 else {
				fatalError("ValidationError: Improperly described map. Expected line of directions, but got:\n \(data)")
			}
			navigation = parse(from: chunks[0], separator: "")

			var l: [String: String] = [:]
			var r: [String: String] = [:]

			let lines = chunks[1].splitAndTrim(separator: "\n")
			guard lines.count >= 1 else {
				fatalError("ValidationError: Improperly described map, expected at least one link")
			}
			for line in lines {
				let entryBits = line.splitAndTrim(separator: "=")
				guard entryBits.count == 2 else { fatalError("ValidationError: Invalid entry: \(line)") }

				let destinations = entryBits[1].filter({$0 != "(" && $0 != ")"}).splitAndTrim(separator: ",")
				guard destinations.count == 2 else { fatalError("ValidationError: Invalid entry destinations: \(entryBits[1])") }
				l[entryBits[0]] = destinations[0]
				r[entryBits[0]] = destinations[1]
			}
			leftLinks = l
			rightLinks = r
		}

		enum Direction: Character, HasFailableInitFromString {
			case left = "L"
			case right = "R"

			init?(_ char: Character) {
				self.init(rawValue: char)
			}

			init?(_ str: String) {
				guard let char = str.first else {
					return nil
				}
				self.init(char)
			}
		}
	}
}
