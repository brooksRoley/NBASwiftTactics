import Foundation

// MARK: - Models

public struct LakersGameStats: Sendable {
    public let date: Date
    public let opponent: String
    public let lakersScore: Int
    public let opponentScore: Int
    public let season: Int
}

public enum APIError: Error, LocalizedError {
    case invalidURL
    case network(Error)
    case decode(Error)
    case notFound

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .network(let err): return "Network error: \(err.localizedDescription)"
        case .decode(let err): return "Failed to decode data: \(err.localizedDescription)"
        case .notFound: return "No recent game found for the Lakers in the current season."
        }
    }
}

// MARK: - Service Protocol

public protocol LakersStatsService {
    func fetchPreviousGameForCurrentSeason() async throws -> LakersGameStats
}

// MARK: - Concrete Service (balldontlie.io)

public final class BalldontlieLakersStatsService: LakersStatsService {
    private let session: URLSession
    private let decoder: JSONDecoder

    // balldontlie team id for Los Angeles Lakers
    private let lakersTeamId = 14

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func fetchPreviousGameForCurrentSeason() async throws -> LakersGameStats {
        let season = Self.currentSeason()
        let today = Date()
        let endDate = Self.simpleDateFormatter.string(from: today)

        var components = URLComponents(string: "https://api.balldontlie.io/v1/games")
        components?.queryItems = [
            URLQueryItem(name: "seasons[]", value: String(season)),
            URLQueryItem(name: "team_ids[]", value: String(lakersTeamId)),
            URLQueryItem(name: "end_date", value: endDate),
            URLQueryItem(name: "per_page", value: "100")
        ]
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // If you have an API key for higher rate limits, set it here as a header.
        // request.setValue("YOUR_API_KEY", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.network(NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? -1))
        }

        let apiResponse: GamesResponse
        do {
            apiResponse = try decoder.decode(GamesResponse.self, from: data)
        } catch {
            // Try a fallback date decoding if ISO8601 with fractional seconds needed
            let fallbackDecoder = JSONDecoder()
            fallbackDecoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let str = try container.decode(String.self)
                if let date = Self.iso8601Fractional.date(from: str) ?? Self.iso8601Basic.date(from: str) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format: \(str)")
            }
            do {
                apiResponse = try fallbackDecoder.decode(GamesResponse.self, from: data)
            } catch {
                throw APIError.decode(error)
            }
        }

        // Find the most recent finished game
        let now = Date()
        let finishedGames = apiResponse.data.filter { game in
            // Treat non-zero scores as finished; some statuses include "Final"
            (game.home_team_score + game.visitor_team_score) > 0 && game.date <= now
        }
        guard let latest = finishedGames.sorted(by: { $0.date > $1.date }).first else {
            throw APIError.notFound
        }

        let lakersAreHome = latest.home_team.id == lakersTeamId
        let opponentTeam = lakersAreHome ? latest.visitor_team : latest.home_team
        let lakersScore = lakersAreHome ? latest.home_team_score : latest.visitor_team_score
        let opponentScore = lakersAreHome ? latest.visitor_team_score : latest.home_team_score

        return LakersGameStats(
            date: latest.date,
            opponent: opponentTeam.full_name,
            lakersScore: lakersScore,
            opponentScore: opponentScore,
            season: latest.season
        )
    }

    // MARK: - Helpers

    static func currentSeason() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let comps = calendar.dateComponents([.year, .month], from: Date())
        guard let year = comps.year, let month = comps.month else { return Calendar.current.component(.year, from: Date()) }
        // NBA season year is the year it starts; before July -> previous year
        return month < 7 ? year - 1 : year
    }

    static let simpleDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    static let iso8601Fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let iso8601Basic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - API DTOs

private struct GamesResponse: Decodable {
    let data: [Game]
}

private struct Game: Decodable {
    let id: Int
    let date: Date
    let home_team: Team
    let visitor_team: Team
    let home_team_score: Int
    let visitor_team_score: Int
    let season: Int
    let status: String?
}

private struct Team: Decodable {
    let id: Int
    let full_name: String
}

// MARK: - Mock

public final class MockLakersStatsService: LakersStatsService {
    public init() {}

    public func fetchPreviousGameForCurrentSeason() async throws -> LakersGameStats {
        let season = BalldontlieLakersStatsService.currentSeason()
        return LakersGameStats(
            date: Date().addingTimeInterval(-86_400),
            opponent: "Los Angeles Clippers",
            lakersScore: 112,
            opponentScore: 106,
            season: season
        )
    }
}
