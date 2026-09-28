//
//  HazardEscalation.swift
//  ReadyUp
//

import Foundation

// A simulated storm, for demonstrating the alert journey the report's feature
// prototype describes: rainfall climbing "from a typical rainfall value to an
// anomalous, intense rainfall value" while the risk tier steps through all
// three levels.
//
// It answers exactly one question — at step n, what is the rainfall? The tier
// comes from the real RiskClassifier, so a simulated storm cannot disagree with
// how a genuine NEA reading would be classified. That is the point: this
// exercises the production classification path rather than faking around it.
struct HazardEscalation: Equatable {

    // Typical light drizzle, comfortably inside the Low band.
    static let restingMillimetres: Double = 0.2
    // Well past the High threshold; also the value AlertsTabUITests already
    // uses for High, so the demo and the tests agree.
    static let peakMillimetres: Double = 6.0
    static let stepCount = 12
    // 12 x 400ms = 4.8s: long enough to watch the tier step, short enough that
    // nobody is waiting during a demo.
    static let stepInterval: Duration = .milliseconds(400)

    private(set) var stepIndex: Int

    init(stepIndex: Int = 0) {
        self.stepIndex = min(max(stepIndex, 0), Self.stepCount)
    }

    var millimetres: Double {
        let span = Self.peakMillimetres - Self.restingMillimetres
        return Self.restingMillimetres + span * Double(stepIndex) / Double(Self.stepCount)
    }

    var tier: AlertTier {
        RiskClassifier.rainfallTier(millimetres: millimetres) ?? .low
    }

    var isFinished: Bool { stepIndex >= Self.stepCount }

    // ========================================
    // mutating func advance()
    // Moves the simulated storm one step toward peak rainfall, stopping at peak rather than running past it. Pure function, unit-tested.
    // Returns: Nothing.
    // ========================================
    mutating func advance() {
        guard !isFinished else { return }
        stepIndex += 1
    }

    // ========================================
    // static func jumping(to tier: AlertTier) -> HazardEscalation
    // Builds an escalation parked at the first step that classifies as the given tier, so a demo can skip straight to High without waiting out the ramp. Pure function, unit-tested.
    // Returns: An escalation at the first matching step, or at peak if no step classifies as that tier.
    // ========================================
    static func jumping(to tier: AlertTier) -> HazardEscalation {
        for step in 0...stepCount where HazardEscalation(stepIndex: step).tier == tier {
            return HazardEscalation(stepIndex: step)
        }
        return HazardEscalation(stepIndex: stepCount)
    }
}
