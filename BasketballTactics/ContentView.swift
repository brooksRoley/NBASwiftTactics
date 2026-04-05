//
//  ContentView.swift
//  BasketballTactics
//
//  Created by Brooks Roley on 4/3/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    var body: some View {
        TabView {
            StatsTab()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            TacticsTab()
                .tabItem { Label("Tactics", systemImage: "sportscourt.fill") }
        }
    }
}

// MARK: - Stats Tab

private struct StatsTab: View {
    @StateObject private var viewModel = LakersStatsViewModel(service: BalldontlieLakersStatsService())

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Previous game banner
                Group {
                    switch viewModel.state {
                    case .idle, .loading:
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Loading last game…")
                                .font(.subheadline)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)

                    case .loaded(let stats):
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last Game · Season \(stats.season)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("vs. \(stats.opponent)")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text("\(stats.lakersScore)–\(stats.opponentScore)")
                                .font(.title2).bold()
                                .foregroundStyle(stats.lakersScore >= stats.opponentScore ? .green : .red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)

                    case .failed:
                        Button("Reload game stats") {
                            Task { await viewModel.reload() }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                    }
                }

                Divider()

                // Roster stat cards
                RosterView()
            }
            .navigationTitle("Lakers")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await viewModel.reload() }
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                }
            }
            .task { await viewModel.reload() }
        }
    }
}

// MARK: - Tactics Tab

private struct TacticsTab: View {
    var body: some View {
        NavigationStack {
            BasketballCourtView()
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Tactics Board")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            NotificationCenter.default.post(name: .clearCourt, object: nil)
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    }
                }
        }
    }
}

// MARK: - ViewModel

final class LakersStatsViewModel: ObservableObject {
    enum LoadState {
        case idle
        case loading
        case loaded(LakersGameStats)
        case failed(Error)
    }

    @Published private(set) var state: LoadState = .idle
    private let service: LakersStatsService

    init(service: LakersStatsService) {
        self.service = service
    }

    @MainActor
    func reload() async {
        state = .loading
        do {
            let stats = try await service.fetchPreviousGameForCurrentSeason()
            state = .loaded(stats)
        } catch {
            state = .failed(error)
        }
    }

    @MainActor
    func useMock() {
        let mock = MockLakersStatsService()
        Task {
            if let stats = try? await mock.fetchPreviousGameForCurrentSeason() {
                state = .loaded(stats)
            }
        }
    }
}

// Current NBA season helper
private func currentSeason() -> Int {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.year, .month], from: Date())
    guard let year = components.year, let month = components.month else {
        return Calendar.current.component(.year, from: Date())
    }
    return month < 7 ? year - 1 : year
}

extension Notification.Name {
    static let clearCourt = Notification.Name("ClearCourtNotification")
}

#Preview {
    ContentView()
}
