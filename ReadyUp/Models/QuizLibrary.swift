//
//  QuizLibrary.swift
//  ReadyUp
//

import Foundation

struct QuizQuestion: Identifiable, Equatable {
    // Matches the Mission.id of the quiz-kind mission this question belongs to.
    let id: String
    let prompt: String
    let choices: [String]
    let correctAnswerIndex: Int
}

// Question content is paraphrased from the SCDF Civil Defence Emergency Handbook
// (10th Edition, 2026); page citations are kept so content stays verifiable.
// Held as static reference data rather than a SwiftData relationship because it
// ships with the app and is never user-edited.
enum QuizLibrary {

    static let questions: [QuizQuestion] = [
        // p.111
        QuizQuestion(
            id: "quiz.emergency_number",
            prompt: "Which number do you call in Singapore for fire and ambulance services?",
            choices: ["999", "995", "911", "112"],
            correctAnswerIndex: 1
        ),
        // p.33
        QuizQuestion(
            id: "quiz.fire_discovery",
            prompt: "You discover a fire in your home and cannot put it out yourself. What do you do first?",
            choices: [
                "Gather your valuables before leaving",
                "Evacuate immediately and call 995",
                "Take the lift down to leave faster",
                "Open all the windows to let the smoke out"
            ],
            correctAnswerIndex: 1
        ),
        // p.34
        QuizQuestion(
            id: "quiz.highrise_evacuation",
            prompt: "How should you evacuate a high-rise building during a fire?",
            choices: [
                "Use the lift, it is faster",
                "Use the exit stairs, never the lift",
                "Wait on your balcony to be rescued",
                "Break a window to signal for help"
            ],
            correctAnswerIndex: 1
        ),
        // p.11
        QuizQuestion(
            id: "quiz.fast_acronym",
            prompt: "What does the F.A.S.T. check help you recognise?",
            choices: [
                "Signs of a heart attack",
                "Signs of a stroke",
                "Signs of choking",
                "Signs of a seizure"
            ],
            correctAnswerIndex: 1
        ),
        // p.9 - the handbook explicitly warns against toothpaste and cotton wool.
        QuizQuestion(
            id: "quiz.burn_treatment",
            prompt: "How should you treat a burn?",
            choices: [
                "Cover it with toothpaste",
                "Cool it under running water for at least 10 minutes",
                "Cover it with cotton wool",
                "Rub ice directly onto the burn"
            ],
            correctAnswerIndex: 1
        ),
        // p.20
        QuizQuestion(
            id: "quiz.cpr_rate",
            prompt: "What is the correct compression rate for hands-only CPR?",
            choices: [
                "At least 50 per minute",
                "At least 100 per minute",
                "Exactly 30 per minute",
                "About 200 per minute"
            ],
            correctAnswerIndex: 1
        ),
        // p.54
        QuizQuestion(
            id: "quiz.thunderstorm_indoors",
            prompt: "During a thunderstorm, what should you avoid doing indoors?",
            choices: [
                "Reading a book",
                "Showering or using a corded telephone",
                "Sitting on the sofa",
                "Switching on a lamp"
            ],
            correctAnswerIndex: 1
        ),
        // p.55
        QuizQuestion(
            id: "quiz.flood_vehicle",
            prompt: "Your vehicle stalls in rapidly rising floodwater. What should you do?",
            choices: [
                "Keep trying to restart the engine",
                "Switch on hazard lights, call 995 or 999, and move to higher ground",
                "Stay inside the vehicle and wait it out",
                "Open the boot to let the water drain"
            ],
            correctAnswerIndex: 1
        ),
        // p.63
        QuizQuestion(
            id: "quiz.tsunami_sign",
            prompt: "Which of these is a warning sign of an incoming tsunami?",
            choices: [
                "A sudden drop in air temperature",
                "The sea level suddenly receding from the shore",
                "Unusually flat, calm seas for several days",
                "A rainbow forming over the water"
            ],
            correctAnswerIndex: 1
        ),
        // p.67 - shouting risks inhaling dust.
        QuizQuestion(
            id: "quiz.trapped_debris",
            prompt: "You are trapped under debris after a building collapse. How should you signal rescuers?",
            choices: [
                "Shout as loudly and continuously as you can",
                "Tap on a pipe or wall, or use a whistle",
                "Light a match so you can be seen",
                "Stay completely silent to save energy"
            ],
            correctAnswerIndex: 1
        ),
        // p.72
        QuizQuestion(
            id: "quiz.public_warning_alarm",
            prompt: "You hear the Public Warning System \"Alarm\" signal (wailing blasts). What does it mean?",
            choices: [
                "Ignore it and carry on as normal",
                "Move to a Civil Defence shelter immediately",
                "Call 995 to ask what is happening",
                "Switch on all the lights in your home"
            ],
            correctAnswerIndex: 1
        ),
        // p.101 - "Stop, Drop, Roll" is a real SCDF technique, but for clothing fires.
        QuizQuestion(
            id: "quiz.sgsecure_response",
            prompt: "What three steps does SGSecure teach for surviving a terror attack?",
            choices: [
                "Run, Hide, Tell",
                "Stop, Drop, Roll",
                "Fight, Flight, Freeze",
                "Look, Listen, Feel"
            ],
            correctAnswerIndex: 0
        )
    ]

    // ========================================
    // static func question(forMissionID missionID: String) -> QuizQuestion?
    // Looks up the quiz question belonging to a quiz-kind mission by matching identifiers.
    // Returns: The matching QuizQuestion, or nil if the mission has no question (for example a task-kind mission).
    // ========================================
    static func question(forMissionID missionID: String) -> QuizQuestion? {
        questions.first { $0.id == missionID }
    }
}
