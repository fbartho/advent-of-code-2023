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
			rows = str.splitAndTrim(separator: "\n").map({line in
				let row: [TileType] = line.splitAndTrim(separator: "").compactMap({TileType(rawValue: $0)})
				return row
			})
			let numCols = (rows.first ?? []).count
			guard rows.allSatisfy({$0.count == numCols}) else {
				fatalError("ValidationError: MirrorMap non-square:\n \(str)")
			}
			bounds = Frame(width: numCols, height: rows.count)
		}

		var summary: Int {
			// "radius" = half the width
			var mirrorXRadiusSum = 0
			var mirrorYRadiusSum = 0

			for cutIndex in CutIndexIterator(parentRange: bounds.xExclusiveRange) {
				if MirrorCoordinateIterator(frame: bounds, verticalCutIndex: cutIndex).allSatisfy({(a, b) in
					info("vcut: \(cutIndex) coord: (\(a), \(b))")
					return self[a] == self[b]
				}) {
					let radius = cutIndex + 1
					mirrorXRadiusSum += radius
				}
			}
			for cutIndex in CutIndexIterator(parentRange: bounds.yExclusiveRange) {
				if MirrorCoordinateIterator(frame: bounds, horizontalCutIndex: cutIndex).allSatisfy({(a, b) in
					info("hcut: \(cutIndex) coord: (\(a), \(b))")
					return self[a] == self[b]
				}) {
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
			return rows.map({$0.map({$0.rawValue}).joined()}).joined(separator: "\n")
		}
		enum TileType: String {
			case ash = "."
			case rock = "#"
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
					if let resultPrime = Self.mirroredCoord(cutIsVertical: cutIsVertical, cutIndex: cutIndex, unmirroredCoord: unmirroredCoord, frame: frame) {
						let result = unmirroredCoord
						unmirroredCoord = next
						return (result, resultPrime)
					}
					unmirroredCoord = next
					next = Self.nextCoord(unmirroredCoord: unmirroredCoord, frame: frame)
				} while frame.exclusiveContains(coord: next)
				return nil
			}
			static func mirroredCoord(cutIsVertical: Bool, cutIndex: Int, unmirroredCoord: Coord2<Int>, frame: Frame<Int>) -> Coord2<Int>? {
				let x: Int
				let y: Int
				switch cutIsVertical {
				case true:
					guard unmirroredCoord.x <= cutIndex else {
						return nil
					}
					y = unmirroredCoord.y
					let distanceFromMirror = (cutIndex - unmirroredCoord.x)
					x =  cutIndex + distanceFromMirror + 1

				case false:
					guard unmirroredCoord.y <= cutIndex else {
						return nil
					}
					x = unmirroredCoord.x
					let distanceFromMirror = (cutIndex - unmirroredCoord.y)
					y =  cutIndex + distanceFromMirror + 1
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
