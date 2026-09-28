//
//  DrillSessionTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct DrillSessionTests {

    private let ids = ["a", "b", "c"]

    @Test func startsAtFirstStep() {
        let session = DrillSession(missionIDs: ids)

        #expect(session.currentMissionID == "a")
        #expect(session.stepNumber == 1)
        #expect(session.totalSteps == 3)
        #expect(session.isFinished == false)
    }

    @Test func advanceMovesThroughEveryStep() {
        var session = DrillSession(missionIDs: ids)

        session.advance()
        #expect(session.currentMissionID == "b")
        session.advance()
        #expect(session.currentMissionID == "c")
        session.advance()
        #expect(session.currentMissionID == nil)
        #expect(session.isFinished)
    }

    @Test func advancingPastTheEndIsSafe() {
        var session = DrillSession(missionIDs: ids)
        for _ in 0..<10 { session.advance() }

        #expect(session.isFinished)
        #expect(session.stepNumber == 3)
    }

    @Test func emptySessionIsImmediatelyFinished() {
        let session = DrillSession(missionIDs: [])

        #expect(session.isFinished)
        #expect(session.currentMissionID == nil)
        #expect(session.pointsEarned == 0)
    }

    @Test func pointsEarnedSumsOnlyCompletedSteps() {
        var session = DrillSession(missionIDs: ids)
        session.record(.completed(points: 30), forMissionID: "a")
        session.record(.failed, forMissionID: "b")
        session.record(.skipped, forMissionID: "c")

        #expect(session.pointsEarned == 30)
        #expect(session.completedCount == 1)
    }

    @Test func recordingTwiceForOneMissionOverwrites() {
        var session = DrillSession(missionIDs: ids)
        session.record(.failed, forMissionID: "a")
        session.record(.completed(points: 10), forMissionID: "a")

        #expect(session.pointsEarned == 10)
        #expect(session.completedCount == 1)
    }

    @Test func allCompletedSumsEveryStep() {
        var session = DrillSession(missionIDs: ids)
        session.record(.completed(points: 30), forMissionID: "a")
        session.record(.completed(points: 10), forMissionID: "b")
        session.record(.completed(points: 30), forMissionID: "c")

        #expect(session.pointsEarned == 70)
        #expect(session.completedCount == 3)
    }

    @Test func resultsAreRetrievableByMissionID() {
        var session = DrillSession(missionIDs: ids)
        session.record(.completed(points: 30), forMissionID: "a")

        #expect(session.results["a"] == .completed(points: 30))
        #expect(session.results["b"] == nil)
    }
}
