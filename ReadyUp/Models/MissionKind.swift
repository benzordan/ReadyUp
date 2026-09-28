//
//  MissionKind.swift
//  ReadyUp
//

import Foundation

// Missions is the umbrella term: a mission is either a knowledge quiz or a
// real-world preparedness task.
enum MissionKind: String, Codable, CaseIterable {
    case quiz
    case task
}
