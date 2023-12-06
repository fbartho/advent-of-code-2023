//
//  Utils.swift
//
//
//  Created by Frederic Barthelemy on 12/5/23.
//

import Foundation

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

	public func verifyAndDrop(prefix: String) -> String {
		guard hasPrefix(prefix) else {
			fatalError("ValidationError: Expected Prefix '\(prefix)' was not found in '\(self)'")
		}
		return String(self.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
	}
}

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
