import Foundation

/*
 --- Day 16: The Floor Will Be Lava ---

 With the beam of light completely focused somewhere, the reindeer leads you deeper still into the Lava Production Facility. At some point, you realize that the steel facility walls have been replaced with cave, and the doorways are just cave, and the floor is cave, and you're pretty sure this is actually just a giant cave.

 Finally, as you approach what must be the heart of the mountain, you see a bright light in a cavern up ahead. There, you discover that the beam of light you so carefully focused is emerging from the cavern wall closest to the facility and pouring all of its energy into a contraption on the opposite side.

 Upon closer inspection, the contraption appears to be a flat, two-dimensional square grid containing empty space (.), mirrors (/ and \), and splitters (| and -).

 The contraption is aligned so that most of the beam bounces around the grid, but each tile on the grid converts some of the beam's light into heat to melt the rock in the cavern.

 You note the layout of the contraption (your puzzle input). For example:

 .|...\....
 |.-.\.....
 .....|-...
 ........|.
 ..........
 .........\
 ..../.\\..
 .-.-/..|..
 .|....-|.\
 ..//.|....
 The beam enters in the top-left corner from the left and heading to the right. Then, its behavior depends on what it encounters as it moves:

 If the beam encounters empty space (.), it continues in the same direction.
 If the beam encounters a mirror (/ or \), the beam is reflected 90 degrees depending on the angle of the mirror. For instance, a rightward-moving beam that encounters a / mirror would continue upward in the mirror's column, while a rightward-moving beam that encounters a \ mirror would continue downward from the mirror's column.
 If the beam encounters the pointy end of a splitter (| or -), the beam passes through the splitter as if the splitter were empty space. For instance, a rightward-moving beam that encounters a - splitter would continue in the same direction.
 If the beam encounters the flat side of a splitter (| or -), the beam is split into two beams going in each of the two directions the splitter's pointy ends are pointing. For instance, a rightward-moving beam that encounters a | splitter would split into two beams: one that continues upward from the splitter's column and one that continues downward from the splitter's column.
 Beams do not interact with other beams; a tile can have many beams passing through it at the same time. A tile is energized if that tile has at least one beam pass through it, reflect in it, or split in it.

 In the above example, here is how the beam of light bounces around the contraption:

 >|<<<\....
 |v-.\^....
 .v...|->>>
 .v...v^.|.
 .v...v^...
 .v...v^..\
 .v../2\\..
 <->-/vv|..
 .|<<<2-|.\
 .v//.|.v..
 Beams are only shown on empty tiles; arrows indicate the direction of the beams. If a tile contains beams moving in multiple directions, the number of distinct directions is shown instead. Here is the same diagram but instead only showing whether a tile is energized (#) or not (.):

 ######....
 .#...#....
 .#...#####
 .#...##...
 .#...##...
 .#...##...
 .#..####..
 ########..
 .#######..
 .#...#.#..
 Ultimately, in this example, 46 tiles become energized.

 The light isn't energizing enough tiles to produce lava; to debug the contraption, you need to start by analyzing the current situation. With the beam starting in the top-left heading right, how many tiles end up being energized?
 */
struct Day16Part1: AdventDayPart {
	var data: String

	static var day: Int = 16
	static var part: Int = 1

	func run() async throws {
		var chart = LaserMap(data)
		print(chart)
		print("--------")
		let visitMap = chart.energizeTheBeam()
		print("VisitMap: \(visitMap)")
		print("--------")
		print("Energized Tile Count \(LaserMap.energizedTileCount(visitMap: visitMap))")
	}

	struct LaserMap: HasInitFromString, CustomDebugStringConvertible {
		init(_ str: String) {
			grid = Grid(str)
		}

		let grid: Grid<MirrorTile>

		static func energizedTileCount(visitMap: Grid<VisitTile>) -> Int {
			let allTiles: [VisitTile] = Array(visitMap.rows.joined())
			let energizedTiles = allTiles.filter({tile in
				return VisitTile.unvisited != tile
			})
			return energizedTiles.count
		}

		typealias Direction = Grid<VisitTile>.Direction
		typealias BeamHead = (traveling: Direction, head: Coord2<Int>)

		mutating func energizeTheBeam(_ startingBeamHead: BeamHead = (traveling: .east, head: (x: -1, y: 0))) -> Grid<VisitTile> {
			// Clone it with a blank map
			var visitMap: Grid<VisitTile> = Grid(rows: grid.rows.map({row in
				return row.map({_ in .unvisited})
			}))

			var beamHeads: [BeamHead] = [startingBeamHead]
			while let beam = beamHeads.popFront() {
				// - beam.head is already marked as visited
				// - nextLoc gets marked as visited this loop
				guard let nextLoc = visitMap.shift(beam.head, toThe: beam.traveling) else {
					// Beam stepped off the map, so let it be dropped!
					continue
				}
				var newDirection = beam.traveling

				if visitMap[nextLoc] == .unvisited {
					visitMap[nextLoc] = .beamDirections([])
				}
				// not else-if
				if case .beamDirections(let currentDirections) = visitMap[nextLoc] {
					if currentDirections.contains(beam.traveling) {
						// We landed on a path that another beam is following, so our beam is redundant
						// (our current beam drops on 'continue')
						continue
					}
					visitMap[nextLoc] = .beamDirections(currentDirections.appending(beam.traveling))

					let base = grid[nextLoc]
					switch base {
					case .empty:
						beamHeads.append((traveling: newDirection, head: nextLoc))

					case .forwardSlash:
						newDirection = switch beam.traveling {
						case .north: .east
						case .south: .west
						case .east: .north
						case .west: .south
						}
						beamHeads.append((traveling: newDirection, head: nextLoc))

					case .backSlash:
						newDirection = switch beam.traveling {
						case .north: .west
						case .south: .east
						case .east: .south
						case .west: .north
						}
						beamHeads.append((traveling: newDirection, head: nextLoc))

					case .horiz:
						// Need to split two directions if you hit a splitter side-on
						let newDirections: [Direction] = switch beam.traveling {
						case .north, .south: [.east, .west]
						case .east: [.east]
						case .west: [.west]
						}
						beamHeads.append(contentsOf: newDirections.map({dir in
							return (traveling: dir, head: nextLoc)
						}))

					case .vert:
						// Need to split two directions if you hit a splitter side-on
						let newDirections: [Direction] = switch beam.traveling {
						case .north: [.north]
						case .south: [.south]
						case .east, .west: [.north, .south]
						}
						beamHeads.append(contentsOf: newDirections.map({dir in
							return (traveling: dir, head: nextLoc)
						}))
					}
				}
			}
			return visitMap
		}

		var debugDescription: String {
			return "\(grid)"
		}

		enum MirrorTile: Character, HasInitFromString, CustomDebugStringConvertible {
			case empty = "."
			case forwardSlash = "/"
			case backSlash = "\\"
			case horiz = "-"
			case vert = "|"
			var isMirror: Bool {
				return switch self {
				case .empty: false
				default: true
				}
			}
			init(_ str: String) {
				self.init(rawValue: str.first!)!
			}
			var debugDescription: String {
				return "\(rawValue)"
			}
		}
		enum VisitTile: Equatable, CustomDebugStringConvertible {
			case unvisited
			case beamDirections([Direction])

			var debugDescription: String {
				return switch self {
				case .unvisited: "."
				case .beamDirections(_): "#"
				}
			}
		}
	}
}

