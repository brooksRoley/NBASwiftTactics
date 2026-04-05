import Foundation

struct PlayerStats {
    var shooting: Float = 50.0
    var defense: Float = 50.0
    var speed: Float = 50.0
    var heightInches: Int = 72
    var weightLbs: Int = 200
    var stamina: Int = 100
}

enum Position: String, CaseIterable {
    case pg = "PG"
    case sg = "SG"
    case sf = "SF"
    case pf = "PF"
    case c = "C"
}

enum ActionType: Int {
    case hold = 0
    case cutToBasket = 1
    case setScreen = 2
    case spotUp = 3
}

enum PlayerState {
    case offense
    case defense
    case transitionToOffense
    case transitionToDefense
}

class PlayerEntity {
    var id: Int = 0
    var name: String = ""
    var team: String = ""
    var position: Position = .pg
    var stats = PlayerStats()
    var cost: Int = 1
    var currentHealth: Int = 100

    // Spatial state
    var pos = Vector2D()
    var velocity = Vector2D()
    var targetLocation = Vector2D()
    var state: PlayerState = .offense
    var plannedAction: ActionType = .hold

    // Formation placement coordinates
    var offensivePlacement = Vector2D()
    var defensivePlacement = Vector2D()

    // Ability tracking
    var hasLimitlessRange = false

    init() {}

    init(id: Int, name: String, speed: Float, shooting: Float) {
        self.id = id
        self.name = name
        stats.speed = speed
        stats.shooting = shooting
    }

    init(name: String, position: Position, stats: PlayerStats) {
        self.name = name
        self.position = position
        self.stats = stats
    }

    func assignPlay(action: ActionType, targetX: Float, targetY: Float) {
        plannedAction = action
        targetLocation = Vector2D(targetX, targetY)
    }

    func updatePhysicsTick(deltaTime: Float) {
        if plannedAction == .cutToBasket || plannedAction == .spotUp {
            let direction = (targetLocation - pos).normalized
            let courtSpeed = (stats.speed / 100.0) * 15.0
            velocity = direction * courtSpeed

            if pos.distance(to: targetLocation) > 0.5 {
                pos = pos + (velocity * deltaTime)
            } else {
                plannedAction = .hold
            }
        }
    }

    func updateTransition() {
        guard state == .transitionToOffense || state == .transitionToDefense else { return }

        let spd = (stats.speed / 100.0) * 2.5

        // Move X axis
        if abs(pos.x - targetLocation.x) > spd {
            pos.x += (targetLocation.x > pos.x) ? spd : -spd
        } else {
            pos.x = targetLocation.x
        }

        // Move Y axis
        if abs(pos.y - targetLocation.y) > spd {
            pos.y += (targetLocation.y > pos.y) ? spd : -spd
        } else {
            pos.y = targetLocation.y
        }

        // Transition complete only when BOTH axes have arrived
        if pos.x == targetLocation.x && pos.y == targetLocation.y {
            state = (state == .transitionToOffense) ? .offense : .defense
        }
    }

    func clampStats() {
        stats.shooting = min(max(stats.shooting, 1.0), 99.0)
        stats.defense = min(max(stats.defense, 1.0), 99.0)
        stats.speed = min(max(stats.speed, 1.0), 99.0)
    }

    func setPlayCoordinates(offX: Float, offY: Float, defX: Float, defY: Float) {
        offensivePlacement = Vector2D(offX, offY)
        defensivePlacement = Vector2D(defX, defY)
    }

    func applyLimitlessRange() {
        guard !hasLimitlessRange else { return }
        stats.shooting = min(stats.shooting + 20.0, 99.0)
        hasLimitlessRange = true
        print("\(name) triggers 'Limitless Range'! Shooting buff applied.")
    }
}
