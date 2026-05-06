# BasketballTactics

BasketballTactics is a SwiftUI-based application that combines live NBA statistics with an interactive basketball tactics simulator. It allows users to track the Los Angeles Lakers' performance and draw up simulated plays on a virtual court.

## Features

- **Stats Tab**: 
  - Retrieves and displays the most recent game stats for the Los Angeles Lakers.
  - Shows game scores and opponent information.
  - Includes a roster view to check player statistics.
  - Offline/mock data support available for testing.
- **Tactics Tab**: 
  - An interactive basketball court view.
  - A comprehensive `GameManager` to spawn players, assign actions (passing, shooting, moving), and simulate play executions.
  - Features an underlying simulation engine that accounts for player stats (speed, shooting, defense), synergy, ball possession, and bot opponents.
  - Real-time simulation ticks driving the execution of set plays.

## Architecture

- **UI Framework**: SwiftUI
- **Key Components**:
  - `GameManager`: Core engine managing the game state, active roster, physics ticks, and bot opponents.
  - `SynergyEngine`: Calculates player stat buffs based on active roster combinations.
  - `BasketballCourtView`: The graphical interface for visualizing the court, players, and ball.
  - `LakersStatsService`: Handles API fetching logic for live stats.
  - `PlayerEntity` & `Court`: Core data models handling positional logic and physics.

## Getting Started

1. Open `BasketballTactics.xcodeproj` in Xcode.
2. Select your target device or simulator (iOS/macOS).
3. Build and Run (`Cmd + R`).
