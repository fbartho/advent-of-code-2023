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
		let partialResult = split(separator: separator).map({ $0.trimmingCharacters(in: .whitespaces) })
		if omittingEmptySubsequences {
			return partialResult.filter({ !$0.isEmpty })
		}
		return partialResult
	}
	public func splitAndTrim(separator: String, maxSplits: Int = Int.max, omittingEmptySubsequences: Bool = true)
		-> [String]
	{
		let partialResult = split(separator: separator).map({ $0.trimmingCharacters(in: .whitespaces) })
		if omittingEmptySubsequences {
			return partialResult.filter({ !$0.isEmpty })
		}
		return partialResult
	}
}
