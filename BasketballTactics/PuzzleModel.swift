import Foundation
import Combine

// MARK: - Puzzle Models

struct PuzzleScenario: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let difficulty: Int
    
    let offensiveSet: [PuzzlePlayer]
    let defensiveSetupOptions: [DefensiveStrategy]
    
    let analyticsContext: String 
    
    let correctStrategy: DefensiveStrategy
    let explanation: String
}

enum DefensiveStrategy: String, Codable, CaseIterable, Identifiable {
    case dropCoverage = "Drop Coverage"
    case ice = "ICE / Down"
    case switchAll = "Switch All"
    case blitz = "Blitz / Trap"
    case hardHedge = "Hard Hedge"
    
    var id: String { rawValue }
}

struct PuzzlePlayer: Codable, Identifiable {
    let id: Int
    let name: String
    let positionX: Float
    let positionY: Float
    let isBallHandler: Bool
    let strengths: [String]
    let weaknesses: [String]
}

// MARK: - Puzzle Manager

@MainActor
class PuzzleManager: ObservableObject {
    @Published var puzzles: [PuzzleScenario] = []
    @Published var completedPuzzleIDs: Set<String> = []

    init() {
        loadMockPuzzles()
        loadProgress()
    }

    func markCompleted(_ id: String) {
        completedPuzzleIDs.insert(id)
        saveProgress()
    }

    func isCompleted(_ id: String) -> Bool {
        return completedPuzzleIDs.contains(id)
    }

    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: "completedPuzzles"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedPuzzleIDs = decoded
        }
    }

    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(completedPuzzleIDs) {
            UserDefaults.standard.set(encoded, forKey: "completedPuzzles")
        }
    }

    private func loadMockPuzzles() {
        self.puzzles = [
            PuzzleScenario(
                id: "1",
                title: "The Luka/Harden Dilemma",
                description: "You are defending a ball-dominant guard in a high Pick and Roll. The roll man is a non-shooting lob threat.",
                difficulty: 3,
                offensiveSet: [
                    PuzzlePlayer(id: 1, name: "Star Guard", positionX: 400, positionY: 150, isBallHandler: true, strengths: ["Elite Step-back 3", "Elite Rim Finishing"], weaknesses: ["Inefficient short mid-range/floaters"]),
                    PuzzlePlayer(id: 2, name: "Lob Threat", positionX: 400, positionY: 200, isBallHandler: false, strengths: ["95th percentile rim finishing", "Elite screen setting"], weaknesses: ["Cannot shoot outside 5 feet"])
                ],
                defensiveSetupOptions: [.blitz, .switchAll, .dropCoverage, .ice],
                analyticsContext: "The ball handler generates 1.15 Points Per Possession (PPP) when they get to the rim or shoot step-back 3s, but only 0.85 PPP when forced into short mid-range floaters.",
                correctStrategy: .dropCoverage,
                explanation: "By dropping the big man into the paint, you take away the lob threat (rim). The on-ball defender fights over the screen to take away the pull-up 3. You force the guard into the in-between area (short mid-range), yielding the lowest expected value (0.85 PPP)."
            ),
            PuzzleScenario(
                id: "2",
                title: "The Stretch 5 Problem",
                description: "A dangerous shooting big man sets a screen for a quick guard.",
                difficulty: 2,
                offensiveSet: [
                    PuzzlePlayer(id: 3, name: "Quick Guard", positionX: 300, positionY: 100, isBallHandler: true, strengths: ["Speed"], weaknesses: ["30th percentile finishing against size"]),
                    PuzzlePlayer(id: 4, name: "Stretch 5", positionX: 300, positionY: 150, isBallHandler: false, strengths: ["90th percentile 3pt frequency and efficiency"], weaknesses: ["Slow foot speed defensively"])
                ],
                defensiveSetupOptions: [.dropCoverage, .switchAll, .blitz],
                analyticsContext: "The screening big is in the 90th percentile for 3pt efficiency. The guard struggles to finish at the rim against size (30th percentile).",
                correctStrategy: .switchAll,
                explanation: "Dropping would leave the big man wide open for a pick-and-pop 3. Switching keeps a body on the 3-point shooter. You live with the mismatch of the guard driving on your big man, knowing the guard struggles to finish at the rim."
            ),
            PuzzleScenario(
                id: "3",
                title: "Denying the Middle",
                description: "A side pick-and-roll is occurring near the wing. The ball handler is elite at making reads when they get to the middle of the floor.",
                difficulty: 4,
                offensiveSet: [
                    PuzzlePlayer(id: 5, name: "Wing Playmaker", positionX: 650, positionY: 300, isBallHandler: true, strengths: ["1.20 PPP when driving middle", "Elite vision"], weaknesses: ["0.90 PPP when forced baseline"]),
                    PuzzlePlayer(id: 6, name: "Screener", positionX: 600, positionY: 300, isBallHandler: false, strengths: ["Solid screen"], weaknesses: [])
                ],
                defensiveSetupOptions: [.hardHedge, .dropCoverage, .ice],
                analyticsContext: "When forced toward the baseline, the offense's efficiency drops to 0.90 PPP due to reduced passing angles and the sideline acting as an extra defender.",
                correctStrategy: .ice,
                explanation: "The on-ball defender jumps to the top side of the ball handler, denying the middle. The big man drops to contain the drive, effectively using the sideline to trap the handler and force the inefficient baseline drive."
            ),
            PuzzleScenario(
                id: "4",
                title: "Spain Pick & Roll",
                description: "The offense runs a high Pick and Roll, but a third offensive player sets a back-screen on the roll man's defender. This creates immense pressure at the rim.",
                difficulty: 5,
                offensiveSet: [
                    PuzzlePlayer(id: 7, name: "Point Guard", positionX: 400, positionY: 150, isBallHandler: true, strengths: ["Elite playmaker"], weaknesses: []),
                    PuzzlePlayer(id: 8, name: "Roll Man", positionX: 400, positionY: 200, isBallHandler: false, strengths: ["Lob threat"], weaknesses: []),
                    PuzzlePlayer(id: 9, name: "Back Screener", positionX: 400, positionY: 300, isBallHandler: false, strengths: ["Elite 3pt shooter"], weaknesses: [])
                ],
                defensiveSetupOptions: [.dropCoverage, .switchAll, .blitz],
                analyticsContext: "Spain PnR yields 1.25 PPP if the defense drops, due to the confusion between the lob and the pop. Switching the back-screen neutralizes the lob and keeps a body on the shooter, dropping PPP to 0.95.",
                correctStrategy: .switchAll,
                explanation: "By switching the back-screen (the big guards the shooter, the wing guards the roll man), you take away the lob and the open 3. You concede a size mismatch in the post, which is statistically less efficient (0.95 PPP) than a lob or an open 3."
            ),
            PuzzleScenario(
                id: "5",
                title: "The Curry Problem",
                description: "The ball handler is a generational shooter, capable of pulling up from 30 feet if given a sliver of space off the screen.",
                difficulty: 4,
                offensiveSet: [
                    PuzzlePlayer(id: 10, name: "Generational Shooter", positionX: 400, positionY: 120, isBallHandler: true, strengths: ["1.30 PPP on pull-up 3s"], weaknesses: ["Turnover prone under extreme pressure"]),
                    PuzzlePlayer(id: 11, name: "Screener", positionX: 400, positionY: 160, isBallHandler: false, strengths: ["Good short-roller"], weaknesses: ["Average playmaker"])
                ],
                defensiveSetupOptions: [.dropCoverage, .ice, .blitz],
                analyticsContext: "Dropping yields an open pull-up 3 (1.30 PPP). Blitzing forces the ball out of their hands, forcing the screener to make plays in a 4-on-3 scenario (1.05 PPP).",
                correctStrategy: .blitz,
                explanation: "You must Blitz (trap) the ball handler to force the ball out of their hands. While you concede a 4-on-3 advantage to the offense, trusting your backend rotations against a non-elite playmaking screener is statistically better than giving up an open 3."
            ),
            PuzzleScenario(
                id: "6",
                title: "The Ghost Screen",
                description: "A shooter runs toward the ball handler as if to set a screen, but sprints out to the 3-point line at the last second (a 'ghost' screen).",
                difficulty: 3,
                offensiveSet: [
                    PuzzlePlayer(id: 12, name: "Slasher", positionX: 250, positionY: 150, isBallHandler: true, strengths: ["Elite rim pressure"], weaknesses: ["Poor jump shooter"]),
                    PuzzlePlayer(id: 13, name: "Movement Shooter", positionX: 300, positionY: 180, isBallHandler: false, strengths: ["Elite catch-and-shoot 3s"], weaknesses: [])
                ],
                defensiveSetupOptions: [.switchAll, .hardHedge, .dropCoverage],
                analyticsContext: "Trying to fight over or hedge a screen that never happens leads to two defenders guarding the ball, leaving the shooter wide open (1.40 PPP).",
                correctStrategy: .switchAll,
                explanation: "Switch All is the safest coverage against ghost screens. Because no actual physical contact is made on the screen, switching seamlessly prevents the defense from getting tangled, ensuring a defender stays attached to the movement shooter."
            ),
            PuzzleScenario(
                id: "7",
                title: "The Zoom Action",
                description: "The offense runs 'Zoom' action: a pindown screen flowing immediately into a dribble hand-off (DHO) for a shooter.",
                difficulty: 4,
                offensiveSet: [
                    PuzzlePlayer(id: 14, name: "Shooting Guard", positionX: 200, positionY: 300, isBallHandler: false, strengths: ["Elite coming off screens"], weaknesses: ["Average ball handler"]),
                    PuzzlePlayer(id: 15, name: "Big (DHO)", positionX: 250, positionY: 150, isBallHandler: true, strengths: ["Elite screen setter"], weaknesses: ["Non-shooter"]),
                    PuzzlePlayer(id: 16, name: "Pindown Screener", positionX: 200, positionY: 250, isBallHandler: false, strengths: ["Good screener"], weaknesses: [])
                ],
                defensiveSetupOptions: [.dropCoverage, .switchAll, .ice],
                analyticsContext: "Chasing the shooter over both screens usually results in trailing the play, giving up 1.15 PPP. Switching the DHO neutralizes the advantage (0.90 PPP).",
                correctStrategy: .switchAll,
                explanation: "Switch All (specifically 'switching out' on the DHO) is the best way to blow up Zoom action. By switching the big onto the shooter and the guard onto the DHO big, you keep a defender between the shooter and the basket at all times."
            ),
            PuzzleScenario(
                id: "8",
                title: "Empty Corner Pick & Roll",
                description: "The offense clears out an entire side of the floor to run a Pick and Roll, leaving no help defenders on the strong side.",
                difficulty: 3,
                offensiveSet: [
                    PuzzlePlayer(id: 17, name: "Athletic Guard", positionX: 600, positionY: 150, isBallHandler: true, strengths: ["Elite downhill driver"], weaknesses: ["Average playmaker"]),
                    PuzzlePlayer(id: 18, name: "Rim Runner", positionX: 550, positionY: 180, isBallHandler: false, strengths: ["Lob threat"], weaknesses: ["Cannot shoot"])
                ],
                defensiveSetupOptions: [.blitz, .dropCoverage, .ice],
                analyticsContext: "Because the corner is empty, a baseline drive has no passing outlets. Forcing the ball handler baseline drops their PPP to 0.85.",
                correctStrategy: .ice,
                explanation: "ICE (or Down) is perfect for an empty corner. You force the ball handler toward the baseline where they have no shooting angles and no corner teammate to pass to, effectively using the baseline as an extra defender."
            ),
            PuzzleScenario(
                id: "9",
                title: "The Short Roll Playmaker",
                description: "You trap the star guard, forcing the ball to the rolling big man. However, the big man is an elite passer in 4-on-3 situations (e.g., Draymond Green).",
                difficulty: 5,
                offensiveSet: [
                    PuzzlePlayer(id: 19, name: "Star Guard", positionX: 400, positionY: 120, isBallHandler: true, strengths: ["Generational scorer"], weaknesses: []),
                    PuzzlePlayer(id: 20, name: "Playmaking Big", positionX: 400, positionY: 200, isBallHandler: false, strengths: ["Elite court vision", "High IQ"], weaknesses: ["Reluctant scorer"])
                ],
                defensiveSetupOptions: [.blitz, .dropCoverage, .switchAll],
                analyticsContext: "Blitzing and giving the ball to an elite short-roll playmaker in space yields 1.25 PPP. Dropping keeps the play 2-on-2 but concedes a pull-up 3.",
                correctStrategy: .switchAll,
                explanation: "Against an elite short-roll playmaker, you cannot Blitz. Switch All allows you to keep the ball handler contained without giving the playmaking big man a 4-on-3 advantage in the middle of the floor."
            ),
            PuzzleScenario(
                id: "10",
                title: "Step-Up Screen in Transition",
                description: "Early in the shot clock, the big man sets a screen parallel to the baseline (a step-up screen) to get the guard downhill quickly.",
                difficulty: 3,
                offensiveSet: [
                    PuzzlePlayer(id: 21, name: "Speedy Guard", positionX: 700, positionY: 200, isBallHandler: true, strengths: ["Fastest player on court"], weaknesses: ["Struggles in half-court sets"]),
                    PuzzlePlayer(id: 22, name: "Trailing Big", positionX: 700, positionY: 250, isBallHandler: false, strengths: ["Sets hard screens"], weaknesses: ["Poor stamina"])
                ],
                defensiveSetupOptions: [.ice, .hardHedge, .dropCoverage],
                analyticsContext: "If the guard gets middle penetration in transition, it breaks the defense (1.20 PPP). Denying the middle forces them to slow down and set up the offense (0.95 PPP).",
                correctStrategy: .ice,
                explanation: "ICE is the best way to handle a step-up screen. By jumping to the high side and forcing the guard toward the sideline, you deny them the middle of the floor and buy time for the rest of your defense to get back in transition."
            )
        ]
    }
}
