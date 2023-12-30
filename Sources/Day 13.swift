import Foundation

/*
 --- Day 13: Point of Incidence ---

 With your help, the hot springs team locates an appropriate spring which launches you neatly and precisely up to the edge of Lava Island.

 There's just one problem: you don't see any lava.

 You do see a lot of ash and igneous rock; there are even what look like gray mountains scattered around. After a while, you make your way to a nearby cluster of mountains only to discover that the valley between them is completely full of large mirrors. Most of the mirrors seem to be aligned in a consistent way; perhaps you should head in that direction?

 As you move through the valley of mirrors, you find that several of them have fallen from the large metal frames keeping them in place. The mirrors are extremely flat and shiny, and many of the fallen mirrors have lodged into the ash at strange angles. Because the terrain is all one color, it's hard to tell where it's safe to walk or where you're about to run into a mirror.

 You note down the patterns of ash (.) and rocks (#) that you see as you walk (your puzzle input); perhaps by carefully analyzing these patterns, you can figure out where the mirrors are!

 For example:

 #.##..##.
 ..#.##.#.
 ##......#
 ##......#
 ..#.##.#.
 ..##..##.
 #.#.##.#.

 #...##..#
 #....#..#
 ..##..###
 #####.##.
 #####.##.
 ..##..###
 #....#..#
 To find the reflection in each pattern, you need to find a perfect reflection across either a horizontal line between two rows or across a vertical line between two columns.

 In the first pattern, the reflection is across a vertical line between two columns; arrows on each of the two columns point at the line between the columns:

 123456789
	 ><
 #.##..##.
 ..#.##.#.
 ##......#
 ##......#
 ..#.##.#.
 ..##..##.
 #.#.##.#.
	 ><
 123456789
 In this pattern, the line of reflection is the vertical line between columns 5 and 6. Because the vertical line is not perfectly in the middle of the pattern, part of the pattern (column 1) has nowhere to reflect onto and can be ignored; every other column has a reflected column within the pattern and must match exactly: column 2 matches column 9, column 3 matches 8, 4 matches 7, and 5 matches 6.

 The second pattern reflects across a horizontal line instead:

 1 #...##..# 1
 2 #....#..# 2
 3 ..##..### 3
 4v#####.##.v4
 5^#####.##.^5
 6 ..##..### 6
 7 #....#..# 7
 This pattern reflects across the horizontal line between rows 4 and 5. Row 1 would reflect with a hypothetical row 8, but since that's not in the pattern, row 1 doesn't need to match anything. The remaining rows match: row 2 matches row 7, row 3 matches row 6, and row 4 matches row 5.

 To summarize your pattern notes, add up the number of columns to the left of each vertical line of reflection; to that, also add 100 multiplied by the number of rows above each horizontal line of reflection. In the above example, the first pattern's vertical line has 5 columns to its left and the second pattern's horizontal line has 4 rows above it, a total of 405.

 Find the line of reflection in each of the patterns in your notes. What number do you get after summarizing all of your notes?
 */
struct Day13Part1: AdventDayPart {
	var data: String

	static var day: Int = 13
	static var part: Int = 1

	func run() async throws {
		let maps: [MirrorMap] = parse(from: data, separator: "\n\n")
		guard maps.count >= 1 else {
			fatalError("Not enough data \(maps)")
		}

		info(maps.map(\.debugDescription).joined(separator: "\n\n"))
		info("------------")
		let summaries = maps.map(\.summary)
		info("Summaries:")
		info(summaries.map(String.init(describing:)).joined(separator: "\n"))
		print("------------")
		let summary = summaries.reduce(0, +)
		print("Summary: \(summary)")
	}

	struct MirrorMap: HasInitFromString, CustomDebugStringConvertible {
		let rows: [[TileType]]
		let bounds: Frame<Int>
		init(_ str: String) {
			rows = str.splitAndTrim(separator: "\n")
				.map({ line in
					let row: [TileType] = line.splitAndTrim(separator: "")
						.compactMap({ TileType(rawValue: $0) })
					return row
				})
			let numCols = (rows.first ?? []).count
			guard rows.allSatisfy({ $0.count == numCols }) else {
				fatalError("ValidationError: MirrorMap non-square:\n \(str)")
			}
			bounds = Frame(width: numCols, height: rows.count)
		}

		var summary: Int {
			// "radius" = half the width
			var mirrorXRadiusSum = 0
			var mirrorYRadiusSum = 0

			for cutIndex in CutIndexIterator(parentRange: bounds.xExclusiveRange) {
				if MirrorCoordinateIterator(frame: bounds, verticalCutIndex: cutIndex)
					.allSatisfy({ (a, b) in
						info("vcut: \(cutIndex) coord: (\(a), \(b))")
						return self[a] == self[b]
					})
				{
					let radius = cutIndex + 1
					mirrorXRadiusSum += radius
				}
			}
			for cutIndex in CutIndexIterator(parentRange: bounds.yExclusiveRange) {
				if MirrorCoordinateIterator(frame: bounds, horizontalCutIndex: cutIndex)
					.allSatisfy({ (a, b) in
						info("hcut: \(cutIndex) coord: (\(a), \(b))")
						return self[a] == self[b]
					})
				{
					let radius = cutIndex + 1
					mirrorYRadiusSum += radius
				}
			}
			// add up the number of columns to the left of each vertical line of reflection; to that,
			// also add 100 multiplied by the number of rows above each horizontal line of reflection.
			return mirrorXRadiusSum + 100 * mirrorYRadiusSum
		}
		subscript(_ coord: Coord2<Int>) -> TileType {
			get {
				return rows[coord.y][coord.x]
			}
		}
		var debugDescription: String {
			return rows.map({ $0.map({ $0.rawValue }).joined() }).joined(separator: "\n")
		}

		enum TileType: String {
			case ash = "."
			case rock = "#"

			mutating func toggle() {
				self =
					switch self {
					case .ash: .rock
					case .rock: .ash
					}
			}
		}
		struct CutIndexIterator: Sequence, IteratorProtocol {
			let parentRange: Range<Int>
			var currIndex: Int
			init(parentRange: Range<Int>) {
				self.parentRange = parentRange
				currIndex = parentRange.lowerBound
			}
			public mutating func next() -> Int? {
				guard currIndex < parentRange.upperBound - 1 else {
					return nil
				}
				let index = currIndex
				currIndex += 1
				return parentRange.lowerBound + index
			}
		}
		struct MirrorCoordinateIterator: Sequence, IteratorProtocol {

			let cutIsVertical: Bool
			let cutIndex: Int
			let frame: Frame<Int>

			var unmirroredCoord: Coord2<Int>

			init(frame: Frame<Int>, cutIsVertical: Bool, cutIndex: Int) {
				self.frame = frame
				unmirroredCoord = frame.origin.coord
				self.cutIsVertical = cutIsVertical
				self.cutIndex = cutIndex
			}
			init(frame: Frame<Int>, verticalCutIndex: Int) {
				self.frame = frame
				unmirroredCoord = frame.origin.coord
				cutIsVertical = true
				cutIndex = verticalCutIndex
			}
			init(frame: Frame<Int>, horizontalCutIndex: Int) {
				self.frame = frame
				unmirroredCoord = frame.origin.coord
				cutIsVertical = false
				cutIndex = horizontalCutIndex
			}
			public mutating func next() -> (Coord2<Int>, Coord2<Int>)? {
				guard frame.exclusiveContains(coord: unmirroredCoord) else {
					return nil
				}
				var next = Self.nextCoord(unmirroredCoord: unmirroredCoord, frame: frame)
				// Repeat loop so we can wrap to next line, skipping the "mirror" coordinates that we're generating directly
				repeat {
					if let resultPrime = Self.mirroredCoord(
						cutIsVertical: cutIsVertical, cutIndex: cutIndex,
						unmirroredCoord: unmirroredCoord, frame: frame)
					{
						let result = unmirroredCoord
						unmirroredCoord = next
						return (result, resultPrime)
					}
					unmirroredCoord = next
					next = Self.nextCoord(unmirroredCoord: unmirroredCoord, frame: frame)
				} while frame.exclusiveContains(coord: next)
				return nil
			}
			static func mirroredCoord(
				cutIsVertical: Bool, cutIndex: Int, unmirroredCoord: Coord2<Int>, frame: Frame<Int>
			) -> Coord2<Int>? {
				let x: Int
				let y: Int
				switch cutIsVertical {
				case true:
					guard unmirroredCoord.x <= cutIndex else {
						return nil
					}
					y = unmirroredCoord.y
					let distanceFromMirror = (cutIndex - unmirroredCoord.x)
					x = cutIndex + distanceFromMirror + 1

				case false:
					guard unmirroredCoord.y <= cutIndex else {
						return nil
					}
					x = unmirroredCoord.x
					let distanceFromMirror = (cutIndex - unmirroredCoord.y)
					y = cutIndex + distanceFromMirror + 1
				}
				if let resultX = frame.safeExclusive(x: x), let resultY = frame.safeExclusive(y: y) {
					return (x: resultX, y: resultY)
				}
				return nil
			}
			/// Just does the calculation, will increment 1-row past bounds
			static func nextCoord(unmirroredCoord: Coord2<Int>, frame: Frame<Int>) -> Coord2<Int> {
				var x: Int? = nil
				var y: Int = unmirroredCoord.y
				x = frame.safeExclusive(x: unmirroredCoord.x + 1)
				if x == nil {
					y += 1
					x = 0
				}
				return (x: x!, y: y)
			}
		}
	}
}

/*
 --- Part Two ---

 You resume walking through the valley of mirrors and - SMACK! - run directly into one. Hopefully nobody was watching, because that must have been pretty embarrassing.

 Upon closer inspection, you discover that every mirror has exactly one smudge: exactly one . or # should be the opposite type.

 In each pattern, you'll need to locate and fix the smudge that causes a different reflection line to be valid. (The old reflection line won't necessarily continue being valid after the smudge is fixed.)

 Here's the above example again:

 #.##..##.
 ..#.##.#.
 ##......#
 ##......#
 ..#.##.#.
 ..##..##.
 #.#.##.#.

 #...##..#
 #....#..#
 ..##..###
 #####.##.
 #####.##.
 ..##..###
 #....#..#
 The first pattern's smudge is in the top-left corner. If the top-left # were instead ., it would have a different, horizontal line of reflection:

 1 ..##..##. 1
 2 ..#.##.#. 2
 3v##......#v3
 4^##......#^4
 5 ..#.##.#. 5
 6 ..##..##. 6
 7 #.#.##.#. 7
 With the smudge in the top-left corner repaired, a new horizontal line of reflection between rows 3 and 4 now exists. Row 7 has no corresponding reflected row and can be ignored, but every other row matches exactly: row 1 matches row 6, row 2 matches row 5, and row 3 matches row 4.

 In the second pattern, the smudge can be fixed by changing the fifth symbol on row 2 from . to #:

 1v#...##..#v1
 2^#...##..#^2
 3 ..##..### 3
 4 #####.##. 4
 5 #####.##. 5
 6 ..##..### 6
 7 #....#..# 7
 Now, the pattern has a different horizontal line of reflection between rows 1 and 2.

 Summarize your notes as before, but instead use the new different reflection lines. In this example, the first pattern's new horizontal line has 3 rows above it and the second pattern's new horizontal line has 1 row above it, summarizing to the value 400.

 In each pattern, fix the smudge and find the different line of reflection. What number do you get after summarizing the new reflection line in each pattern in your notes?
 */
struct Day13Part2: AdventDayPart {
	var data: String

	static var day: Int = 13
	static var part: Int = 2

	func run() async throws {
		let maps: [MirrorMap] = parse(from: data, separator: "\n\n")
		guard maps.count >= 1 else {
			fatalError("Not enough data \(maps)")
		}

		info(maps.map(\.debugDescription).joined(separator: "\n\n"))
		info("------------")
		//		let tMaps = [maps.last!]
		//		let summaries = tMaps.map(\.summary)
		let summaries = maps.map(\.summary)
		info("Summaries:")
		info(summaries.map(String.init(describing:)).joined(separator: "\n"))
		print("------------")
		let summary = summaries.reduce(0, +)
		print("Summary: \(summary)")
	}

	struct MirrorMap: HasInitFromString, CustomDebugStringConvertible {
		let rows: [[TileType]]
		let cols: [[TileType]]
		let bounds: Frame<Int>
		init(_ str: String) {
			rows = str.splitAndTrim(separator: "\n")
				.map({ line in
					let row: [TileType] = line.splitAndTrim(separator: "")
						.compactMap({ TileType(rawValue: $0) })
					return row
				})
			let numCols = (rows.first ?? []).count
			guard rows.allSatisfy({ $0.count == numCols }) else {
				fatalError("ValidationError: MirrorMap non-square:\n \(str)")
			}
			bounds = Frame(width: numCols, height: rows.count)
			// Flip the rows into columns, so we can easily use the same algorithm on both
			cols = Self.mirror(rows)
		}
		var summary: Int {
			// "radius" = half the width
			var mirrorXRadiusSum = 0
			var mirrorYRadiusSum = 0

			let horizInitialCutIndex = Self.findSymmetryIndex(grid: rows)
			let vertInitialCutIndex = Self.findSymmetryIndex(grid: cols)
			if nil == horizInitialCutIndex && nil == vertInitialCutIndex {
				print("MirrorMap malformed?: has no initial symmetry! \(self)")
			}

			for coord in Self.allCoords(for: rows) {
				let nextRows = Self.wipingSmudge(in: rows, at: coord)
				if let newHorizontalSymmetry = Self.findSymmetryIndex(
					grid: nextRows, skipIndex: horizInitialCutIndex ?? -1)
				{
					let radius = newHorizontalSymmetry + 1
					mirrorYRadiusSum += radius

					// Only need to find 1 alternate symmetry!
					break
				}

				let nextCols = Self.mirror(nextRows)
				if let newVerticalSymmetry = Self.findSymmetryIndex(
					grid: nextCols, skipIndex: vertInitialCutIndex ?? -1)
				{
					let radius = newVerticalSymmetry + 1
					mirrorXRadiusSum += radius

					// Only need to find 1 alternate symmetry!
					break
				}
			}
			// add up the number of columns to the left of each vertical line of reflection; to that,
			// also add 100 multiplied by the number of rows above each horizontal line of reflection.
			return mirrorXRadiusSum + 100 * mirrorYRadiusSum
		}

		var debugDescription: String {
			return [Self.describe(grid: rows), Self.describe(grid: cols)].joined(separator: "\nRotated:\n")
				+ "\n===\n"
		}
		static func describe(grid: [[TileType]]) -> String {
			return grid.map({ $0.map({ $0.rawValue }).joined() }).joined(separator: "\n")
		}
		static func printGrid(_ grid: [[TileType]]) {
			print(describe(grid: grid))
		}

		static func wipingSmudge(in grid: [[TileType]], at: Coord2<Int>) -> [[TileType]] {
			var result = grid
			result[at.y][at.x].toggle()
			return result
		}

		/// Symmetry implies two "rows" are identical
		/// This returns the cut index of the next pair of duplicate lines
		static func findNextDuplicateLines(grid: [[TileType]], greaterThanIndex: Int = -1) -> Int? {
			var lastRowIndex = 0
			for nextRowIndex in 1 ..< grid.count {
				guard lastRowIndex > greaterThanIndex else {
					lastRowIndex += 1
					continue
				}
				if grid[lastRowIndex] == grid[nextRowIndex] {
					return lastRowIndex
				}
				lastRowIndex += 1
			}
			return nil
		}
		static func findSymmetryIndex(grid: [[TileType]], skipIndex: Int = -2) -> Int? {
			var candidateIndex = -1
			while candidateIndex < grid.count {
				if candidateIndex == skipIndex {
					candidateIndex += 1
					continue
				}
				let next = findNextDuplicateLines(grid: grid, greaterThanIndex: candidateIndex)
				if next == nil {
					return nil
				} else {
					candidateIndex = next!
					if candidateIndex == skipIndex {
						candidateIndex += 1
						continue
					}
				}
				if isSymmetry(grid: grid, cutIndex: candidateIndex) {
					info("Found Symmetry: \(candidateIndex) for:\n\(describe(grid: grid))")
					return candidateIndex
				}
			}
			return nil
		}
		static func isSymmetry(grid: [[TileType]], cutIndex: Int) -> Bool {
			return mirrorIndices(for: grid, cutIndex: cutIndex)
				.allSatisfy({ (a, b) in
					return grid[a.y][a.x] == grid[b.y][b.x]
				})
		}

		/// Rotates a grid 90 degrees to the left
		static func rotateLeft(_ grid: [[TileType]]) -> [[TileType]] {
			let oldRowCount = grid.count
			let oldColCount = (grid.first ?? []).count
			let newColCount = oldRowCount
			let newRowCount = oldColCount
			let result: [[TileType]] = allCoords(for: grid)
				.reduce(
					into: [],
					{ accum, from in
						let to = Self.rotateLeft(from, rowCount: newRowCount)
						while accum.count <= to.y {
							accum.append(Array(repeating: .ash, count: newColCount))
						}

						accum[to.y][to.x] = grid[from.y][from.x]
					})
			return result
		}
		static func rotateLeft(_ coord: Coord2<Int>, rowCount: Int) -> Coord2<Int> {
			// 0,0 -> 0,R-1-0
			// 1,0 -> 0,R-1-1
			// 0,1 -> 1,R-1-0

			// C-1,0 -> 0,0
			// C-1,1 -> 1,0

			// C-1-1,0 -> 1,1
			return (x: coord.y, y: rowCount - 1 - coord.x)
		}
		/// Rotates a grid 90 degrees to the right
		static func rotateRight(_ grid: [[TileType]]) -> [[TileType]] {
			let oldRowCount = grid.count
			let newColCount = oldRowCount
			let result: [[TileType]] = allCoords(for: grid)
				.reduce(
					into: [],
					{ accum, from in
						let to = Self.rotateRight(from, colCount: newColCount)
						while accum.count <= to.y {
							accum.append(Array(repeating: .ash, count: newColCount))
						}

						accum[to.y][to.x] = grid[from.y][from.x]
					})
			return result
		}
		static func rotateRight(_ coord: Coord2<Int>, colCount: Int) -> Coord2<Int> {
			// 0,0 -> C-1,0
			// 1,0 -> C-1,1

			// 1,1 -> C-1-1,0
			return (x: colCount - 1 - coord.y, y: coord.x)
		}
		/// Diagonally mirroring along the 0,0 -> N,N diagonal
		static func mirror(_ grid: [[TileType]]) -> [[TileType]] {
			let newColCount = grid.count
			let result: [[TileType]] = allCoords(for: grid)
				.reduce(
					into: [],
					{ accum, coord in
						let (x, y) = coord
						while accum.count <= x {
							accum.append(Array(repeating: .ash, count: newColCount))
						}
						accum[x][y] = grid[y][x]
					})
			return result
		}

		static func cutIndices(for grid: [[TileType]]) -> [Int] {
			let width = (grid.first ?? []).count
			return cutIndices(for: 0 ..< (width - 1))
		}
		static func cutIndices(for range: Range<Int>) -> [Int] {
			if let cacheHit = Day13Part2CutIndexCache[range] {
				return cacheHit
			}
			let result = Array(CutIndexIterator(parentRange: range))
			Day13Part2CutIndexCache[range] = result
			return result
		}
		static func mirrorIndices(for frame: Frame<Int>, vertical: Bool, cutIndex: Int)
			-> [MirrorCoordinateIterator.Element]
		{
			let cacheKey = [
				frame.debugDescription, String(describing: vertical), String(describing: cutIndex),
			]
			.joined(separator: "|")
			if let cacheHit = Day13Part2MirrorCoordinateIndexCache[cacheKey] {
				return cacheHit
			}
			let result = Array(
				MirrorCoordinateIterator(frame: frame, cutIsVertical: vertical, cutIndex: cutIndex))
			Day13Part2MirrorCoordinateIndexCache[cacheKey] = result
			return result
		}
		static func mirrorIndices(for grid: [[TileType]], cutIndex: Int) -> [MirrorCoordinateIterator.Element] {
			let width = (grid.first ?? []).count
			let height = grid.count
			return mirrorIndices(
				for: Frame(width: width, height: height), vertical: false, cutIndex: cutIndex)
		}
		static func allCoords(for grid: [[TileType]]) -> [Coord2<Int>] {
			let height = grid.count
			let width = (grid.first ?? []).count
			let cacheKey = "\(width)x\(height)"
			if let cacheHit = Day13Part2AllCoordsCache[cacheKey] {
				return cacheHit
			}
			var result: [Coord2<Int>] = []
			for y in 0 ..< height {
				for x in 0 ..< width {
					result.append((x: x, y: y))
				}
			}
			Day13Part2AllCoordsCache[cacheKey] = result
			return result
		}
	}
	typealias TileType = Day13Part1.MirrorMap.TileType
	typealias CutIndexIterator = Day13Part1.MirrorMap.CutIndexIterator
	typealias MirrorCoordinateIterator = Day13Part1.MirrorMap.MirrorCoordinateIterator
}
var Day13Part2CutIndexCache: [Range<Int>: [Int]] = [:]
var Day13Part2MirrorCoordinateIndexCache: [String: [Day13Part1.MirrorMap.MirrorCoordinateIterator.Element]] = [:]
var Day13Part2AllCoordsCache: [String: [Coord2<Int>]] = [:]
