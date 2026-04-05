import Foundation

struct ActiveSynergy {
    var name: String = ""
    var tier: Int = 0
    var speedBuff: Float = 0.0
    var shootingBuff: Float = 0.0
    var defenseBuff: Float = 0.0
}

class SynergyEngine {
    private(set) var currentBuffs: [ActiveSynergy] = []

    func analyzeRoster(_ activeFloor: [PlayerEntity]) {
        currentBuffs.removeAll()
        guard !activeFloor.isEmpty else { return }

        var teamCounts: [String: Int] = [:]
        var giantsCount = 0
        var sharpshootersCount = 0
        var lockdownCount = 0
        var totalSpeed: Float = 0.0

        for player in activeFloor {
            teamCounts[player.team, default: 0] += 1
            if player.stats.heightInches >= 82 { giantsCount += 1 }
            if player.stats.shooting >= 85.0 { sharpshootersCount += 1 }
            if player.stats.defense >= 85.0 { lockdownCount += 1 }
            totalSpeed += player.stats.speed
        }

        // Franchise Synergies
        for (team, count) in teamCounts {
            if count >= 2 {
                var syn = ActiveSynergy()
                syn.name = "\(team) Franchise"
                syn.tier = count / 2
                syn.shootingBuff = 5.0 * Float(syn.tier)
                currentBuffs.append(syn)
            }
        }

        if giantsCount >= 2 {
            let twinTowers = ActiveSynergy(
                name: "Twin Towers",
                tier: giantsCount - 1,
                speedBuff: -5.0,
                shootingBuff: 0.0,
                defenseBuff: 15.0
            )
            currentBuffs.append(twinTowers)
            print("Synergy Activated: Twin Towers! Paint defense heavily boosted.")
        }

        if sharpshootersCount >= 3 {
            let splashFamily = ActiveSynergy(
                name: "Splash Family",
                tier: 1,
                speedBuff: 5.0,
                shootingBuff: 20.0,
                defenseBuff: -5.0
            )
            currentBuffs.append(splashFamily)
            print("Synergy Activated: Splash Family! Limitless range unlocked.")
        }

        if (totalSpeed / Float(activeFloor.count)) > 85.0 && activeFloor.count >= 4 {
            let runAndGun = ActiveSynergy(
                name: "7 Seconds or Less",
                tier: 2,
                speedBuff: 25.0,
                shootingBuff: 10.0,
                defenseBuff: -10.0
            )
            currentBuffs.append(runAndGun)
            print("Synergy Activated: 7 Seconds or Less! Transition speed maximized.")
        }
    }

    func findSimilarComps(target: PlayerEntity, shopPool: [PlayerEntity]) -> [PlayerEntity] {
        shopPool.filter { calculateSimilarity(a: target, b: $0) < 25.0 }
    }

    private func calculateSimilarity(a: PlayerEntity, b: PlayerEntity) -> Float {
        let hDiff = Float(a.stats.heightInches - b.stats.heightInches) * 2.0
        let sDiff = a.stats.shooting - b.stats.shooting
        let dDiff = a.stats.defense - b.stats.defense
        let spdDiff = a.stats.speed - b.stats.speed

        return sqrt(hDiff * hDiff + sDiff * sDiff + dDiff * dDiff + spdDiff * spdDiff)
    }
}
