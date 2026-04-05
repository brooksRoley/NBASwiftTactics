import Foundation

enum RoundType {
    case standard5v5
    case playground3v3
    case horseMinigame
    case draftLottery
}

class GameState {
    var currentSeason: Int = 1
    var currentRound: Int = 1
    var teamWins: Int = 0
    var teamLosses: Int = 0
    var currentCapSpace: Int = GameState.salaryCap

    static let salaryCap = 136_000_000
    static let salaryFloor = 122_000_000

    func determineNextRound() -> RoundType {
        if currentRound % 5 == 0 { return .playground3v3 }
        if currentRound % 7 == 0 { return .draftLottery }
        if currentRound % 12 == 0 { return .horseMinigame }
        return .standard5v5
    }

    func executeDraftLottery() {
        print("--- DRAFT LOTTERY INITIATED ---")
        let winPercentage: Float = (teamWins + teamLosses == 0)
            ? 0.5
            : Float(teamWins) / Float(teamWins + teamLosses)

        if winPercentage < 0.3 {
            print("Your team is tanking! Granted 1st overall pick. Legendary unit pool unlocked.")
        } else {
            print("Your team is winning. Granted late round pick.")
        }
    }

    func processShopRoll(costToRoll: Int) {
        if currentCapSpace >= costToRoll {
            currentCapSpace -= costToRoll
            print("Rerolling shop...")
        }
    }
}
