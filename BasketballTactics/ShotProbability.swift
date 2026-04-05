import Foundation

func calculateShotProbability(shooter: PlayerEntity, nearestDefender: PlayerEntity, hoopPos: Vector2D) -> Float {
    let distToHoop = shooter.pos.distance(to: hoopPos)
    let defenderProximity = shooter.pos.distance(to: nearestDefender.pos)

    // Exponential decay prevents exceeding 1.0 at close range
    let baseProb = (shooter.stats.shooting / 100.0) * exp(-distToHoop * 0.05)

    // Contest penalty
    var contestPenalty: Float = 0.0
    if defenderProximity < 5.0 {
        contestPenalty = (5.0 - defenderProximity) * 0.1
    }

    return min(max(baseProb - contestPenalty, 0.0), 1.0)
}
