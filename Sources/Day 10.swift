import Foundation

/*
 --- Day 10: Pipe Maze ---

 You use the hang glider to ride the hot air from Desert Island all the way up to the floating metal island. This island is surprisingly cold and there definitely aren't any thermals to glide on, so you leave your hang glider behind.

 You wander around for a while, but you don't find any people or animals. However, you do occasionally find signposts labeled "Hot Springs" pointing in a seemingly consistent direction; maybe you can find someone at the hot springs and ask them where the desert-machine parts are made.

 The landscape here is alien; even the flowers and trees are made of metal. As you stop to admire some metal grass, you notice something metallic scurry away in your peripheral vision and jump into a big pipe! It didn't look like any animal you've ever seen; if you want a better look, you'll need to get ahead of it.

 Scanning the area, you discover that the entire field you're standing on is densely packed with pipes; it was hard to tell at first because they're the same metallic silver color as the "ground". You make a quick sketch of all of the surface pipes you can see (your puzzle input).

 The pipes are arranged in a two-dimensional grid of tiles:

 - | is a vertical pipe connecting north and south.
 - - is a horizontal pipe connecting east and west.
 - L is a 90-degree bend connecting north and east.
 - J is a 90-degree bend connecting north and west.
 - 7 is a 90-degree bend connecting south and west.
 - F is a 90-degree bend connecting south and east.
 - . is ground; there is no pipe in this tile.
 - S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.

 Based on the acoustics of the animal's scurrying, you're confident the pipe that contains the animal is one large, continuous loop.

 For example, here is a square loop of pipe:

 .....
 .F-7.
 .|.|.
 .L-J.
 .....
 If the animal had entered this loop in the northwest corner, the sketch would instead look like this:

 .....
 .S-7.
 .|.|.
 .L-J.
 .....
 In the above diagram, the S tile is still a 90-degree F bend: you can tell because of how the adjacent pipes connect to it.

 Unfortunately, there are also many pipes that aren't connected to the loop! This sketch shows the same loop as above:

 -L|F7
 7S-7|
 L|7||
 -L-J|
 L|-JF
 In the above diagram, you can still figure out which pipes form the main loop: they're the ones connected to S, pipes those pipes connect to, pipes those pipes connect to, and so on. Every pipe in the main loop connects to its two neighbors (including S, which will have exactly two pipes connecting to it, and which is assumed to connect back to those two pipes).

 Here is a sketch that contains a slightly more complex main loop:

 ..F7.
 .FJ|.
 SJ.L7
 |F--J
 LJ...
 Here's the same example sketch with the extra, non-main-loop pipe tiles also shown:

 7-F7-
 .FJ|7
 SJLL7
 |F--J
 LJ.LJ
 If you want to get out ahead of the animal, you should find the tile in the loop that is farthest from the starting position. Because the animal is in the pipe, it doesn't make sense to measure this by direct distance. Instead, you need to find the tile that would take the longest number of steps along the loop to reach from the starting point - regardless of which way around the loop the animal went.

 In the first example with the square loop:

 .....
 .S-7.
 .|.|.
 .L-J.
 .....
 You can count the distance each tile in the loop is from the starting point like this:

 .....
 .012.
 .1.3.
 .234.
 .....
 In this example, the farthest point from the start is 4 steps away.

 Here's the more complex loop again:

 ..F7.
 .FJ|.
 SJ.L7
 |F--J
 LJ...
 Here are the distances for each tile on that loop:

 ..45.
 .236.
 01.78
 14567
 23...
 Find the single giant loop starting at S. How many steps along the loop does it take to get from the starting position to the point farthest from the starting position?
 */
struct Day10Part1: AdventDayPart {
	var data: String

	static var day: Int = 10
	static var part: Int = 1

	func run() async throws {
		let maze = Maze(data)
		print(maze)
		print("--------")
		let distMap = maze.distanceMap()
		Maze.printDistanceMap(distMap)
		print("--------")
		let maxDist = Maze.maxDistanceFromBeast(using: distMap)
		print("Max Distance: \(maxDist)")
	}

	typealias Coord = (x: Int, y: Int)
	typealias DistanceMap = [[Int]]

	struct Maze: HasInitFromString, CustomDebugStringConvertible {
		let mouse: Coord
		let tiles: [[TileType]]
		var debugDescription: String {
			let tileStr = tiles.map({ $0.map({ String($0.rawValue) }).joined(separator: "") })
				.joined(separator: "\n")
			return "Mouse @ \(mouse)\n\(tileStr)"
		}

		init(_ str: String) {
			let rowStrs = str.splitAndTrim(separator: "\n")

			let rows: [[TileType]] = rowStrs.map({
				$0.split(separator: "")
					.map({ tileStr in
						return TileType(rawValue: tileStr.first!)!
					})
			})

			var mouseTmp: Coord = (x: -1, y: -1)
			for rowIndex in rows.indices {
				let row = rows[rowIndex]
				for colIndex in row.indices {
					let tile = row[colIndex]
					if tile == .start {
						mouseTmp = (x: colIndex, y: rowIndex)
					}
				}
			}
			guard mouseTmp.x >= 0 && mouseTmp.y >= 0 else {
				fatalError("ValidationError: No beast found in maze.")
			}
			mouse = mouseTmp
			tiles = rows
		}

		func tile(coord: Coord) -> TileType {
			return tiles[coord.y][coord.x]
		}

		func distanceMap() -> [[Int]] {
			// Initialize everything to -1
			var result = tiles.map({ $0.map({ _ in -1 }) })
			// Mark the mouse coord as 0
			result[mouse.y][mouse.x] = 0

			let adjacent = calculateAdjacentTileCoords(for: mouse)
			let outboundPaths = adjacent.filter({ (towards, coord) in
				let tile = tile(coord: coord)
				// print("\(tile.rawValue) - coord: \(coord)")
				return tile.canEnter(traveling: towards)
			})
			guard outboundPaths.count == 2 else {
				fatalError(
					"Maze Construction Error: wrong number of possible paths from \(mouse) \(outboundPaths)"
				)
			}
			var hasFoundStart = false

			var distance = 1
			/// Chase the pipe around in both directions
			var a = try! navigate(path: outboundPaths[0], in: &result, distance: distance)
			var b = try! navigate(path: outboundPaths[1], in: &result, distance: distance)
			while !hasFoundStart {
				distance += 1
				do {
					a = try navigate(path: a, in: &result, distance: distance)
					b = try navigate(path: b, in: &result, distance: distance)
				} catch {
					hasFoundStart = true
				}
			}
			return result
		}
		func navigate(path: (Direction, Coord), in map: inout DistanceMap, distance: Int) throws -> (
			Direction, Coord
		) {
			let (dir, coord) = path
			// print(Self.printDistanceMap(map))
			// print("\(path)")
			let mapDist = map[coord.y][coord.x]
			if mapDist == 0 {
				guard tile(coord: coord) == .start else {
					fatalError("TravelError: Only 0-distance location should be the start")
				}
				throw NavigationError.alreadyFoundStart
			}
			guard mapDist == -1 else {
				throw NavigationError.foundStart
			}
			map[coord.y][coord.x] = distance

			let tile = tile(coord: coord)
			let nextDirection = tile.nextDirection(enteredTileByGoing: dir)
			let nextCoord = coordFor(coord: coord, toThe: nextDirection)
			guard isSafe(coord: nextCoord) else {
				fatalError("TravelError: Tried to step out of the maze at \(nextCoord)")
			}
			return (nextDirection, nextCoord)
		}
		func coordFor(coord: Coord, toThe dir: Direction) -> Coord {
			switch dir {
			case .north: return (x: coord.x, y: coord.y - 1)
			case .south: return (x: coord.x, y: coord.y + 1)
			case .east: return (x: coord.x + 1, y: coord.y)
			case .west: return (x: coord.x - 1, y: coord.y)
			}
		}
		func isSafe(coord: Coord) -> Bool {
			return coord.x >= 0
				&& coord.y >= 0
				&& coord.x < tiles[0].count
				&& coord.y < tiles.count
		}
		func calculateAdjacentTileCoords(for coord: Coord) -> [(Direction, Coord)] {
			return [
				.north,
				.south,
				.east,
				.west,
			]
			.map({ ($0, coordFor(coord: coord, toThe: $0)) }).filter({ isSafe(coord: $0.1) })
		}
		static func maxDistanceFromBeast(using distanceMap: DistanceMap) -> Int {
			return distanceMap.joined().max()!
		}
		static func printDistanceMap(_ distanceMap: DistanceMap) {
			print(distanceMap.map({ $0.map(String.init).joined(separator: "\t") }).joined(separator: "\n"))
		}

		/// Not actually a errors  🤷🏻‍♂️
		enum NavigationError: Error {
			case alreadyFoundStart
			case foundStart
		}

		enum Direction {
			case north, south, east, west

			var inverse: Direction {
				return switch self {
				case .north: .south
				case .south: .north
				case .east: .west
				case .west: .east
				}
			}
		}
		enum TileType: Character {
			/// | is a vertical pipe connecting north and south.
			case vertical = "|"
			/// - is a horizontal pipe connecting east and west.
			case horizontal = "-"
			/// L is a 90-degree bend connecting north and east.
			case northAndEast = "L"
			/// J is a 90-degree bend connecting north and west.
			case northAndWest = "J"
			/// 7 is a 90-degree bend connecting south and west.
			case southAndWest = "7"
			/// F is a 90-degree bend connecting south and east.
			case southAndEast = "F"
			/// . is ground; there is no pipe in this tile.
			case ground = "."
			/// S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.
			case start = "S"

			var validEntranceDirections: [Direction] {
				return switch self {
				case .vertical: [.north, .south]
				case .horizontal: [.west, .east]
				case .northAndEast: [.south, .west]
				case .northAndWest: [.south, .east]
				case .southAndWest: [.north, .east]
				case .southAndEast: [.north, .west]
				case .ground: []
				case .start: [.north, .south, .east, .west]
				}
			}
			var validExitDirections: [Direction] {
				return switch self {
				case .vertical: [.north, .south]
				case .horizontal: [.west, .east]
				case .northAndEast: [.north, .east]
				case .northAndWest: [.north, .west]
				case .southAndWest: [.south, .west]
				case .southAndEast: [.south, .east]
				case .ground: []
				case .start: [.north, .south, .east, .west]
				}
			}
			func canEnter(traveling: Direction) -> Bool {
				return validEntranceDirections.contains(traveling)
			}
			func nextDirection(enteredTileByGoing: Direction) -> Direction {
				let dir = enteredTileByGoing.inverse
				return validExitDirections.filter({ $0 != dir }).first!
			}
		}
	}
}

/*
 --- Part Two ---

 You quickly reach the farthest point of the loop, but the animal never emerges. Maybe its nest is within the area enclosed by the loop?

 To determine whether it's even worth taking the time to search for such a nest, you should calculate how many tiles are contained within the loop. For example:

 ...........
 .S-------7.
 .|F-----7|.
 .||.....||.
 .||.....||.
 .|L-7.F-J|.
 .|..|.|..|.
 .L--J.L--J.
 ...........
 The above loop encloses merely four tiles - the two pairs of . in the southwest and southeast (marked I below). The middle . tiles (marked O below) are not in the loop. Here is the same loop again with those regions marked:

 ...........
 .S-------7.
 .|F-----7|.
 .||OOOOO||.
 .||OOOOO||.
 .|L-7OF-J|.
 .|II|O|II|.
 .L--JOL--J.
 .....O.....
 In fact, there doesn't even need to be a full tile path to the outside for tiles to count as outside the loop - squeezing between pipes is also allowed! Here, I is still within the loop and O is still outside the loop:

 ..........
 .S------7.
 .|F----7|.
 .||OOOO||.
 .||OOOO||.
 .|L-7F-J|.
 .|II||II|.
 .L--JL--J.
 ..........
 In both of the above examples, 4 tiles are enclosed by the loop.

 Here's a larger example:

 .F----7F7F7F7F-7....
 .|F--7||||||||FJ....
 .||.FJ||||||||L7....
 FJL7L7LJLJ||LJ.L-7..
 L--J.L7...LJS7F-7L7.
 ....F-J..F7FJ|L7L7L7
 ....L7.F7||L7|.L7L7|
 .....|FJLJ|FJ|F7|.LJ
 ....FJL-7.||.||||...
 ....L---J.LJ.LJLJ...
 The above sketch has many random bits of ground, some of which are in the loop (I) and some of which are outside it (O):

 OF----7F7F7F7F-7OOOO
 O|F--7||||||||FJOOOO
 O||OFJ||||||||L7OOOO
 FJL7L7LJLJ||LJIL-7OO
 L--JOL7IIILJS7F-7L7O
 OOOOF-JIIF7FJ|L7L7L7
 OOOOL7IF7||L7|IL7L7|
 OOOOO|FJLJ|FJ|F7|OLJ
 OOOOFJL-7O||O||||OOO
 OOOOL---JOLJOLJLJOOO
 In this larger example, 8 tiles are enclosed by the loop.

 Any tile that isn't part of the main loop can count as being enclosed by the loop. Here's another example with many bits of junk pipe lying around that aren't connected to the main loop at all:

 FF7FSF7F7F7F7F7F---7
 L|LJ||||||||||||F--J
 FL-7LJLJ||||||LJL-77
 F--JF--7||LJLJ7F7FJ-
 L---JF-JLJ.||-FJLJJ7
 |F|F-JF---7F7-L7L|7|
 |FFJF7L7F-JF7|JL---7
 7-L-JL7||F7|L7F-7F7|
 L.L7LFJ|||||FJL7||LJ
 L7JLJL-JLJLJL--JLJ.L
 Here are just the tiles that are enclosed by the loop marked with I:

 FF7FSF7F7F7F7F7F---7
 L|LJ||||||||||||F--J
 FL-7LJLJ||||||LJL-77
 F--JF--7||LJLJIF7FJ-
 L---JF-JLJIIIIFJLJJ7
 |F|F-JF---7IIIL7L|7|
 |FFJF7L7F-JF7IIL---7
 7-L-JL7||F7|L7F-7F7|
 L.L7LFJ|||||FJL7||LJ
 L7JLJL-JLJLJL--JLJ.L
 In this last example, 10 tiles are enclosed by the loop.

 Figure out whether you have time to search for the nest by calculating the area within the loop. How many tiles are enclosed by the loop?
 */
struct Day10Part2: AdventDayPart {
	var data: String

	static var day: Int = 10
	static var part: Int = 2

	func run() async throws {
		let maze = Maze(data)
		print(maze)
		print("--------")
		let pipeMap = maze.pipeMap()
		Maze.printDistanceMap(pipeMap.distances)
		print("--------")
		let maxDist = Maze.maxDistanceFromBeast(using: pipeMap.distances)
		print("Max Distance: \(maxDist)")
		print("--------")
		let (result, map) = maze.loopEnclosedTileCount(pipeMap: pipeMap)
		Maze.printDistanceMap(map)
		print("Potential Nest Spots: \(result)")
	}

	typealias Coord = (x: Int, y: Int)
	typealias DistanceMap = [[Int]]

	struct Maze: HasInitFromString, CustomDebugStringConvertible {
		let mouse: Coord
		let tiles: [[TileType]]
		var startPipe: TileType? = nil

		var debugDescription: String {
			let tileStr = tiles.map({ $0.map({ String($0.rawValue) }).joined(separator: "") })
				.joined(separator: "\n")
			return "Mouse @ \(mouse)\n\(tileStr)"
		}

		init(_ str: String) {
			let rowStrs = str.splitAndTrim(separator: "\n")

			let rows: [[TileType]] = rowStrs.map({
				$0.split(separator: "")
					.map({ tileStr in
						return TileType(rawValue: tileStr.first!)!
					})
			})

			var mouseTmp: Coord = (x: -1, y: -1)
			for rowIndex in rows.indices {
				let row = rows[rowIndex]
				for colIndex in row.indices {
					let tile = row[colIndex]
					if tile == .start {
						mouseTmp = (x: colIndex, y: rowIndex)
					}
				}
			}
			guard mouseTmp.x >= 0 && mouseTmp.y >= 0 else {
				fatalError("ValidationError: No beast found in maze.")
			}
			mouse = mouseTmp
			tiles = rows
		}

		func tile(coord: Coord) -> TileType {
			return tiles[coord.y][coord.x]
		}

		/// Outputs a tuple
		/// - number of enclosed tiles
		/// - map for debugging that marks the outside tiles as 0, the main pipe as 1, and the inside tiles as 2
		func loopEnclosedTileCount(pipeMap: (distances: [[Int]], startPipe: TileType)) -> (
			result: Int, map: DistanceMap
		) {
			var result = 0
			var map = pipeMap.distances
			// State Machine vars
			var insideLoop = false
			// when you take an S curve like up-right-up that crosses the pipe
			// U-curves (up-right-down) don't cross the pipe
			var lookingForNorthAndWest = false
			var lookingForSouthAndWest = false

			/// Scan horizontally across the maze
			/// Count the pipe crossings
			for y in 0 ..< tiles.count {
				for x in 0 ..< tiles.first!.count {
					map[y][x] = 0
					var tile = tile(coord: (x: x, y: y))
					if tile == .start {
						tile = pipeMap.startPipe
					}
					let isOnMainLoop = pipeMap.distances[y][x] >= 0
					if !isOnMainLoop && insideLoop {
						result += 1
						map[y][x] = 2
					} else if isOnMainLoop {
						map[y][x] = 1
						switch tile {
						case .vertical:
							insideLoop.toggle()
						case .northAndEast:
							lookingForSouthAndWest = true
						case .northAndWest:
							if lookingForNorthAndWest {
								// S-curve detected
								insideLoop.toggle()
								lookingForNorthAndWest = false
							}
							lookingForSouthAndWest = false
						case .southAndWest:
							if lookingForSouthAndWest {
								// S-curve detected
								insideLoop.toggle()
								lookingForSouthAndWest = false
							}
							lookingForNorthAndWest = false
						case .southAndEast:
							lookingForNorthAndWest = true
						case .horizontal: continue  // no effect
						case .start, .ground: fatalError("Impossiblility")
						}
					}
				}
			}
			return (result, map)
		}

		func pipeMap() -> (distances: [[Int]], startPipe: TileType) {
			// Initialize everything to -1
			var result = tiles.map({ $0.map({ _ in -1 }) })
			// Mark the mouse coord as 0
			result[mouse.y][mouse.x] = 0

			let adjacent = calculateAdjacentTileCoords(for: mouse)
			let outboundPaths = adjacent.filter({ (towards, coord) in
				let tile = tile(coord: coord)
				// print("\(tile.rawValue) - coord: \(coord)")
				return tile.canEnter(towards: towards)
			})
			guard outboundPaths.count == 2 else {
				fatalError(
					"Maze Construction Error: wrong number of possible paths from \(mouse) \(outboundPaths)"
				)
			}

			var hasFoundStart = false
			var distance = 1
			/// Chase the pipe around in both directions
			var a = try! navigate(path: outboundPaths[0], in: &result, distance: distance)
			var b = try! navigate(path: outboundPaths[1], in: &result, distance: distance)
			while !hasFoundStart {
				distance += 1
				do {
					a = try navigate(path: a, in: &result, distance: distance)
					b = try navigate(path: b, in: &result, distance: distance)
				} catch {
					hasFoundStart = true
				}
			}
			return (
				result,
				// Cache the actual pipe the mouse is sitting on
				startPipe: TileType.pipeGiven(outboundDirections: outboundPaths.map({ $0.0 }))
			)
		}
		func navigate(path: (Direction, Coord), in map: inout DistanceMap, distance: Int) throws -> (
			Direction, Coord
		) {
			let (dir, coord) = path
			// print(Self.printDistanceMap(map))
			// print("\(path)")
			let mapDist = map[coord.y][coord.x]
			if mapDist == 0 {
				guard tile(coord: coord) == .start else {
					fatalError("TravelError: Only 0-distance location should be the start")
				}
				throw NavigationError.alreadyFoundStart
			}
			guard mapDist == -1 else {
				throw NavigationError.foundStart
			}
			map[coord.y][coord.x] = distance

			let tile = tile(coord: coord)
			let nextDirection = tile.nextDirection(enteredTileByGoing: dir)
			let nextCoord = coordFor(coord: coord, toThe: nextDirection)
			guard isSafe(coord: nextCoord) else {
				fatalError("TravelError: Tried to step out of the maze at \(nextCoord)")
			}
			return (nextDirection, nextCoord)
		}
		func coordFor(coord: Coord, toThe dir: Direction) -> Coord {
			switch dir {
			case .north: return (x: coord.x, y: coord.y - 1)
			case .south: return (x: coord.x, y: coord.y + 1)
			case .east: return (x: coord.x + 1, y: coord.y)
			case .west: return (x: coord.x - 1, y: coord.y)
			}
		}
		func isSafe(coord: Coord) -> Bool {
			return coord.x >= 0
				&& coord.y >= 0
				&& coord.x < tiles[0].count
				&& coord.y < tiles.count
		}
		func calculateAdjacentTileCoords(for coord: Coord) -> [(Direction, Coord)] {
			return [
				.north,
				.south,
				.east,
				.west,
			]
			.map({ ($0, coordFor(coord: coord, toThe: $0)) }).filter({ isSafe(coord: $0.1) })
		}
		static func maxDistanceFromBeast(using distanceMap: DistanceMap) -> Int {
			return distanceMap.joined().max()!
		}
		static func printDistanceMap(_ distanceMap: DistanceMap) {
			print(distanceMap.map({ $0.map(String.init).joined(separator: "\t") }).joined(separator: "\n"))
		}

		/// Not actually a errors  🤷🏻‍♂️
		enum NavigationError: Error {
			case alreadyFoundStart
			case foundStart
		}

		enum Direction: Int {
			case north = 0
			case south, east, west

			var inverse: Direction {
				return switch self {
				case .north: .south
				case .south: .north
				case .east: .west
				case .west: .east
				}
			}
		}
		enum TileType: Character {
			/// | is a vertical pipe connecting north and south.
			case vertical = "|"
			/// - is a horizontal pipe connecting east and west.
			case horizontal = "-"
			/// L is a 90-degree bend connecting north and east.
			case northAndEast = "L"
			/// J is a 90-degree bend connecting north and west.
			case northAndWest = "J"
			/// 7 is a 90-degree bend connecting south and west.
			case southAndWest = "7"
			/// F is a 90-degree bend connecting south and east.
			case southAndEast = "F"
			/// . is ground; there is no pipe in this tile.
			case ground = "."
			/// S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.
			case start = "S"

			var validEntranceDirections: [Direction] {
				return switch self {
				case .vertical: [.north, .south]
				case .horizontal: [.west, .east]
				case .northAndEast: [.south, .west]
				case .northAndWest: [.south, .east]
				case .southAndWest: [.north, .east]
				case .southAndEast: [.north, .west]
				case .ground: []
				case .start: [.north, .south, .east, .west]
				}
			}
			var validExitDirections: [Direction] {
				return switch self {
				case .vertical: [.north, .south]
				case .horizontal: [.west, .east]
				case .northAndEast: [.north, .east]
				case .northAndWest: [.north, .west]
				case .southAndWest: [.south, .west]
				case .southAndEast: [.south, .east]
				case .ground: []
				case .start: [.north, .south, .east, .west]
				}
			}
			func canEnter(towards: Direction) -> Bool {
				return validEntranceDirections.contains(towards)
			}
			func nextDirection(enteredTileByGoing: Direction) -> Direction {
				let dir = enteredTileByGoing.inverse
				return validExitDirections.filter({ $0 != dir }).first!
			}
			static func pipeGiven(outboundDirections: [Direction]) -> TileType {
				guard outboundDirections.count == 2 else {
					fatalError(
						"UnavailablePipeError: Pipes only have exactly 2 exits in this maze. \(outboundDirections)"
					)
				}
				let dirs = outboundDirections.sorted(by: { $0.rawValue < $1.rawValue })
				return switch (dirs[0], dirs[1]) {
				case (.north, .south): .vertical
				case (.east, .west): .horizontal
				case (.north, .east): .northAndEast
				case (.north, .west): .northAndWest
				case (.south, .east): .southAndEast
				case (.south, .west): .southAndWest
				default: fatalError("UnavailablePipeError: Pipes can't go diagonally \(dirs)")
				}
			}
		}
	}
}
