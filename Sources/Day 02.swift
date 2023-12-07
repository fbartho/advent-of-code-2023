/*
 --- Day 2: Cube Conundrum ---

 You're launched high into the atmosphere! The apex of your trajectory just barely reaches the surface of a large island floating in the sky. You gently land in a fluffy pile of leaves. It's quite cold, but you don't see much snow. An Elf runs over to greet you.

 The Elf explains that you've arrived at Snow Island and apologizes for the lack of snow. He'll be happy to explain the situation, but it's a bit of a walk, so you have some time. They don't get many visitors up here; would you like to play a game in the meantime?

 As you walk, the Elf shows you a small bag and some cubes which are either red, green, or blue. Each time you play this game, he will hide a secret number of cubes of each color in the bag, and your goal is to figure out information about the number of cubes.

 To get information, once a bag has been loaded with cubes, the Elf will reach into the bag, grab a handful of random cubes, show them to you, and then put them back in the bag. He'll do this a few times per game.

 You play several games and record the information from each game (your puzzle input). Each game is listed with its ID number (like the 11 in Game 11: ...) followed by a semicolon-separated list of subsets of cubes that were revealed from the bag (like 3 red, 5 green, 4 blue).

 For example, the record of a few games might look like this:

 Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
 Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
 Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
 Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
 Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
 In game 1, three sets of cubes are revealed from the bag (and then put back again). The first set is 3 blue cubes and 4 red cubes; the second set is 1 red cube, 2 green cubes, and 6 blue cubes; the third set is only 2 green cubes.

 The Elf would first like to know which games would have been possible if the bag contained only 12 red cubes, 13 green cubes, and 14 blue cubes?

 In the example above, games 1, 2, and 5 would have been possible if the bag had been loaded with that configuration. However, game 3 would have been impossible because at one point the Elf showed you 20 red cubes at once; similarly, game 4 would also have been impossible because the Elf showed you 15 blue cubes at once. If you add up the IDs of the games that would have been possible, you get 8.

 Determine which games would have been possible if the bag had been loaded with only 12 red cubes, 13 green cubes, and 14 blue cubes. What is the sum of the IDs of those games?
 */
struct Day02Part1: AdventDayPart {
	var data: String

	static var day: Int = 2
	static var part: Int = 1

	func run() async throws {
		let lines = data.splitAndTrim(separator: "\n")
		guard lines.count >= 2 else {
			fatalError("No GameBag description + Games \(lines)")
		}
		let initialStateString = lines[0]

		let gameBagBits = initialStateString.splitAndTrim(separator: ":")
		guard gameBagBits.count >= 2 else {
			fatalError("Initial state string broken - \(gameBagBits)")
		}
		let availableBlocksString = gameBagBits[1]
		let gameBag = Game.parseGameBoard(state: availableBlocksString)

		let games = lines[1...].map { Game(result: $0) }
		print("Games:\n\(games.map(\.debugDescription).joined(separator:"\n"))")

		let possibleGameIds: [Int] = games.filter({ $0.isPossibleGame(for: gameBag) })
			.map(\.id)

		let sumOfPossibleGameIds = possibleGameIds.reduce(0, +)
		print("Sum: \(sumOfPossibleGameIds)")
	}

	typealias SingleColorPlucking = (num: Int, color: String)
	typealias Move = [SingleColorPlucking]
	/// Colors to Number
	typealias GameBag = [String: Int]
	struct Game: CustomDebugStringConvertible {
		let id: Int
		let moves: [Move]

		init(result: String) {
			let chunks = Array(result.split(separator: ":"))
			guard chunks.count == 2 else {
				fatalError("Missing ID or Results for '\(result)'")
			}
			let idChunks = Array(chunks[0].split(separator: " "))
			guard idChunks.count == 2 else {
				fatalError(
					"Missing ID, expected Number for '\(result)', but got \(idChunks)"
				)
			}
			guard let idTmp = Int(idChunks[1]) else {
				fatalError(
					"Could not parse ID: expected Number for '\(result)', but got \(idChunks)"
				)
			}
			id = idTmp

			let moveChunks = Array(chunks[1].split(separator: ";"))
			guard moveChunks.count > 0 else {
				fatalError(
					"Expected at least one plucking to describe a game for '\(result)'"
				)
			}
			moves = moveChunks.map { move in
				let pluckingChunks = move.splitAndTrim(separator: ",")
				guard pluckingChunks.count > 0 else {
					fatalError(
						"Expected at least one visible cube in a plucking for '\(move)' from '\(result)'"
					)
				}
				return pluckingChunks.map { plucking in
					return Self.parseCubeCount(
						plucking, move: move, origin: result)
				}
			}
		}
		var debugDescription: String {
			let joinedMoves =
				moves.map({ pluckings in
					pluckings
						.map({ "\($0.num) \($0.color)" })
						.joined(separator: ", ")
				})
				.joined(separator: "; ")

			return "Game \(id): \(joinedMoves)"
		}

		static func isPluckingPossible(
			_ plucking: SingleColorPlucking, for gameBag: GameBag
		) -> Bool {
			guard let gameBagAvailableForColor = gameBag[plucking.color] else {
				return false
			}
			return plucking.num <= gameBagAvailableForColor
		}
		func isPossibleGame(for gameBag: GameBag) -> Bool {
			return moves.joined()
				.allSatisfy({ plucking in
					return Self.isPluckingPossible(plucking, for: gameBag)
				})
		}
		static func parseCubeCount(
			_ str: some StringProtocol, move: some StringProtocol,
			origin: some StringProtocol
		) -> SingleColorPlucking {
			let moveColorDescription = str.splitAndTrim(separator: " ")
			guard moveColorDescription.count == 2 else {
				fatalError(
					"Invalid count/color description '\(str) from '\(move)' from '\(origin)' - wrong number of bits."
				)
			}
			let itemNum = Int(moveColorDescription[0]) ?? -1
			guard itemNum >= 0 else {
				fatalError(
					"Incorrectly parsed item count as '\(itemNum)' for '\(move)' from '\(origin)' - No negative cube counts!"
				)
			}
			return (num: itemNum, color: String(moveColorDescription[1]))
		}
		static func parseGameBoard(state: some StringProtocol) -> GameBag {
			var bag: GameBag = [:]
			let cubeStrs =
				state.splitAndTrim(separator: ",")
			for cubeStr in cubeStrs {
				let parsed = Self.parseCubeCount(
					cubeStr, move: state, origin: "GameBag")
				bag[parsed.color] = parsed.num
			}
			return bag
		}
	}
}
/*
 --- Part Two ---

 The Elf says they've stopped producing snow because they aren't getting any water! He isn't sure why the water stopped; however, he can show you how to get to the water source to check it out for yourself. It's just up ahead!

 As you continue your walk, the Elf poses a second question: in each game you played, what is the fewest number of cubes of each color that could have been in the bag to make the game possible?

 Again consider the example games from earlier:

 Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
 Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
 Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
 Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
 Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
 In game 1, the game could have been played with as few as 4 red, 2 green, and 6 blue cubes. If any color had even one fewer cube, the game would have been impossible.
 Game 2 could have been played with a minimum of 1 red, 3 green, and 4 blue cubes.
 Game 3 must have been played with at least 20 red, 13 green, and 6 blue cubes.
 Game 4 required at least 14 red, 3 green, and 15 blue cubes.
 Game 5 needed no fewer than 6 red, 3 green, and 2 blue cubes in the bag.
 The power of a set of cubes is equal to the numbers of red, green, and blue cubes multiplied together. The power of the minimum set of cubes in game 1 is 48. In games 2-5 it was 12, 1560, 630, and 36, respectively. Adding up these five powers produces the sum 2286.

 For each game, find the minimum set of cubes that must have been present. What is the sum of the power of these sets?
 */
struct Day02Part2: AdventDayPart {
	var data: String

	static var day: Int = 2
	static var part: Int = 2

	func run() async throws {
		let lines =
			data.splitAndTrim(separator: "\n")
		guard lines.count >= 1 else {
			fatalError("Not enough Games \(lines)")
		}

		let games = lines.map { Game(result: $0) }
		print("Games:\n\(games.map(\.debugDescription).joined(separator:"\n"))")

		let minimumBags = Array(games.map(\.minimumGameBag))
		let bagPowers = Array(minimumBags.map({ Game.gameBagPower($0) }))
		print("GamePowers \(bagPowers)")

		let sumOfPowers = bagPowers.reduce(0, +)
		print("Sum: \(sumOfPowers)")
	}

	typealias SingleColorPlucking = (num: Int, color: String)
	typealias Move = [SingleColorPlucking]
	/// Colors to Number
	typealias GameBag = [String: Int]
	struct Game: CustomDebugStringConvertible {
		let id: Int
		let moves: [Move]

		init(result: String) {
			let chunks = Array(result.split(separator: ":"))
			guard chunks.count == 2 else {
				fatalError("Missing ID or Results for '\(result)'")
			}
			let idChunks = Array(chunks[0].split(separator: " "))
			guard idChunks.count == 2 else {
				fatalError(
					"Missing ID, expected Number for '\(result)', but got \(idChunks)"
				)
			}
			guard let idTmp = Int(idChunks[1]) else {
				fatalError(
					"Could not parse ID: expected Number for '\(result)', but got \(idChunks)"
				)
			}
			id = idTmp

			let moveChunks = Array(chunks[1].split(separator: ";"))
			guard moveChunks.count > 0 else {
				fatalError(
					"Expected at least one plucking to describe a game for '\(result)'"
				)
			}
			moves = moveChunks.map { move in
				let pluckingChunks =
					move.splitAndTrim(separator: ",")
				guard pluckingChunks.count > 0 else {
					fatalError(
						"Expected at least one visible cube in a plucking for '\(move)' from '\(result)'"
					)
				}
				return pluckingChunks.map {
					Self.parseCubeCount($0, move: move, origin: result)
				}
			}
		}
		var debugDescription: String {
			let joinedMoves =
				moves.map({ pluckings in
					pluckings
						.map({ "\($0.num) \($0.color)" })
						.joined(separator: ", ")
				})
				.joined(separator: "; ")

			return "Game \(id): \(joinedMoves)"
		}

		static func parseCubeCount(
			_ str: some StringProtocol, move: some StringProtocol,
			origin: some StringProtocol
		) -> SingleColorPlucking {
			let moveColorDescription = str.splitAndTrim(separator: " ")
			guard moveColorDescription.count == 2 else {
				fatalError(
					"Invalid count/color description '\(str) from '\(move)' from '\(origin)' - wrong number of bits."
				)
			}
			let itemNum = Int(moveColorDescription[0]) ?? -1
			guard itemNum >= 0 else {
				fatalError(
					"Incorrectly parsed item count as '\(itemNum)' for '\(move)' from '\(origin)' - No negative cube counts!"
				)
			}
			return (num: itemNum, color: String(moveColorDescription[1]))
		}
		static func parseGameBoard(state: some StringProtocol) -> GameBag {
			var bag: GameBag = [:]
			let cubeStrs = state.splitAndTrim(separator: ",")
			for cubeStr in cubeStrs {
				let parsed = Self.parseCubeCount(
					cubeStr, move: state, origin: "GameBag")
				bag[parsed.color] = parsed.num
			}
			return bag
		}
		var minimumGameBag: GameBag {
			var minBag: GameBag = [:]
			for event in moves.joined() {
				minBag[event.color] = max(event.num, minBag[event.color] ?? 0)
			}
			return minBag
		}
		/**
		 The power of a set of cubes is equal to the numbers of red, green, and blue cubes multiplied together.
		 */
		static func gameBagPower(_ bag: GameBag) -> Int {
			let red = bag["red"] ?? 0
			let green = bag["green"] ?? 0
			let blue = bag["blue"] ?? 0
			return red * green * blue
		}
	}
}
