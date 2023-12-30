//
//  Utils.swift
//
//
//  Created by Frederic Barthelemy on 12/5/23.
//

import Foundation

let ENABLE_INFO_LOG = true
func info(_ items: @autoclosure () -> Any, separator: String = " ", terminator: String = "\n") {
	guard ENABLE_INFO_LOG else { return }
	print(items(), separator: separator, terminator: terminator)
}

// MARK: - Parsing
protocol HasInitFromString {
	init(_ str: String)
}
extension String: HasInitFromString {}

func parse<StringType, ValueType>(from str: StringType, separator: String) -> [ValueType]
where StringType: StringProtocol, ValueType: HasInitFromString {
	return str.splitAndTrim(separator: separator).map(ValueType.init)
}
func parse<StringType, ValueType>(from str: StringType, separator: StringType.Element) -> [ValueType]
where StringType: StringProtocol, ValueType: HasInitFromString {
	return str.splitAndTrim(separator: separator).map(ValueType.init)
}
protocol HasFailableInitFromString {
	init?(_ str: String)
}

/// Parses a line of simple types that have a failable init
func parse<StringType, ValueType>(from str: StringType, separator: String) -> [ValueType]
where StringType: StringProtocol, ValueType: HasFailableInitFromString {
	return str.splitAndTrim(separator: separator).compactMap(ValueType.init)
}
/// Parses a line of simple types that have a failable init
func parse<StringType, ValueType>(from str: StringType, separator: StringType.Element) -> [ValueType]
where StringType: StringProtocol, ValueType: HasFailableInitFromString {
	return str.splitAndTrim(separator: separator).compactMap(ValueType.init)
}

extension Int: HasFailableInitFromString {}
extension Float: HasFailableInitFromString {}
extension Double: HasFailableInitFromString {}
extension String: HasFailableInitFromString {}

extension StringProtocol {
	public func splitAndTrim(
		separator: Self.Element, maxSplits: Int = Int.max, omittingEmptySubsequences: Bool = true
	) -> [String] {
		let partialResult = split(separator: separator, maxSplits: maxSplits)
			.map({ $0.trimmingCharacters(in: .whitespaces) })
		if omittingEmptySubsequences {
			return partialResult.filter({ !$0.isEmpty })
		}
		return partialResult
	}
	public func splitAndTrim(separator: String, maxSplits: Int = Int.max, omittingEmptySubsequences: Bool = true)
		-> [String]
	{
		let partialResult = split(separator: separator, maxSplits: maxSplits)
			.map({ $0.trimmingCharacters(in: .whitespaces) })
		if omittingEmptySubsequences {
			return partialResult.filter({ !$0.isEmpty })
		}
		return partialResult
	}

	public func strippingAllNonDigits() -> String {
		return unicodeScalars.filter({ CharacterSet.decimalDigits.contains($0) }).map(String.init).joined()
	}

	public func verifyAndDrop(prefix: String) -> String {
		guard hasPrefix(prefix) else {
			fatalError("ValidationError: Expected Prefix '\(prefix)' was not found in '\(self)'")
		}
		return String(self.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
	}

	var isASCII: Bool {
		return allSatisfy(\.isASCII)
	}
	var asciiValues: [UInt8] { compactMap(\.asciiValue) }
}
extension String {
	func repeated(by count: Int) -> String {
		return String(repeating: self, count: count)
	}
}
// MARK: Arrays & Collections
extension Array {
	mutating func prepend(_ element: Element) {
		self.insert(element, at: 0)
	}
	mutating func popFront() -> Element? {
		let result = first
		self = Array(dropFirst())
		return result
	}
	func prepending(_ element: Element) -> Self {
		var result = self
		result.insert(element, at: 0)
		return result
	}
	func appending(_ element: Element) -> Self {
		var result = self
		result.append(element)
		return result
	}
	func swapping(_ element: Element, at index: Self.Index) -> Self {
		var result = self
		if index != endIndex {
			// Allow swapping to append an item
			result.remove(at: index)
		}
		result.insert(element, at: index)
		return result
	}
	func replacingSubrange<C>(_ subrange: Range<Int>, with newElements: C) -> Self
	where Element == C.Element, C: Collection {
		var result = self
		result.replaceSubrange(subrange, with: newElements)
		return result
	}
}
extension Array where Element: Equatable {
	func countPrefix(of element: Element) -> Int {
		var count = 0
		for el in self {
			if el == element {
				count += 1
			} else {
				return count
			}
		}
		return count
	}
	func countSuffix(of element: Element) -> Int {
		var count = 0
		for el in reversed() {
			if el == element {
				count += 1
			} else {
				return count
			}
		}
		return count
	}
}
// MARK: - Misc
struct ProgressLogger {
	let prefix: String
	/// Powers of 2 might grow too fast for satisfying feedback
	let strideMultiple: Double
	var currentThreshold: Double

	mutating func tick(counter: Int, extra: () -> String = { "" }) {
		tick(counter: Double(counter))
	}
	mutating func tick(counter: Double, extra: () -> String = { "" }) {
		if counter > currentThreshold {
			currentThreshold = currentThreshold * strideMultiple
			print("\(prefix): \(Decimal(counter))\(extra())")
		}
	}
}
struct PercentageFormatter {
	static func format(total: Double, remaining: Double) -> String {
		let completed = total - remaining
		let percentComplete = (completed) / (total) * 100
		return
			"\(String(format:"%.2f%%", percentComplete)) - completed: \(Int(completed)) remaining: \(Int(remaining))"
	}
}

extension ClosedRange<Int> {
	var alternateDescription: String {
		return "\(self)-len: \(count)"
	}
}

extension Slice where Base == ClosedRange<Int> {
	var alternateDescription: String {
		guard !isEmpty else {
			return "<Empty Range>"
		}
		return "\(ClosedRange(self))"
	}
}
extension ClosedRange where Bound: Strideable, Bound.Stride: SignedInteger {
	init(_ slice: Slice<Self>) {
		let lower = slice.base[slice.startIndex]
		let upper = slice.base[slice.index(before: slice.endIndex)]
		self.init(uncheckedBounds: (lower: lower, upper: upper))
	}
}

/// Iterator that wraps around the end if its collection
/// from: https://stackoverflow.com/a/38413254
public struct LoopIterator<Base: Collection>: Sequence, IteratorProtocol {

	private let collection: Base
	public private(set) var index: Base.Index

	public init(collection: Base) {
		self.collection = collection
		self.index = collection.startIndex
	}

	public mutating func next() -> Base.Iterator.Element? {
		guard !collection.isEmpty else {
			return nil
		}

		let result = collection[index]
		collection.formIndex(after: &index)
		if index == collection.endIndex {
			index = collection.startIndex
		}
		return result
	}
}
/// Look at swift-collections library for alternatives
public struct PairingsIterator<Base: Collection>: Sequence, IteratorProtocol {

	private let collection: Base

	private var fromIndex: Base.Index
	private var toIndex: Base.Index

	public private(set) var terminated: Bool = false
	mutating func reset() {
		fromIndex = collection.startIndex
		toIndex = collection.startIndex
		collection.formIndex(after: &toIndex)
		terminated = (collection.isEmpty || toIndex == collection.endIndex)
	}

	public init(collection: Base) {
		self.collection = collection
		fromIndex = collection.startIndex
		toIndex = collection.startIndex
		reset()
	}

	public mutating func next() -> (Base.Iterator.Element, Base.Iterator.Element)? {
		guard !collection.isEmpty && !terminated else {
			return nil
		}

		let from = collection[fromIndex]
		let to = collection[toIndex]

		collection.formIndex(after: &toIndex)
		if toIndex == collection.endIndex {
			collection.formIndex(after: &fromIndex)
			if fromIndex == collection.endIndex {
				terminated = true
			} else {
				toIndex = fromIndex
				collection.formIndex(after: &toIndex)
				if toIndex == collection.endIndex {
					terminated = true
				}
			}
		}
		return (from, to)
	}
}
// MARK: - Math
func leastCommonMultiple<Bound>(numbers nums: [Bound]) -> Bound
where Bound: Comparable, Bound: ExpressibleByIntegerLiteral, Bound: FixedWidthInteger {
	return nums.reduce(1, { accum, b in leastCommonMultiple(a: accum, b: b) })
}
private func greatestCommonDivisor<Bound>(a: Bound, b: Bound) -> Bound
where Bound: Comparable, Bound: ExpressibleByIntegerLiteral, Bound: FixedWidthInteger {  // euclidean algorithm
	if b == 0 {
		return a
	} else {
		return greatestCommonDivisor(a: b, b: a % b)
	}
}

private func leastCommonMultiple<Bound>(a: Bound, b: Bound) -> Bound
where Bound: Comparable, Bound: ExpressibleByIntegerLiteral, Bound: FixedWidthInteger {
	let gcd = greatestCommonDivisor(a: a, b: b)
	return (a * b) / gcd
}

typealias Coord2<Bound> = (x: Bound, y: Bound) where Bound: Comparable, Bound: SignedNumeric, Bound: Equatable
func == <Bound>(_ a: Coord2<Bound>, _ b: Coord2<Bound>) -> Bool
where Bound: Comparable, Bound: SignedNumeric, Bound: Equatable {
	return a.x == b.x && a.y == b.y
}
func == <Bound>(_ a: (Coord2<Bound>, Coord2<Bound>), _ b: (Coord2<Bound>, Coord2<Bound>)) -> Bool
where Bound: Comparable, Bound: SignedNumeric, Bound: Equatable {
	return a.0 == b.0 && a.1 == b.1
}
struct Coord2Box<Bound>: Equatable, CustomDebugStringConvertible
where Bound: Comparable, Bound: SignedNumeric, Bound: Equatable {
	let element: Coord2<Bound>
	init(_ element: Coord2<Bound>) {
		self.element = element
	}
	init?(_ element: Coord2<Bound>?) {
		guard let element = element else { return nil }
		self.element = element
	}
	init(_ tuple: (Bound, Bound)) {
		element = (x: tuple.0, y: tuple.1)
	}
	init?(_ tuple: (Bound, Bound)?) {
		guard let tuple = tuple else { return nil }
		element = (x: tuple.0, y: tuple.1)
	}
	init(_ x: Bound, _ y: Bound) {
		element = (x: x, y: y)
	}
	static func == (lhs: Coord2Box<Bound>, rhs: Coord2Box<Bound>) -> Bool {
		return lhs.element == rhs.element
	}
	var debugDescription: String {
		return "(\(element.x), \(element.y))"
	}
}
struct DuplexCoord2Box<Bound>: Equatable, CustomDebugStringConvertible
where Bound: Comparable, Bound: SignedNumeric, Bound: Equatable {
	let a: Coord2Box<Bound>
	let b: Coord2Box<Bound>

	init(_ a: (Bound, Bound), _ b: (Bound, Bound)) {
		self.a = Coord2Box(a)
		self.b = Coord2Box(b)
	}
	init(_ tuple: (Coord2<Bound>, Coord2<Bound>)) {
		a = Coord2Box(tuple.0)
		b = Coord2Box(tuple.1)
	}
	init(_ tuple: ((Bound, Bound), (Bound, Bound))) {
		a = Coord2Box(tuple.0)
		b = Coord2Box(tuple.1)
	}

	var debugDescription: String {
		return "(\(a), \(b))"
	}
}
struct Path2<Bound> where Bound: Comparable, Bound: SignedNumeric, Bound: Equatable {
	var from: Coord2<Bound>
	var to: Coord2<Bound>

	init(from: Coord2<Bound>, to: Coord2<Bound>) {
		self.from = from
		self.to = to
	}

	init(_ tuple: (Coord2<Bound>, Coord2<Bound>)) {
		from = tuple.0
		to = tuple.1
	}
}

struct Frame<Bound>: CustomDebugStringConvertible, Hashable, Equatable
where Bound: Comparable, Bound: SignedNumeric, Bound: Hashable, Bound: Equatable {
	var origin: Origin
	var size: Size

	init(width: Bound, height: Bound) {
		origin = Origin()
		size = Size(width: width, height: height)
	}
	init() {
		origin = Origin()
		size = Size()
	}

	func inclusiveContains(coord: Coord2<Bound>) -> Bool {
		return origin.x <= coord.x
			&& origin.y <= coord.y
			&& size.inclusiveContains(coord: coord)

	}
	func exclusiveContains(coord: Coord2<Bound>) -> Bool {
		return origin.x <= coord.x
			&& origin.y <= coord.y
			&& size.exclusiveContains(coord: coord)

	}
	mutating func normalize() {
		let oldOrigin = origin
		origin = Origin()
		size.width -= oldOrigin.x
		size.height -= oldOrigin.y
	}
	func normalized() -> Frame<Bound> {
		var result = self
		result.normalize()
		return result
	}
	var xInclusiveRange: ClosedRange<Bound> {
		return origin.x ... size.width
	}
	var yInclusiveRange: ClosedRange<Bound> {
		return origin.y ... size.height
	}
	var xExclusiveRange: Range<Bound> {
		return origin.x ..< size.width
	}
	var yExclusiveRange: Range<Bound> {
		return origin.y ..< size.height
	}
	var debugDescription: String {
		return "[o: \(origin), s: \(size)]"
	}
	func safeInclusive(x: Bound) -> Bound? {
		guard xInclusiveRange.contains(x) else {
			return nil
		}
		return x
	}
	func safeInclusive(y: Bound) -> Bound? {
		guard yInclusiveRange.contains(y) else {
			return nil
		}
		return y
	}
	func safeInclusive(coord: Coord2<Bound>) -> Coord2<Bound>? {
		guard xInclusiveRange.contains(coord.x) else {
			return nil
		}
		guard yInclusiveRange.contains(coord.y) else {
			return nil
		}
		return coord
	}
	func safeExclusive(x: Bound) -> Bound? {
		guard xExclusiveRange.contains(x) else {
			return nil
		}
		return x
	}
	func safeExclusive(y: Bound) -> Bound? {
		guard yExclusiveRange.contains(y) else {
			return nil
		}
		return y
	}
	func safeExclusive(coord: Coord2<Bound>) -> Coord2<Bound>? {
		guard xExclusiveRange.contains(coord.x) else {
			return nil
		}
		guard yExclusiveRange.contains(coord.y) else {
			return nil
		}
		return coord
	}

	struct Origin: CustomDebugStringConvertible, Hashable, Equatable {
		var x: Bound
		var y: Bound

		init(x: Bound = 0, y: Bound = 0) {
			self.x = x
			self.y = y
		}

		var debugDescription: String {
			return "(\(x), \(y))"
		}

		var coord: Coord2<Bound> {
			return (x: x, y: y)
		}
	}
	struct Size: CustomDebugStringConvertible, Hashable, Equatable {
		var width: Bound
		var height: Bound

		init(width: Bound = 0, height: Bound = 0) {
			self.width = width
			self.height = height
		}

		fileprivate func inclusiveContains(coord: Coord2<Bound>) -> Bool {
			return width >= coord.x && height >= coord.y
		}
		fileprivate func exclusiveContains(coord: Coord2<Bound>) -> Bool {
			return width > coord.x && height > coord.y
		}

		var debugDescription: String {
			return "(\(width), \(height))"
		}
		var coord: Coord2<Bound> {
			return (x: width, y: height)
		}
	}
}
// MARK: - Grids
struct Grid<Element>: CustomDebugStringConvertible {
	enum Direction: String {
		case north, south, east, west
	}
	var frame: Frame<Int>
	var rows: [[Element]]
	init(frame: Frame<Int>, rows: [[Element]]) {
		self.frame = frame
		self.rows = rows
	}
	init(rows: [[Element]]) {
		let rowCount = rows.count
		let colCount = (rows.first ?? []).count
		frame = Frame(width: colCount, height: rowCount)
		self.rows = rows
	}
	func contains(coord: Coord2<Int>) -> Bool {
		return frame.exclusiveContains(coord: coord)
	}
	var rowCount: Int {
		return frame.size.height
	}
	var colCount: Int {
		return frame.size.width
	}
	subscript(coord: Coord2<Int>) -> Element {
		get {
			guard contains(coord: coord) else {
				fatalError("Grid: Out-of-bounds read: \(coord)")
			}
			return rows[coord.y][coord.x]
		}
		set(newValue) {
			guard contains(coord: coord) else {
				fatalError("Grid: Out-of-bounds write: \(coord)")
			}
			rows[coord.y][coord.x] = newValue
		}
	}
	func shift(_ coord: Coord2<Int>, toThe direction: Direction, by distance: Int = 1) -> Coord2<Int>? {
		// Coord can be just outside the map, so don't validate it!

		var result: Coord2<Int> = coord
		switch direction {
		case .north:
			result.y -= distance
		case .south:
			result.y += distance
		case .east:
			result.x += distance
		case .west:
			result.x -= distance
		}
		guard frame.exclusiveContains(coord: result) else {
			return nil
		}
		return result
	}
	var debugDescription: String {
		return "{\(frame)}\n\(Self.describe(grid:rows))"
	}
	static func describe(grid: [[Element]]) -> String {
		return grid.map({ $0.map(String.init(describing:)).joined() }).joined(separator: "\n")
	}
	static func printGrid(_ grid: [[Element]]) {
		print(describe(grid: grid))
	}
}
extension Grid: HasInitFromString where Element: HasInitFromString {
	init(_ str: String) {
		let rows = str.splitAndTrim(separator: "\n")
			.map({ rowStr in
				let row: [Element] = rowStr.split(separator: "").map(String.init)
					.map({ elStr in
						return Element(elStr)
					})
				return row
			})
		self.init(rows: rows)
	}
}
extension Grid: HasFailableInitFromString where Element: HasFailableInitFromString {
	init?(_ str: String) {
		let candidateRows: [[Element?]] = str.splitAndTrim(separator: "\n")
			.map({ parse(from: $0, separator: "") })
		var cleanRows: [[Element]] = []
		for row in candidateRows {
			let cleanRow = Array(row.compacted())
			guard row.count == cleanRow.count else {
				info("Probably unexpected nil in \(row) for:\n\(str)")
				return nil
			}
			cleanRows.append(cleanRow)
		}
		self.init(rows: cleanRows)
	}
}
extension Grid: Equatable where Element: Equatable {

}
extension Grid: Hashable where Element: Hashable {

}

// MARK: - Caching
protocol CacheBasics where KeyType: Hashable {
	associatedtype KeyType
	associatedtype ValueType
	var cache: [KeyType: ValueType] { get set }
	subscript(_ key: KeyType) -> ValueType? { get set }
}
extension CacheBasics {
	subscript(_ key: KeyType) -> ValueType? {
		get {
			return cache[key]
		}
		set(newValue) {
			cache[key] = newValue
		}
	}
}
struct Cache<KeyType, ValueType>: CacheBasics where KeyType: Hashable {
	var cache: [KeyType: ValueType] = [:]

	/// Lazily generates & stores the value if it's not present!
	mutating func lookup(_ what: KeyType, _ generator: () -> ValueType) -> ValueType {
		guard let value = self[what] else {
			let result = generator()
			self[what] = result
			return result
		}
		return value
	}
}
protocol SelfKeyingCache: CacheBasics {
	var keyer: (_: ValueType) -> KeyType { get }
}
protocol PreloadableCache {
	associatedtype KeyType
	associatedtype ValueType

	mutating func insert(key: KeyType, value: ValueType)
}
extension PreloadableCache where Self: SelfKeyingCache {
	mutating func insert(_ what: ValueType) {
		cache[keyer(what)] = what
	}
}

extension Grid {
	func allCoords() -> [Coord2<Int>] {
		let height = rows.count
		let width = (rows.first ?? []).count
		let cacheKey = "\(width)x\(height)"

		return allCoordsCache.lookup(cacheKey) {
			var result: [Coord2<Int>] = []
			for y in frame.origin.y ..< height {
				for x in frame.origin.x ..< width {
					result.append((x: x, y: y))
				}
			}
			return result
		}
	}
}
private var allCoordsCache: Cache<String, [Coord2<Int>]> = Cache()
