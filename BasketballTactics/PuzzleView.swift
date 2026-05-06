import SwiftUI

struct PuzzleListView: View {
    @StateObject private var puzzleManager = PuzzleManager()
    
    var body: some View {
        NavigationStack {
            List(puzzleManager.puzzles) { puzzle in
                NavigationLink(destination: PuzzleDetailView(puzzle: puzzle)) {
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
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Tactics Puzzles")
        }
    }
}

struct PuzzleDetailView: View {
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
                        .background(Color(UIColor.secondarySystemBackground))
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Mini Court View

struct MiniCourtView: View {
    let players: [PuzzlePlayer]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                court(in: geo.size)
                    .fill(Color.orange.opacity(0.15))
                    .overlay(courtLines(in: geo.size).stroke(Color.brown, lineWidth: 2))
                
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

    private func court(in size: CGSize) -> Path {
        var path = Path()
        path.addRect(CGRect(origin: .zero, size: size))
        return path
    }

    private func courtLines(in size: CGSize) -> Path {
        var path = Path()
        let w = size.width
        let h = size.height

        path.addRect(CGRect(x: 0, y: 0, width: w, height: h))
        path.move(to: CGPoint(x: 0, y: h/2))
        path.addLine(to: CGPoint(x: w, y: h/2))

        let arcCenter = CGPoint(x: w/2, y: h - h*0.2)
        path.addArc(center: arcCenter, radius: min(w, h) * 0.35, startAngle: .degrees(200), endAngle: .degrees(-20), clockwise: true)

        let ftCenter = CGPoint(x: w/2, y: h - h*0.35)
        path.addEllipse(in: CGRect(x: ftCenter.x - 30, y: ftCenter.y - 30, width: 60, height: 60))

        let keyWidth: CGFloat = min(w * 0.4, 120)
        let keyHeight: CGFloat = h * 0.35
        path.addRect(CGRect(x: (w - keyWidth)/2, y: h - keyHeight, width: keyWidth, height: keyHeight))

        return path
    }
}

#Preview {
    PuzzleListView()
}
