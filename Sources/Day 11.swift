import Foundation

/*
 --- Day 11: Cosmic Expansion ---

 You continue following signs for "Hot Springs" and eventually come across an observatory. The Elf within turns out to be a researcher studying cosmic expansion using the giant telescope here.

 He doesn't know anything about the missing machine parts; he's only visiting for this research project. However, he confirms that the hot springs are the next-closest area likely to have people; he'll even take you straight there once he's done with today's observation analysis.

 Maybe you can help him with the analysis to speed things up?

 The researcher has collected a bunch of data and compiled the data into a single giant image (your puzzle input). The image includes empty space (.) and galaxies (#). For example:

 ...#......
 .......#..
 #.........
 ..........
 ......#...
 .#........
 .........#
 ..........
 .......#..
 #...#.....
 The researcher is trying to figure out the sum of the lengths of the shortest path between every pair of galaxies. However, there's a catch: the universe expanded in the time it took the light from those galaxies to reach the observatory.

 Due to something involving gravitational effects, only some space expands. In fact, the result is that any rows or columns that contain no galaxies should all actually be twice as big.

 In the above example, three columns and two rows contain no galaxies:

 v  v  v
 ...#......
 .......#..
 #.........
 >..........<
 ......#...
 .#........
 .........#
 >..........<
 .......#..
 #...#.....
 ^  ^  ^
 These rows and columns need to be twice as big; the result of cosmic expansion therefore looks like this:

 ....#........
 .........#...
 #............
 .............
 .............
 ........#....
 .#...........
 ............#
 .............
 .............
 .........#...
 #....#.......
 Equipped with this expanded universe, the shortest path between every pair of galaxies can be found. It can help to assign every galaxy a unique number:

 ....1........
 .........2...
 3............
 .............
 .............
 ........4....
 .5...........
 ............6
 .............
 .............
 .........7...
 8....9.......
 In these 9 galaxies, there are 36 pairs. Only count each pair once; order within the pair doesn't matter. For each pair, find any shortest path between the two galaxies using only steps that move up, down, left, or right exactly one . or # at a time. (The shortest path between two galaxies is allowed to pass through another galaxy.)

 For example, here is one of the shortest paths between galaxies 5 and 9:

 ....1........
 .........2...
 3............
 .............
 .............
 ........4....
 .5...........
 .##.........6
 ..##.........
 ...##........
 ....##...7...
 8....9.......
 This path has length 9 because it takes a minimum of nine steps to get from galaxy 5 to galaxy 9 (the eight locations marked # plus the step onto galaxy 9 itself). Here are some other example shortest path lengths:

 Between galaxy 1 and galaxy 7: 15
 Between galaxy 3 and galaxy 6: 17
 Between galaxy 8 and galaxy 9: 5
 In this example, after expanding the universe, the sum of the shortest path between all 36 pairs of galaxies is 374.

 Expand the universe, then find the length of the shortest path between every pair of galaxies. What is the sum of these lengths?
 */
struct Day11Part1: AdventDayPart {
	var data: String

	static var day: Int = 11
	static var part: Int = 1

	func run() async throws {

		let galaxy = Galaxy(data)
		print("\(galaxy)")
		print("---------")
		let inflated = galaxy.inflated
		print("Inflated\n\(galaxy)")
		print("---------")
		let shortestStarPaths = inflated.shortestStarPaths
		print("Shortest: \n \(shortestStarPaths)")
		let pathLengths = shortestStarPaths.map({ p in
			let result = p.stepwiseLength
			print("\(p) -> \(result)")
			return result
		})
		print("---------")
		let lengthSum = pathLengths.reduce(0, +)
		print("Length Sum: \(lengthSum)")
	}
	typealias Coord = Coord2<Int>
	struct Galaxy: HasInitFromString, CustomDebugStringConvertible {
		let stars: [Coord]
		let bounds: Frame<Int>

		init(stars: [Coord], bounds: Frame<Int>) {
			self.stars = stars
			self.bounds = bounds
		}
		init(_ str: String) {
			let lines = str.splitAndTrim(separator: "\n")
			var rows: [[MapTile]] = []
			var newStars: [Coord] = []
			for (rowIndex, line) in lines.indexed() {
				var currentRow: [MapTile] = []
				let explodedLine = line.split(separator: "")
				for (charIndex, char) in explodedLine.indexed() {
					guard let tile = MapTile(rawValue: char) else {
						fatalError("ValidationError: Unknown Map Tile \(char)")
					}

					if tile == .star {
						newStars.append((x: charIndex, y: rowIndex))
						currentRow.append(.star)
					} else {
						currentRow.append(.nothing)
					}
				}
				rows.append(currentRow)
			}
			guard rows.count >= 1 && newStars.count >= 1 else {
				fatalError("Not enough data \(str)")
			}

			stars = newStars
			bounds = Frame(width: rows.first!.count, height: rows.count)
		}

		var inflated: Galaxy {
			var emptyRowIndices = Set(bounds.yExclusiveRange)
			var emptyColIndices = Set(bounds.xExclusiveRange)

			for coord in stars {
				emptyRowIndices.remove(coord.y)
				emptyColIndices.remove(coord.x)
			}
			var newBounds = bounds
			newBounds.size.width += emptyColIndices.count
			newBounds.size.height += emptyRowIndices.count

			let newStars: [Coord] =
				stars.map({ star in
					let numLowerShifts = emptyRowIndices.filter({ $0 < star.y }).count

					return (x: star.x, y: star.y + numLowerShifts)
				})
				.map({ star in
					let numLowerShifts = emptyColIndices.filter({ $0 < star.x }).count

					return (x: star.x + numLowerShifts, y: star.y)
				})

			return Galaxy(stars: newStars, bounds: newBounds)
		}
		var pairings: PairingsIterator<[Coord]> {
			return PairingsIterator(collection: stars)
		}
		var shortestStarPaths: [Path2<Int>] {
			return pairings.map(Path2<Int>.init)
		}
		var debugDescription: String {
			return "Galaxy\(stars)\n(\(bounds))"
		}
		enum MapTile: String.SubSequence {
			case nothing = "."
			case star = "#"
		}
	}
}
extension Path2 where Bound == Int {
	var stepwiseLength: Int {
		return Int(abs(to.x - from.x) + abs(to.y - from.y))
	}
}

/*
 --- Part Two ---

 The galaxies are much older (and thus much farther apart) than the researcher initially estimated.

 Now, instead of the expansion you did before, make each empty row or column one million times larger. That is, each empty row should be replaced with 1000000 empty rows, and each empty column should be replaced with 1000000 empty columns.

 (In the example above, if each empty row or column were merely 10 times larger, the sum of the shortest paths between every pair of galaxies would be 1030. If each empty row or column were merely 100 times larger, the sum of the shortest paths between every pair of galaxies would be 8410. However, your universe will need to expand far beyond these values.)

 Starting with the same initial image, expand the universe according to these new rules, then find the length of the shortest path between every pair of galaxies. What is the sum of these lengths?
 */
struct Day11Part2: AdventDayPart {
	var data: String

	static var day: Int = 11
	static var part: Int = 2

	func run() async throws {

		let galaxy = Galaxy(data)
		print("\(galaxy)")
		print("---------")
		let inflated = galaxy.inflated
		print("Inflated\n\(galaxy)")
		print("---------")
		let shortestStarPaths = inflated.shortestStarPaths
		print("Shortest: \n \(shortestStarPaths)")
		let pathLengths = shortestStarPaths.map({ p in
			let result = p.stepwiseLength
			print("\(p) -> \(result)")
			return result
		})
		print("---------")
		let lengthSum = pathLengths.reduce(0, +)
		print("Length Sum: \(lengthSum)")
	}

	typealias Coord = Coord2<Int>
	struct Galaxy: HasInitFromString, CustomDebugStringConvertible {
		let stars: [Coord]
		let bounds: Frame<Int>

		static var InflationFactor = 1_000_000 - 1

		init(stars: [Coord], bounds: Frame<Int>) {
			self.stars = stars
			self.bounds = bounds
		}
		init(_ str: String) {
			let lines = str.splitAndTrim(separator: "\n")
			var rows: [[MapTile]] = []
			var newStars: [Coord] = []
			for (rowIndex, line) in lines.indexed() {
				var currentRow: [MapTile] = []
				let explodedLine = line.split(separator: "")
				for (charIndex, char) in explodedLine.indexed() {
					guard let tile = MapTile(rawValue: char) else {
						fatalError("ValidationError: Unknown Map Tile \(char)")
					}

					if tile == .star {
						newStars.append((x: charIndex, y: rowIndex))
						currentRow.append(.star)
					} else {
						currentRow.append(.nothing)
					}
				}
				rows.append(currentRow)
			}
			guard rows.count >= 1 && newStars.count >= 1 else {
				fatalError("Not enough data \(str)")
			}

			stars = newStars
			bounds = Frame(width: rows.first!.count, height: rows.count)
		}

		var inflated: Galaxy {
			var emptyRowIndices = Set(bounds.yExclusiveRange)
			var emptyColIndices = Set(bounds.xExclusiveRange)

			for coord in stars {
				emptyRowIndices.remove(coord.y)
				emptyColIndices.remove(coord.x)
			}
			var newBounds = bounds
			newBounds.size.width += emptyColIndices.count
			newBounds.size.height += emptyRowIndices.count

			let newStars: [Coord] =
				stars.map({ star in
					let numLowerShifts = emptyRowIndices.filter({ $0 < star.y }).count

					let spacing = numLowerShifts * Self.InflationFactor

					return (x: star.x, y: star.y + spacing)
				})
				.map({ star in
					let numLowerShifts = emptyColIndices.filter({ $0 < star.x }).count

					let spacing = numLowerShifts * Self.InflationFactor

					return (x: star.x + spacing, y: star.y)
				})

			return Galaxy(stars: newStars, bounds: newBounds)
		}
		var pairings: PairingsIterator<[Coord]> {
			return PairingsIterator(collection: stars)
		}
		var shortestStarPaths: [Path2<Int>] {
			return pairings.map(Path2<Int>.init)
		}
		var debugDescription: String {
			return "Galaxy\(stars)\n(\(bounds))"
		}
		enum MapTile: String.SubSequence {
			case nothing = "."
			case star = "#"
		}
	}
}
