import Foundation

/*
 --- Day 7: Camel Cards ---

 Your all-expenses-paid trip turns out to be a one-way, five-minute ride in an airship. (At least it's a cool airship!) It drops you off at the edge of a vast desert and descends back to Island Island.

 "Did you bring the parts?"

 You turn around to see an Elf completely covered in white clothing, wearing goggles, and riding a large camel.

 "Did you bring the parts?" she asks again, louder this time. You aren't sure what parts she's looking for; you're here to figure out why the sand stopped.

 "The parts! For the sand, yes! Come with me; I will show you." She beckons you onto the camel.

 After riding a bit across the sands of Desert Island, you can see what look like very large rocks covering half of the horizon. The Elf explains that the rocks are all along the part of Desert Island that is directly above Island Island, making it hard to even get there. Normally, they use big machines to move the rocks and filter the sand, but the machines have broken down because Desert Island recently stopped receiving the parts they need to fix the machines.

 You've already assumed it'll be your job to figure out why the parts stopped when she asks if you can help. You agree automatically.

 Because the journey will take a few days, she offers to teach you the game of Camel Cards. Camel Cards is sort of similar to poker except it's designed to be easier to play while riding a camel.

 In Camel Cards, you get a list of hands, and your goal is to order them based on the strength of each hand. A hand consists of five cards labeled one of A, K, Q, J, T, 9, 8, 7, 6, 5, 4, 3, or 2. The relative strength of each card follows this order, where A is the highest and 2 is the lowest.

 Every hand is exactly one type. From strongest to weakest, they are:

 - Five of a kind, where all five cards have the same label: AAAAA
 - Four of a kind, where four cards have the same label and one card has a different label: AA8AA
 - Full house, where three cards have the same label, and the remaining two cards share a different label: 23332
 - Three of a kind, where three cards have the same label, and the remaining two cards are each different from any other card in the hand: TTT98
 - Two pair, where two cards share one label, two other cards share a second label, and the remaining card has a third label: 23432
 - One pair, where two cards share one label, and the other three cards have a different label from the pair and each other: A23A4
 - High card, where all cards' labels are distinct: 23456
 Hands are primarily ordered based on type; for example, every full house is stronger than any three of a kind.

 If two hands have the same type, a second ordering rule takes effect. Start by comparing the first card in each hand. If these cards are different, the hand with the stronger first card is considered stronger. If the first card in each hand have the same label, however, then move on to considering the second card in each hand. If they differ, the hand with the higher second card wins; otherwise, continue with the third card in each hand, then the fourth, then the fifth.

 So, 33332 and 2AAAA are both four of a kind hands, but 33332 is stronger because its first card is stronger. Similarly, 77888 and 77788 are both a full house, but 77888 is stronger because its third card is stronger (and both hands have the same first and second card).

 To play Camel Cards, you are given a list of hands and their corresponding bid (your puzzle input). For example:

 32T3K 765
 T55J5 684
 KK677 28
 KTJJT 220
 QQQJA 483
 This example shows five hands; each hand is followed by its bid amount. Each hand wins an amount equal to its bid multiplied by its rank, where the weakest hand gets rank 1, the second-weakest hand gets rank 2, and so on up to the strongest hand. Because there are five hands in this example, the strongest hand will have rank 5 and its bid will be multiplied by 5.

 So, the first step is to put the hands in order of strength:

 32T3K is the only one pair and the other hands are all a stronger type, so it gets rank 1.
 KK677 and KTJJT are both two pair. Their first cards both have the same label, but the second card of KK677 is stronger (K vs T), so KTJJT gets rank 2 and KK677 gets rank 3.
 T55J5 and QQQJA are both three of a kind. QQQJA has a stronger first card, so it gets rank 5 and T55J5 gets rank 4.
 Now, you can determine the total winnings of this set of hands by adding up the result of multiplying each hand's bid with its rank (765 * 1 + 220 * 2 + 28 * 3 + 684 * 4 + 483 * 5). So the total winnings in this example are 6440.

 Find the rank of every hand in your set. What are the total winnings?
 */
struct Day07Part1: AdventDayPart {
	var data: String

	static var day: Int = 7
	static var part: Int = 1

	func run() async throws {
		let handSet = HandSet(data)
		let rankBuckets = handSet.updateRanks()
		let sortedBucketKeys = rankBuckets.keys.sorted()
		for handTypeIndex in sortedBucketKeys {
			let bucket = rankBuckets[handTypeIndex]!
			let handTypeName = String(describing: HandType(rawValue: handTypeIndex)!)
			print("\n\(handTypeName) \(bucket.count) entries: \(bucket)")
		}
		print("-------")
		print("\(handSet)")
		print("-------")
		let winnings = handSet.winnings
		print("\(winnings)")
	}
	enum HandType: Int {
		/// High card, where all cards' labels are distinct: 23456
		case highCard = 0
		/// One pair, where two cards share one label, and the other three cards have a different label from the pair and each other: A23A4
		case onePair
		/// Two pair, where two cards share one label, two other cards share a second label, and the remaining card has a third label: 23432
		case twoPair
		/// Three of a kind, where three cards have the same label, and the remaining two cards are each different from any other card in the hand: TTT98
		case threeOfAKind
		/// Full house, where three cards have the same label, and the remaining two cards share a different label: 23332
		case fullHouse
		/// Four of a kind, where four cards have the same label and one card has a different label: AA8AA
		case fourOfAKind
		/// Five of a kind, where all five cards have the same label: AAAAA
		case fiveOfAKind

		static var weakest = HandType.highCard
		static var strongest = HandType.fiveOfAKind
		static var typesInDescendingStrength = ((weakest.rawValue)...(strongest.rawValue)).reversed().map({HandType(rawValue: $0)})

		static func handType(for cardValues: [Int]) -> HandType {
			let cardCounts: [Int: Int] = cardValues.reduce(into: [:], {result, charIndex in
				guard let currentCount = result[charIndex] else {
					result[charIndex] = 1
					return
				}

				result[charIndex] = currentCount + 1
			})
			let sortedCounts = cardCounts.values.sorted()
			let uniqueSymbols = Set(cardValues)

			if uniqueSymbols.count == 1 {
				return .fiveOfAKind
			}
			if uniqueSymbols.count == 2 {
				switch (sortedCounts[0], sortedCounts[1]) {
				case (1, 4):
					return .fourOfAKind
				case (2, 3):
					return .fullHouse
				default:
					fatalError("ValidationError: [2-symbols] handType cannot be determined due to an invalid number of card types \(cardValues)")
				}
			}
			if uniqueSymbols.count == 3 {
				switch (sortedCounts[0], sortedCounts[1], sortedCounts[2]) {
				case (1, 1, 3):
					return .threeOfAKind
				case (1, 2, 2):
					return .twoPair
				default:
					fatalError("ValidationError: [3-symbols] handType cannot be determined due to an invalid number of card types \(cardValues)")
				}
			}
			if uniqueSymbols.count == 4 {
				return .onePair
			}
			if uniqueSymbols.count == 5 {
				return .highCard
			}
			fatalError("ValidationError: 1. handType cannot be determined due to an invalid number of card types \(cardValues)")
		}
	}
	final class HandSet: CustomDebugStringConvertible {
		let hands: [Hand]
		init(_ str: String) {
			hands = parse(from: str, separator: "\n")
		}
		@discardableResult func updateRanks() -> [Int: [Hand]]{
			var buckets: [Int: [Hand]] = hands.reduce(into: [:], {accum, hand in
				let bucketIndex = hand.handType.rawValue
				if accum[bucketIndex] == nil {
					accum[bucketIndex] = []
				}
				accum[hand.handType.rawValue]!.append(hand)
			})

			// Sort every bucket, so hands are in increasing order within their bucket of the same type
			for handTypeIndex in buckets.keys {
				buckets[handTypeIndex]!.sort(by: {a, b in
					return a.cardSortValue < b.cardSortValue
				})
			}

			var nextRank = 1
			for handTypeIndex in buckets.keys.sorted() {
				let bucket = buckets[handTypeIndex]!
				for hand in bucket {
					hand.rank = nextRank
					nextRank += 1
				}
			}
			return buckets
		}
		var winnings: Int {
			return hands.map(\.score).reduce(0, +)
		}
		var debugDescription: String {
			let handStr = hands.map({"\($0)"}).joined(separator:"\n")
			return "Hands:\n\(handStr)"
		}
	}
	final class Hand: CustomDebugStringConvertible, HasInitFromString {

		let cards: String
		let bid: Int
		let handType: HandType

		// Each card converted to an index into cardsInAscendingOrder
		let cardValues: [Int]
		/// For hands of the same handType, this value will distinguish the higher cards from the lower ones
		let cardSortValue: Int

		init(_ str: String) {
			let bits = str.splitAndTrim(separator: " ")
			guard bits.count == 2 else {
				fatalError("ValidationError: Expected a list of cards followed by a number bid! '\(str)'")
			}
			cards = bits[0]
			guard cards.count == 5 && cards.allSatisfy({Self.availableCards.contains($0)}) else {
				fatalError("ValidationError: Broken hand, unexpected card face value \(cards)")
			}
			cardValues = cards.map({Self.cardsInAscendingOrder.firstIndex(of: $0)!})

			// Start by comparing the first card in each hand.
			// If these cards are different, the hand with the stronger first card is considered stronger.
			// If the first card in each hand have the same label, however, then move on to considering the second card in each hand. If they differ, the hand with the higher second card wins; otherwise, continue with the third card in each hand, then the fourth, then the fifth.
			let reversedValues = Array(cardValues.reversed())
			var tmp: Int = 0
			for digit in 0..<cardValues.count {
				let digitValue = reversedValues[digit]
				tmp += Int(pow(Self.cardSortValueDigitMagnitudeChange, Double(digit)) * Double(digitValue))
			}
			cardSortValue = tmp

			guard let tmp = Int(bits[1]) else {
				fatalError("ValidationError: Expected a hand bid, as an integer, but got \(bits[1])")
			}
			bid = tmp
			handType = HandType.handType(for: cardValues)
			rank = -1
		}

		var rank: Int

		var score: Int {
			guard rank > 0 else {
				fatalError("API Misuse: rank needs to be assigned before score can be computed")
			}
			return bid * rank
		}


		var debugDescription: String {
			return "\(cards) \(bid) (\(rank), s: \(cardSortValue))"
		}

		static var cardsInAscendingOrder = Array("AKQJT98765432".reversed())
		static var availableCards = Set(cardsInAscendingOrder)

		/// Because we have 13 card faces, we can't pack them all into a single order of magnitude, we really could do something with base 13,
		///  but it's just easier to use 100 as the scale between the digits, and "waste" some of the range.
		///
		/// Using 10 here would lead to cards sorting in a slightly different order, which would lead to the wrong result on production datasets!
		static var cardSortValueDigitMagnitudeChange: Double = 100
	}
}

