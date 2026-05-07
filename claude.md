# Project Context: Basketball Tactics

## Goal
Ship V1.0.0 to the iOS App Store as a $0.99 paid app.

## V1.0.0 Launch Checklist & Validation

### Features Needed for V1.0.0
1. **Interactive Puzzles (10 Minimum)**: Educational NBA schematics puzzles using "Cleaning the Glass" concepts. Includes visual `MiniCourtView` (Currently complete with 10 puzzles).
2. **IP Safe Data**: All real NBA team names ("Lakers") and player names ("LeBron James") replaced with generic names ("L.A. Stars", "Star Forward") to pass App Store review. (Currently implemented via Mock Services).
3. **Tactics Board**: Fully functional sandbox for drawing plays and markers.
4. **(Optional but recommended)**: User defaults to save completed puzzles.

### Validation & Playthrough Testing
1. **Device Scaling Test**: Play through all 10 puzzles on both an iPhone SE (small screen) and iPhone 15 Pro Max (large screen) simulators to ensure the `MiniCourtView` coordinates and markers scale without clipping.
2. **Offline Mode Validation**: Ensure the app functions completely in Airplane Mode.
3. **Puzzle Logic Review**: Play through each puzzle and deliberately choose incorrect answers to ensure the grading logic and explanations display correctly without UI bugs.
4. **Memory Leaks / Performance**: Verify that repeatedly opening/closing the Tactics Board or drawing massive amounts of lines on the court doesn't crash the app.

### Final Submission Steps
1. **App Icon & Branding**: Add a 1024x1024 icon that does NOT use trademarked NBA logos.
2. **Screenshots**: Capture 4 compelling screenshots (Tactics board, Puzzle List, Puzzle Detail with Mini Court, Roster Stats).
3. **Privacy Policy**: Host a simple text page stating no user data is collected.
