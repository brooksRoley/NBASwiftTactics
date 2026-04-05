import Foundation

// MARK: - Models

public struct PlayerSeasonStats: Identifiable, Sendable {
    public let id: Int
    public let playerName: String
    public let position: String
    public let pts: Double
    public let reb: Double
    public let ast: Double
    public let gamesPlayed: Int
}

// MARK: - Protocol

public protocol PlayerStatsService {
    func fetchLakersSeasonAverages() async throws -> [PlayerSeasonStats]
}

// MARK: - Live Service

public final class BalldontliePlayerStatsService: PlayerStatsService {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let lakersTeamId = 14

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func fetchLakersSeasonAverages() async throws -> [PlayerSeasonStats] {
        let season = BalldontlieLakersStatsService.currentSeason()

        var components = URLComponents(string: "https://api.balldontlie.io/v1/stats")
        components?.queryItems = [
            URLQueryItem(name: "seasons[]", value: String(season)),
            URLQueryItem(name: "team_ids[]", value: String(lakersTeamId)),
            URLQueryItem(name: "per_page", value: "100")
        ]
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.network(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? -1))
        }

        let statsResponse: PlayerStatsAPIResponse
        do {
            statsResponse = try decoder.decode(PlayerStatsAPIResponse.self, from: data)
        } catch {
            throw APIError.decode(error)
        }

        // Group by player and compute averages client-side
        var playerMap: [Int: PlayerAccumulator] = [:]

        for stat in statsResponse.data where stat.min != nil && stat.min != "0" && stat.min != "" {
            let pid = stat.player.id
            if playerMap[pid] == nil {
                playerMap[pid] = PlayerAccumulator(
                    name: "\(stat.player.first_name) \(stat.player.last_name)",
                    position: stat.player.position ?? "—"
                )
            }
            playerMap[pid]?.pts.append(stat.pts)
            playerMap[pid]?.reb.append(stat.reb)
            playerMap[pid]?.ast.append(stat.ast)
        }

        return playerMap.compactMap { (pid, acc) -> PlayerSeasonStats? in
            guard acc.pts.count >= 3 else { return nil }
            return PlayerSeasonStats(
                id: pid,
                playerName: acc.name,
                position: acc.position,
                pts: acc.pts.average,
                reb: acc.reb.average,
                ast: acc.ast.average,
                gamesPlayed: acc.pts.count
            )
        }
        .sorted { $0.pts > $1.pts }
    }
}

// MARK: - Private helpers

private struct PlayerAccumulator {
    let name: String
    let position: String
    var pts: [Double] = []
    var reb: [Double] = []
    var ast: [Double] = []
}

private extension Array where Element == Double {
    var average: Double { isEmpty ? 0 : reduce(0, +) / Double(count) }
}

// MARK: - API DTOs

private struct PlayerStatsAPIResponse: Decodable {
    let data: [PlayerStatEntry]
}

private struct PlayerStatEntry: Decodable {
    let player: PlayerRef
    let pts: Double
    let reb: Double
    let ast: Double
    let min: String?
}

private struct PlayerRef: Decodable {
    let id: Int
    let first_name: String
    let last_name: String
    let position: String?
}

// MARK: - Mock

public final class MockPlayerStatsService: PlayerStatsService {
    public init() {}

    public func fetchLakersSeasonAverages() async throws -> [PlayerSeasonStats] {
        [
            PlayerSeasonStats(id: 2544,  playerName: "LeBron James",      position: "F",  pts: 25.7, reb: 7.3,  ast: 8.3, gamesPlayed: 71),
            PlayerSeasonStats(id: 3202,  playerName: "Anthony Davis",     position: "C",  pts: 24.7, reb: 12.6, ast: 3.5, gamesPlayed: 76),
            PlayerSeasonStats(id: 1629029,playerName: "Austin Reaves",   position: "G",  pts: 15.9, reb: 4.4,  ast: 5.5, gamesPlayed: 79),
            PlayerSeasonStats(id: 1626156,playerName: "D'Angelo Russell", position: "G",  pts: 14.3, reb: 3.1,  ast: 6.0, gamesPlayed: 68),
            PlayerSeasonStats(id: 1629060,playerName: "Rui Hachimura",    position: "F",  pts: 13.7, reb: 4.7,  ast: 1.4, gamesPlayed: 74),
            PlayerSeasonStats(id: 1641705,playerName: "Max Christie",     position: "G",  pts: 10.2, reb: 3.3,  ast: 1.8, gamesPlayed: 62),
            PlayerSeasonStats(id: 203076, playerName: "Gabe Vincent",     position: "G",  pts: 8.4,  reb: 2.1,  ast: 2.9, gamesPlayed: 58),
        ]
    }
}
