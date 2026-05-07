import SwiftUI
import Combine

struct PuzzleListView: View {
    @StateObject private var puzzleManager = PuzzleManager()
    
    var body: some View {
        NavigationStack {
            List(puzzleManager.puzzles) { puzzle in
                NavigationLink(destination: PuzzleDetailView(puzzleManager: puzzleManager, puzzle: puzzle)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(puzzle.title)
                                .font(.headline)
                            
                            HStack {
                                Text("Difficulty: \(puzzle.difficulty)/5")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                        Spacer()
                        if puzzleManager.isCompleted(puzzle.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Tactics Puzzles")
        }
    }
}

struct PuzzleDetailView: View {
    @ObservedObject var puzzleManager: PuzzleManager
    let puzzle: PuzzleScenario
    @State private var selectedStrategy: DefensiveStrategy?
    @State private var showResult = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(puzzle.title)
                        .font(.largeTitle)
                        .bold()
                    
                    Text(puzzle.description)
                        .font(.body)
                }
                
                Divider()
                
                // Visual Court
                MiniCourtView(players: puzzle.offensiveSet)
                    .padding(.vertical, 8)
                
                Divider()
                
                // Analytics Context
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                        Text("Analytics Context")
                            .font(.headline)
                    }
                    
                    Text(puzzle.analyticsContext)
                        .font(.subheadline)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Divider()
                
                // Offensive Set
                VStack(alignment: .leading, spacing: 12) {
                    Text("Offensive Personnel")
                        .font(.headline)
                    
                    ForEach(puzzle.offensiveSet) { player in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(player.name)
                                    .fontWeight(.semibold)
                                if player.isBallHandler {
                                    Image(systemName: "basketball.fill")
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            if !player.strengths.isEmpty {
                                Text("Strengths: \(player.strengths.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            if !player.weaknesses.isEmpty {
                                Text("Weaknesses: \(player.weaknesses.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                    }
                }
                
                Divider()
                
                // Strategy Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Defensive Strategy")
                        .font(.headline)
                    
                    ForEach(puzzle.defensiveSetupOptions) { strategy in
                        Button(action: {
                            selectedStrategy = strategy
                            showResult = true
                            if strategy == puzzle.correctStrategy {
                                puzzleManager.markCompleted(puzzle.id)
                            }
                        }) {
                            HStack {
                                Text(strategy.rawValue)
                                    .fontWeight(.medium)
                                Spacer()
                                if selectedStrategy == strategy {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedStrategy == strategy ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Result
                if showResult, let selected = selectedStrategy {
                    VStack(alignment: .leading, spacing: 12) {
                        let isCorrect = selected == puzzle.correctStrategy
                        
                        HStack {
                            Image(systemName: isCorrect ? "checkmark.seal.fill" : "xmark.seal.fill")
                                .foregroundColor(isCorrect ? .green : .red)
                                .font(.title)
                            
                            Text(isCorrect ? "Correct!" : "Incorrect")
                                .font(.title2)
                                .bold()
                                .foregroundColor(isCorrect ? .green : .red)
                        }
                        
                        Text(puzzle.explanation)
                            .font(.body)
                            .padding()
                            .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                
            }
            .padding()
        }
        .navigationTitle("Puzzle")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

// MARK: - Mini Court View

struct MiniCourtView: View {
    let players: [PuzzlePlayer]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                PremiumCourtBackground(isHalfCourt: true)
                
                ForEach(players) { player in
                    ZStack {
                        Circle()
                            .fill(player.isBallHandler ? Color.orange : Color.blue)
                            .frame(width: 30, height: 30)
                            .shadow(radius: 2)
                        Text(player.name.prefix(1))
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(.white)
                    }
                    // Scaled based on an arbitrary 800x800 coordinate system from the mock data
                    .position(x: CGFloat(player.positionX) / 800 * geo.size.width,
                              y: CGFloat(player.positionY) / 800 * geo.size.height)
                }
            }
        }
        .frame(height: 250)
        .cornerRadius(12)
    }

}

#Preview {
    PuzzleListView()
}
