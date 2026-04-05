import SwiftUI
import Combine

// MARK: - RosterView

struct RosterView: View {
    @StateObject private var viewModel = RosterViewModel(service: BalldontliePlayerStatsService())

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading roster…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let players):
                let maxPts = players.first?.pts ?? 30
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(players) { player in
                            PlayerStatCard(stats: player, maxPts: maxPts)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }

            case .failed(let error):
                VStack(spacing: 10) {
                    Text("Couldn't load roster")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Use sample data") { viewModel.useMock() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await viewModel.load() }
    }
}

// MARK: - PlayerStatCard

struct PlayerStatCard: View {
    let stats: PlayerSeasonStats
    let maxPts: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stats.playerName)
                        .font(.headline)
                    Text(positionLabel(stats.position))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(stats.gamesPlayed) GP")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 14) {
                StatBar(label: "PTS", value: stats.pts, max: maxPts,    color: .yellow)
                StatBar(label: "REB", value: stats.reb, max: 15,        color: .orange)
                StatBar(label: "AST", value: stats.ast, max: 12,        color: Color(red: 0.3, green: 0.6, blue: 1))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func positionLabel(_ pos: String) -> String {
        switch pos {
        case "G": return "Guard"
        case "F": return "Forward"
        case "C": return "Center"
        case "G-F", "F-G": return "Guard · Forward"
        case "F-C", "C-F": return "Forward · Center"
        default: return pos
        }
    }
}

// MARK: - StatBar

struct StatBar: View {
    let label: String
    let value: Double
    let max: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(value / max, 1.0), height: 7)
                        .animation(.easeOut(duration: 0.4), value: value)
                }
            }
            .frame(height: 7)
            Text(String(format: "%.1f", value))
                .font(.caption)
                .bold()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ViewModel

final class RosterViewModel: ObservableObject {
    enum LoadState {
        case idle
        case loading
        case loaded([PlayerSeasonStats])
        case failed(Error)
    }

    @Published private(set) var state: LoadState = .idle
    private var service: PlayerStatsService

    init(service: PlayerStatsService) {
        self.service = service
    }

    @MainActor
    func load() async {
        state = .loading
        do {
            let players = try await service.fetchLakersSeasonAverages()
            state = .loaded(players)
        } catch {
            state = .failed(error)
        }
    }

    @MainActor
    func useMock() {
        service = MockPlayerStatsService()
        Task { await load() }
    }
}

#Preview {
    RosterView()
        .padding()
        .background(Color(white: 0.1))
}
