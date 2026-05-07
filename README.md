# BasketballTactics

BasketballTactics is a SwiftUI-based application that combines basketball statistics with an interactive tactics simulator and an educational puzzle mode. It allows users to track the "L.A. Stars" performance, draw up simulated plays on a virtual court, and master advanced NBA-level defensive schematics.

## Features

- **Puzzles Tab (New)**:
  - 10 interactive scenarios teaching advanced pick-and-roll coverages (Drop, ICE, Switch All, Blitz).
  - Integrates "Cleaning the Glass" style analytics to explain defensive logic.
  - Visual `MiniCourtView` plots player positions for each puzzle.
- **Stats Tab**: 
  - Displays the most recent game stats and roster for the L.A. Stars (using IP-safe mock data for App Store compliance).
- **Tactics Tab**: 
  - An interactive basketball court view.
  - A comprehensive `GameManager` to spawn players, assign actions (passing, shooting, moving), and simulate play executions.
  - Real-time simulation ticks driving the execution of set plays.

## Architecture

- **UI Framework**: SwiftUI
- **Key Components**:
  - `PuzzleManager`: Manages the state and logic for the educational scenarios.
  - `GameManager`: Core engine managing the game state, active roster, physics ticks, and bot opponents.
  - `BasketballCourtView`: The graphical interface for visualizing the court, players, and ball.
  - `PlayerEntity` & `Court`: Core data models handling positional logic and physics.

## Getting Started

1. Open `BasketballTactics.xcodeproj` in Xcode.
2. Select your target device or simulator (iOS/macOS).
3. Build and Run (`Cmd + R`).

## V1.0.0 App Store Launch Checklist ($0.99 Target)

### 1. Polish & Validation
- [ ] **Device Scaling**: Verify `MiniCourtView` renders correctly on iPhone SE and iPhone 15 Pro Max.
- [ ] **Offline Resilience**: Ensure the app functions completely in Airplane Mode (since data is mocked, just verify).
- [ ] **State Persistence**: (Optional) Save completed puzzles using `@AppStorage`.

### 2. Apple Developer Submission
- [ ] **App Icon**: Add a 1024x1024 icon free of NBA trademarks.
- [ ] **Screenshots**: Capture 4 compelling screenshots representing the educational value (Tactics, Puzzles, Stats).
- [ ] **Privacy Policy**: Host a simple text page stating no data is collected.
- [ ] **Pricing Tier**: Set to Tier 1 ($0.99) in App Store Connect.
