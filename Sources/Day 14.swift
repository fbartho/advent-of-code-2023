import Foundation

/*
 --- Day 14: Parabolic Reflector Dish ---

 You reach the place where all of the mirrors were pointing: a massive parabolic reflector dish attached to the side of another large mountain.

 The dish is made up of many small mirrors, but while the mirrors themselves are roughly in the shape of a parabolic reflector dish, each individual mirror seems to be pointing in slightly the wrong direction. If the dish is meant to focus light, all it's doing right now is sending it in a vague direction.

 This system must be what provides the energy for the lava! If you focus the reflector dish, maybe you can go where it's pointing and use the light to fix the lava production.

 Upon closer inspection, the individual mirrors each appear to be connected via an elaborate system of ropes and pulleys to a large metal platform below the dish. The platform is covered in large rocks of various shapes. Depending on their position, the weight of the rocks deforms the platform, and the shape of the platform controls which ropes move and ultimately the focus of the dish.

 In short: if you move the rocks, you can focus the dish. The platform even has a control panel on the side that lets you tilt it in one of four directions! The rounded rocks (O) will roll when the platform is tilted, while the cube-shaped rocks (#) will stay in place. You note the positions of all of the empty spaces (.) and rocks (your puzzle input). For example:

 O....#....
 O.OO#....#
 .....##...
 OO.#O....O
 .O.....O#.
 O.#..O.#.#
 ..O..#O..O
 .......O..
 #....###..
 #OO..#....
 Start by tilting the lever so all of the rocks will slide north as far as they will go:

 OOOO.#.O..
 OO..#....#
 OO..O##..O
 O..#.OO...
 ........#.
 ..#....#.#
 ..O..#.O.O
 ..O.......
 #....###..
 #....#....
 You notice that the support beams along the north side of the platform are damaged; to ensure the platform doesn't collapse, you should calculate the total load on the north support beams.

 The amount of load caused by a single rounded rock (O) is equal to the number of rows from the rock to the south edge of the platform, including the row the rock is on. (Cube-shaped rocks (#) don't contribute to load.) So, the amount of load caused by each rock in each row is as follows:

 OOOO.#.O.. 10
 OO..#....#  9
 OO..O##..O  8
 O..#.OO...  7
 ........#.  6
 ..#....#.#  5
 ..O..#.O.O  4
 ..O.......  3
 #....###..  2
 #....#....  1
 The total load is the sum of the load caused by all of the rounded rocks. In this example, the total load is 136.

 Tilt the platform so that the rounded rocks all roll north. Afterward, what is the total load on the north support beams?
 */
struct Day14Part1: AdventDayPart {
	var data: String

	static var day: Int = 14
	static var part: Int = 1

	func run() async throws {
		let platform = PlatformMap(data)
		guard platform.grid.rows.count >= 1 else {
			fatalError("Not enough data \(data)")
		}
		print(platform)
		print("---------------")
		let tilted = platform.tiltingUntilSettled(toThe: .north)
		print("Tilted:\n", tilted)
		print("---------------")

		print("Total Load: \(tilted.totalLoad)")
	}
	struct PlatformMap: HasInitFromString, CustomDebugStringConvertible, Hashable, Equatable {
		var grid: Grid<TileType>

		init(grid: Grid<TileType>) {
			self.grid = grid
		}

		init(_ str: String) {
			guard let g = Grid<TileType>(str) else {
				fatalError("Unexpectedly undefined grid!")
			}
			grid = g
		}
		var debugDescription: String {
			return "\(grid)"
		}
		func printSelf() {
			print(self)
		}

		/// The amount of load caused by a single rounded rock (O) is equal to the number of rows
		/// 	from the rock to the south edge of the platform,
		///		-- including the row the rock is on.
		var totalLoad: Int {
			let colCount = grid.colCount

			return grid.allCoords().filter({ grid[$0] == .rollingRock }).map({ $0.y })
				.map({ y in
					return colCount - y
				})
				.reduce(0, +)
		}

		func tiltingUntilSettled(toThe direction: Grid<TileType>.Direction) -> PlatformMap {
			// info("Tilting: \(direction)")
			var rollables = grid.allCoords().filter({ grid[$0] == .rollingRock })
			var nextGrid = grid
			while rollables.count > 0 {
				var stuckCount = 0
				rollables = rollables.compactMap({ coord in
					guard let nextCoord = grid.shift(coord, toThe: direction) else {
						return nil
					}
					switch nextGrid[nextCoord] {
					case .rollingRock:
						// If there's already a rolling rock, then wait for it to move
						stuckCount += 1
						return coord
					case .empty:
						nextGrid[nextCoord] = .rollingRock
						nextGrid[coord] = .empty
						return nextCoord
					case .cubeRock:
						// So no further mutations are necessary
						return nil
					}
				})
				if !rollables.isEmpty && rollables.count == stuckCount {
					// Abort if everything is stuck!
					break
				}
			}
			return Self(grid: nextGrid)
		}

		enum TileType: String, HasFailableInitFromString, CustomDebugStringConvertible {
			case empty = "."
			case cubeRock = "#"
			case rollingRock = "O"
			//init?(_ str: String) {
			//	self.init(rawValue: str)
			//}
			init(_ str: String) {
				self.init(rawValue: str)!
			}
			var debugDescription: String {
				return self.rawValue
			}
		}
	}
}

/*
 --- Part Two ---

 The parabolic reflector dish deforms, but not in a way that focuses the beam. To do that, you'll need to move the rocks to the edges of the platform. Fortunately, a button on the side of the control panel labeled "spin cycle" attempts to do just that!

 Each cycle tilts the platform four times so that the rounded rocks roll north, then west, then south, then east. After each tilt, the rounded rocks roll as far as they can before the platform tilts in the next direction. After one cycle, the platform will have finished rolling the rounded rocks in those four directions in that order.

 Here's what happens in the example above after each of the first few cycles:

 After 1 cycle:
 .....#....
 ....#...O#
 ...OO##...
 .OO#......
 .....OOO#.
 .O#...O#.#
 ....O#....
 ......OOOO
 #...O###..
 #..OO#....

 After 2 cycles:
 .....#....
 ....#...O#
 .....##...
 ..O#......
 .....OOO#.
 .O#...O#.#
 ....O#...O
 .......OOO
 #..OO###..
 #.OOO#...O

 After 3 cycles:
 .....#....
 ....#...O#
 .....##...
 ..O#......
 .....OOO#.
 .O#...O#.#
 ....O#...O
 .......OOO
 #...O###.O
 #.OOO#...O
 This process should work if you leave it running long enough, but you're still worried about the north support beams. To make sure they'll survive for a while, you need to calculate the total load on the north support beams after 1000000000 cycles.

 In the above example, after 1000000000 cycles, the total load on the north support beams is 64.

 Run the spin cycle for 1000000000 cycles. Afterward, what is the total load on the north support beams?
 */
struct Day14Part2: AdventDayPart {
	var data: String

	static var day: Int = 14
	static var part: Int = 2

	typealias PlatformMap = Day14Part1.PlatformMap

	static var ShakeLimit = 1_000_000_000

	func run() async throws {
		let platform = PlatformMap(data)
		guard platform.grid.rows.count >= 1 else {
			fatalError("Not enough data \(data)")
		}
		print(platform)
		print("---------------")
		var count = 0
		var seen: Set<PlatformMap> = Set()
		var current = platform
		var results: [PlatformMap] = []
		var last = current
		while count < Self.ShakeLimit {
			if seen.contains(current) {
				print(
					"Duplicate State on loop index \(count), early exit! \((count/1_000_000_000) * 100)%"
				)
				break
			}
			seen.insert(current)
			results.append(current)
			current = spinCycle(platform: current)
			count += 1
			// print(count, current.totalLoad, current)
			if last == current {
				print("Aborting early at \(count) \((Double(count)/1_000_000_000) * 100)%")
				break
			}
			last = current
		}
		print("---------------")
		if let prefixLength = results.firstIndex(of: current) {
			let loopLength = results.count - prefixLength
			let offset = (Self.ShakeLimit - prefixLength) % loopLength
			let finalStateIndex = prefixLength + offset
			current = results[finalStateIndex]
		}
		print("---------------")

		print("Total Load: \(current.totalLoad)")
	}
	func spinCycle(platform: PlatformMap) -> PlatformMap {
		var result = platform
		result = result.tiltingUntilSettled(toThe: .north)
		result = result.tiltingUntilSettled(toThe: .west)
		result = result.tiltingUntilSettled(toThe: .south)
		result = result.tiltingUntilSettled(toThe: .east)
		return result
	}
}
