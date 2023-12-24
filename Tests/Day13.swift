import XCTest

@testable import AdventOfCode


final class Day13Tests: XCTestCase {
	typealias MirrorMap = Day13Part1.MirrorMap
	typealias CutIndexIterator = MirrorMap.CutIndexIterator
	typealias MirrorCoordinateIterator = MirrorMap.MirrorCoordinateIterator
	/// description-string for
	func d<T>(_ what: T) -> String {
		return String(describing: what)
	}
	/// Sequence to array, short
	func a<T, E>(_ what: T) -> [E] where T: Sequence, T.Element == E {
		return Array(what)
	}
	func testCutIndexIterator() {
		XCTAssertEqual(a(CutIndexIterator(parentRange: 0..<2)), [0])
		XCTAssertEqual(a(CutIndexIterator(parentRange: 0..<4)), [0,1,2])
	}
	func testMirrorCoordinateIterator1() {
		XCTAssertEqual(nil, Coord2Box(MirrorCoordinateIterator.mirroredCoord(cutIsVertical: true,
																			 cutIndex: 0,
																			 unmirroredCoord: (x: 0, y: 0),
																			 frame: Frame(width: 0, height: 0))))
		XCTAssertEqual(Coord2Box(1, 0),
					   Coord2Box(MirrorCoordinateIterator.mirroredCoord(cutIsVertical: true,
																		cutIndex: 0,
																		unmirroredCoord: (x: 0, y: 0),
																		frame: Frame(width: 2, height: 1))!))
		/// *.|.?
		XCTAssertEqual(Coord2Box(3, 0),
					   Coord2Box(MirrorCoordinateIterator.mirroredCoord(cutIsVertical: true,
																		cutIndex: 1,
																		unmirroredCoord: (x: 0, y: 0),
																		frame: Frame(width: 4, height: 1))!))

		typealias P = DuplexCoord2Box<Int>
		XCTAssertEqual(
			[
				P((0, 0),(1, 0)),
			],
			a(MirrorCoordinateIterator(frame: Frame(width: 2, height: 1),
									   verticalCutIndex: 0).map({DuplexCoord2Box($0)}))
		)
	}
	func testMirrorCoordinateIterator2() {
		typealias P = DuplexCoord2Box<Int>

		XCTAssertEqual(
			[
				P((0, 0),(3, 0)),
				P((1, 0),(2, 0)),
			],
			a(MirrorCoordinateIterator(frame: Frame(width: 4, height: 1),
									   verticalCutIndex: 1).map({DuplexCoord2Box($0)}))
		)
	}
}
