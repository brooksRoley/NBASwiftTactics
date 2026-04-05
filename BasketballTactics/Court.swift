import Foundation
import GameplayKit

class Court {
    var homeScore: Int = 0
    var awayScore: Int = 0
    var ball = Basketball()

    private var homeTeam: [PlayerEntity] = []
    private var awayTeam: [PlayerEntity] = []
    private var rng: GKMersenneTwisterRandomSource = GKMersenneTwisterRandomSource(seed: 42)

    // Pixel-space court: 800 x 400. Hoops centred at x=30 and x=770, mid-height.
    private static let homeHoop = Vector2D(30.0, 200.0)
    private static let awayHoop = Vector2D(770.0, 200.0)

    // Distance from hoop at which a player will attempt a shot
    private static let shotRange: Float = 100.0
    // Distance at which a player picks up a loose ball
    private static let pickupRange: Float = 30.0
    // Pixel-to-feet ratio so ShotProbability (designed in feet) stays accurate
    private static let pxPerFt: Float = 8.25

    var getHomeTeam: [PlayerEntity] { homeTeam }
    var getAwayTeam: [PlayerEntity] { awayTeam }

    func addPlayer(_ player: PlayerEntity, isHome: Bool) {
        if isHome {
            homeTeam.append(player)
        } else {
            awayTeam.append(player)
        }
    }

    func clear() {
        homeTeam.removeAll()
        awayTeam.removeAll()
        ball = Basketball()
        homeScore = 0
        awayScore = 0
    }

    func reseed(_ seed: UInt64) {
        rng = GKMersenneTwisterRandomSource(seed: seed)
    }

    // Give ball to home player with highest shooting
    func initPossession() {
        guard !homeTeam.isEmpty else { return }
        guard let best = homeTeam.max(by: { $0.stats.shooting < $1.stats.shooting }) else { return }
        ball.isPossessed = true
        ball.possessorId = best.id
        ball.position = Vector3D(best.pos.x, best.pos.y, 0.0)
    }

    private func movePlayerToward(_ player: PlayerEntity, target: Vector2D, dt: Float) {
        let dir = target - player.pos
        let dist = dir.magnitude
        guard dist >= 2.0 else { return }
        // Max speed 200 px/s scaled by the player's speed stat
        let step = (player.stats.speed / 100.0) * 200.0 * dt
        player.pos = player.pos + dir.normalized * min(step, dist)
    }

    private func findNearestDefender(to attacker: PlayerEntity, isHomeAttacker: Bool) -> PlayerEntity? {
        let defenders = isHomeAttacker ? awayTeam : homeTeam
        var nearest: PlayerEntity?
        var minDist: Float = .greatestFiniteMagnitude
        for d in defenders {
            let dist = attacker.pos.distance(to: d.pos)
            if dist < minDist {
                minDist = dist
                nearest = d
            }
        }
        return nearest
    }

    // MARK: - Shot attempt

    private func attemptShot(shooter: PlayerEntity, isHomeTeam: Bool) {
        let targetHoop = isHomeTeam ? Court.awayHoop : Court.homeHoop
        let defender = findNearestDefender(to: shooter, isHomeAttacker: isHomeTeam)

        // ShotProbability formula was designed for feet; scale pixel positions down
        let prob: Float
        if let defender = defender {
            let scaledS = PlayerEntity(id: shooter.id, name: shooter.name, speed: shooter.stats.speed, shooting: shooter.stats.shooting)
            scaledS.pos = Vector2D(shooter.pos.x / Court.pxPerFt, shooter.pos.y / Court.pxPerFt)

            let scaledD = PlayerEntity(id: defender.id, name: defender.name, speed: defender.stats.speed, shooting: defender.stats.shooting)
            scaledD.stats.defense = defender.stats.defense
            scaledD.pos = Vector2D(defender.pos.x / Court.pxPerFt, defender.pos.y / Court.pxPerFt)

            let hoopFt = Vector2D(targetHoop.x / Court.pxPerFt, targetHoop.y / Court.pxPerFt)
            prob = calculateShotProbability(shooter: scaledS, nearestDefender: scaledD, hoopPos: hoopFt)
        } else {
            prob = (shooter.stats.shooting / 100.0) * 0.5
        }

        // 3-pointer if shot is taken from beyond 200px of the hoop (~24 ft)
        let distToHoop = shooter.pos.distance(to: targetHoop)
        let points = distToHoop > 200.0 ? 3 : 2

        let roll = Float(rng.nextUniform())
        let made = roll < prob

        if made {
            if isHomeTeam {
                homeScore += points
            } else {
                awayScore += points
            }
            // Hand ball to the other team at mid-court
            ball.position = Vector3D(400.0, 200.0, 0.0)
            ball.velocity = Vector3D(0.0, 0.0, 0.0)
            let nextTeam = isHomeTeam ? awayTeam : homeTeam
            if !nextTeam.isEmpty {
                ball.isPossessed = true
                ball.possessorId = nextTeam[0].id
            } else {
                ball.isPossessed = false
            }
        } else {
            // Miss: launch ball on arc toward the hoop area for a rebound
            ball.isPossessed = false
            ball.possessorId = -1
            let spreadX = Float(rng.nextUniform()) * 100.0 - 50.0
            let spreadY = Float(rng.nextUniform()) * 100.0 - 50.0
            let landX = targetHoop.x + spreadX
            let landY = targetHoop.y + spreadY
            let flightTime: Float = 0.7
            ball.position = Vector3D(shooter.pos.x, shooter.pos.y, 5.0)
            ball.velocity = Vector3D(
                (landX - shooter.pos.x) / flightTime,
                (landY - shooter.pos.y) / flightTime,
                8.0  // upward arc
            )
        }
    }

    // MARK: - Rebound

    private func assignRebound(dt: Float) {
        let ballPos = Vector2D(ball.position.x, ball.position.y)
        var nearest: PlayerEntity?
        var minAdj: Float = .greatestFiniteMagnitude

        func check(_ team: [PlayerEntity]) {
            for p in team {
                let dist = p.pos.distance(to: ballPos)
                // Taller players get a virtual distance bonus
                let heightAdj = dist - Float(p.stats.heightInches - 72) * 2.0
                if heightAdj < minAdj {
                    minAdj = heightAdj
                    nearest = p
                }
            }
        }
        check(homeTeam)
        check(awayTeam)

        guard let nearest = nearest else { return }

        if nearest.pos.distance(to: ballPos) < Court.pickupRange {
            ball.isPossessed = true
            ball.possessorId = nearest.id
        } else {
            movePlayerToward(nearest, target: ballPos, dt: dt)
        }
    }

    // MARK: - Main sim step

    func updateSimulationStep(dt: Float) {
        // Loose ball: apply physics and try to assign rebound once ball lands
        if !ball.isPossessed {
            ball.updatePhysics(deltaTime: dt)
            if ball.position.z <= 0.5 {
                assignRebound(dt: dt)
            }
            return
        }

        // Identify the ball carrier and their team
        var isHomeCarrier = false
        var carrier: PlayerEntity?
        for p in homeTeam {
            if p.id == ball.possessorId { carrier = p; isHomeCarrier = true; break }
        }
        if carrier == nil {
            for p in awayTeam {
                if p.id == ball.possessorId { carrier = p; isHomeCarrier = false; break }
            }
        }
        guard let carrier = carrier else { return }

        let team = isHomeCarrier ? homeTeam : awayTeam
        let opponents = isHomeCarrier ? awayTeam : homeTeam
        let targetHoop = isHomeCarrier ? Court.awayHoop : Court.homeHoop

        // Steal check
        for def in opponents {
            let dist = carrier.pos.distance(to: def.pos)
            if dist < 40.0 {
                let stealChance = (def.stats.defense / 100.0) * 0.15 * dt
                let proximityBonus = ((40.0 - dist) / 40.0) * 0.1 * dt
                if Float(rng.nextUniform()) < stealChance + proximityBonus {
                    ball.possessorId = def.id
                    return
                }
            }
        }

        // Pass check (under defensive pressure)
        if let nearestDef = findNearestDefender(to: carrier, isHomeAttacker: isHomeCarrier),
           carrier.pos.distance(to: nearestDef.pos) < 60.0 {
            for tm in team {
                if tm.id == carrier.id { continue }
                let tmDef = findNearestDefender(to: tm, isHomeAttacker: isHomeCarrier)
                let openness: Float = tmDef != nil ? tm.pos.distance(to: tmDef!.pos) : 200.0
                if openness > 80.0 && Float(rng.nextUniform()) < 0.3 * dt {
                    ball.possessorId = tm.id
                    ball.position = Vector3D(tm.pos.x, tm.pos.y, 0.0)
                    return
                }
            }
        }

        // Ball carrier drives to basket
        movePlayerToward(carrier, target: targetHoop, dt: dt)
        ball.position = Vector3D(carrier.pos.x, carrier.pos.y, 0.0)

        if carrier.pos.distance(to: targetHoop) < Court.shotRange {
            attemptShot(shooter: carrier, isHomeTeam: isHomeCarrier)
            return
        }

        // Teammates spread to offensive spots
        let offBaseX: Float = isHomeCarrier ? 480.0 : 120.0
        for i in 0..<team.count {
            if team[i].id == carrier.id { continue }
            let spot = Vector2D(offBaseX + Float(i % 3) * 80.0, 80.0 + Float(i) * 100.0)
            movePlayerToward(team[i], target: spot, dt: dt)
        }

        // Opponents defend: position between attacker and attacked basket
        for def in opponents {
            var mark: PlayerEntity?
            var minD: Float = .greatestFiniteMagnitude
            for att in team {
                let d = def.pos.distance(to: att.pos)
                if d < minD { minD = d; mark = att }
            }
            if let mark = mark {
                let toHoop = targetHoop - mark.pos
                let mag = toHoop.magnitude
                let guardSpot = mag > 0
                    ? mark.pos + toHoop.normalized * min(30.0, mag)
                    : mark.pos
                movePlayerToward(def, target: guardSpot, dt: dt)
            }
        }
    }
}
