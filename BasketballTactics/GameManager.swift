import Foundation

class GameManager {
    private var activeRoster: [Int: PlayerEntity] = [:]
    private var synergyEngine = SynergyEngine()
    private(set) var court = Court()

    func spawnPlayer(id: Int, name: String, speed: Float, shooting: Float) {
        activeRoster[id] = PlayerEntity(id: id, name: name, speed: speed, shooting: shooting)
        print("Engine: Spawned \(activeRoster[id]!.name) into the simulation.")
    }

    func setPlayerPlay(playerId: Int, actionTypeInt: Int, targetX: Float, targetY: Float) {
        guard let player = activeRoster[playerId],
              let action = ActionType(rawValue: actionTypeInt) else { return }
        player.assignPlay(action: action, targetX: targetX, targetY: targetY)
        print("Engine: \(player.name) assigned action \(actionTypeInt) targeting (\(targetX), \(targetY))")
    }

    func tickSimulation(deltaTime: Float) {
        if !court.getHomeTeam.isEmpty {
            // Round in progress -- let the court sim drive everything
            court.updateSimulationStep(dt: deltaTime)
        } else {
            // Pre-round (e.g. unit tests): just move players via their planned actions
            for (_, player) in activeRoster {
                player.updatePhysicsTick(deltaTime: deltaTime)
            }
        }
    }

    struct GameStateSnapshot: Codable {
        struct PlayerSnapshot: Codable {
            let id: Int
            let name: String
            let x: Float
            let y: Float
        }
        struct BotSnapshot: Codable {
            let id: Int
            let x: Float
            let y: Float
        }
        struct BallSnapshot: Codable {
            let x: Float
            let y: Float
            let z: Float
            let isPossessed: Bool
            let possessorId: Int
        }

        let players: [PlayerSnapshot]
        let bots: [BotSnapshot]
        let ball: BallSnapshot
        let homeScore: Int
        let awayScore: Int
    }

    func getGameStateSnapshot() -> GameStateSnapshot {
        let homeTeam = court.getHomeTeam
        let awayTeam = court.getAwayTeam

        let players: [GameStateSnapshot.PlayerSnapshot]
        if !homeTeam.isEmpty {
            players = homeTeam.map { .init(id: $0.id, name: $0.name, x: $0.pos.x, y: $0.pos.y) }
        } else {
            players = activeRoster.values.map { .init(id: $0.id, name: $0.name, x: $0.pos.x, y: $0.pos.y) }
        }

        let bots = awayTeam.map { GameStateSnapshot.BotSnapshot(id: $0.id, x: $0.pos.x, y: $0.pos.y) }

        let ball = GameStateSnapshot.BallSnapshot(
            x: court.ball.position.x,
            y: court.ball.position.y,
            z: court.ball.position.z,
            isPossessed: court.ball.isPossessed,
            possessorId: court.ball.possessorId
        )

        return GameStateSnapshot(
            players: players,
            bots: bots,
            ball: ball,
            homeScore: court.homeScore,
            awayScore: court.awayScore
        )
    }

    func getGameStateJSON() -> String {
        let snapshot = getGameStateSnapshot()
        guard let data = try? JSONEncoder().encode(snapshot),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func getActiveFloorPlayers() -> [PlayerEntity] {
        Array(activeRoster.values)
    }

    private func spawnBotOpponents() {
        struct BotDef {
            let id: Int
            let startX: Float
            let startY: Float
            let speed: Float
            let shooting: Float
            let defense: Float
        }

        let bots: [BotDef] = [
            BotDef(id: 901, startX: 620.0, startY: 80.0,  speed: 60.0, shooting: 45.0, defense: 55.0),
            BotDef(id: 902, startX: 670.0, startY: 200.0, speed: 55.0, shooting: 40.0, defense: 60.0),
            BotDef(id: 903, startX: 600.0, startY: 320.0, speed: 65.0, shooting: 50.0, defense: 50.0),
        ]
        for def in bots {
            let bot = PlayerEntity(id: def.id, name: "Bot", speed: def.speed, shooting: def.shooting)
            bot.stats.defense = def.defense
            bot.pos = Vector2D(def.startX, def.startY)
            court.addPlayer(bot, isHome: false)
        }
    }

    func startRound() {
        court.clear()

        synergyEngine.analyzeRoster(getActiveFloorPlayers())
        let buffs = synergyEngine.currentBuffs

        for (_, player) in activeRoster {
            for buff in buffs {
                player.stats.speed += buff.speedBuff
                player.stats.shooting += buff.shootingBuff
                player.stats.defense += buff.defenseBuff
                player.clampStats()
            }

            // Map planning-grid placement (0-4) to left-half sim coordinates
            let simX = player.offensivePlacement.x * 70.0 + 40.0
            let simY = player.offensivePlacement.y * 70.0 + 40.0
            player.pos = Vector2D(simX, simY)

            court.addPlayer(player, isHome: true)
        }

        spawnBotOpponents()
        court.initPossession()
    }

    func loadRosterJSON(_ jsonData: String) {
        struct RosterEntry: Decodable {
            let id: Int
            let name: String
            let cost: Int
            struct Stats: Decodable {
                let shooting: Float
                let speed: Float
                let defense: Float
            }
            let stats: Stats
        }

        guard let data = jsonData.data(using: .utf8) else {
            print("Engine: Failed to convert roster JSON to data")
            return
        }

        do {
            let roster = try JSONDecoder().decode([RosterEntry].self, from: data)
            for entry in roster {
                let player = PlayerEntity(id: entry.id, name: entry.name, speed: entry.stats.speed, shooting: entry.stats.shooting)
                player.cost = entry.cost
                player.stats.defense = entry.stats.defense
                player.clampStats()
                activeRoster[entry.id] = player
            }
            print("Engine: Loaded \(activeRoster.count) players from roster JSON")
        } catch {
            print("Engine: Failed to parse roster JSON: \(error)")
        }
    }

    func setPlayerCoordinates(playerId: Int, offX: Float, offY: Float, defX: Float, defY: Float) {
        activeRoster[playerId]?.setPlayCoordinates(offX: offX, offY: offY, defX: defX, defY: defY)
    }

    func removePlayer(playerId: Int) {
        activeRoster.removeValue(forKey: playerId)
    }
}
