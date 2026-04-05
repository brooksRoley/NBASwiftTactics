import Foundation

enum UnitCost: Int {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
}

class GameEconomy {
    private static let currentSalaryCap: Double = 136_000_000.0

    // Thresholds match scraper.py:_determine_cost() -- keep in sync
    func calculateDraftCost(playerSalary: Double) -> UnitCost {
        let capPercentage = playerSalary / Self.currentSalaryCap

        if capPercentage >= 0.25 { return .five }
        if capPercentage >= 0.15 { return .four }
        if capPercentage >= 0.08 { return .three }
        if capPercentage >= 0.03 { return .two }
        return .one
    }
}

class StatNormalizer {
    func convertZScoreToGameStat(_ zScore: Double) -> Int {
        let scaled = 50.0 + (zScore * 20.0)
        return min(max(Int(scaled.rounded()), 1), 99)
    }
}
