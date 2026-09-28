//
//  HazardDomainTests.swift
//  ReadyUpTests
//

import Foundation
import Testing
@testable import ReadyUp

struct HazardDomainTests {

    // The authored assignment, spelled out so an accidental reassignment in
    // MissionSeedData fails here rather than silently reshuffling the grid.
    private let expectedDomains: [String: HazardDomain] = [
        "task.ready_bag": .householdReadiness,
        "task.first_aid_kit": .householdReadiness,
        "task.food_stockpile": .householdReadiness,
        "task.save_contacts": .householdReadiness,
        "task.assist_plan": .householdReadiness,
        "task.fire_safety_checklist": .fireSafety,
        "task.smoke_detector": .fireSafety,
        "task.fire_extinguisher": .fireSafety,
        "task.lpg_check": .fireSafety,
        "task.cpr_learn": .firstAid,
        "task.choking_response": .firstAid,
        "task.find_shelter": .shelterAndWarnings,
        "task.shelter_clear": .shelterAndWarnings,
        "task.icah_spot": .shelterAndWarnings,
        "task.flood_alerts": .naturalHazards,
        "task.secure_furniture": .naturalHazards,
        "task.run_hide_tell": .securityThreats,
        "task.bleeding_control": .securityThreats,
        "quiz.emergency_number": .householdReadiness,
        "quiz.fire_discovery": .fireSafety,
        "quiz.highrise_evacuation": .fireSafety,
        "quiz.fast_acronym": .firstAid,
        "quiz.burn_treatment": .firstAid,
        "quiz.cpr_rate": .firstAid,
        "quiz.thunderstorm_indoors": .naturalHazards,
        "quiz.flood_vehicle": .naturalHazards,
        "quiz.tsunami_sign": .naturalHazards,
        "quiz.trapped_debris": .shelterAndWarnings,
        "quiz.public_warning_alarm": .shelterAndWarnings,
        "quiz.sgsecure_response": .securityThreats
    ]

    @Test func everySeededMissionMatchesItsExpectedDomain() {
        for mission in MissionSeedData.starterMissions {
            let expected = expectedDomains[mission.id]
            #expect(expected != nil, "\(mission.id) is missing from the expected-domain table")
            #expect(mission.domain == expected, "\(mission.id) is in the wrong domain")
        }
    }

    @Test func expectedTableCoversEverySeededMission() {
        let seededIDs = Set(MissionSeedData.starterMissions.map(\.id))
        #expect(seededIDs == Set(expectedDomains.keys))
    }

    @Test func everyDomainHasAtLeastOneMission() {
        let missions = MissionSeedData.starterMissions
        for domain in HazardDomain.allCases {
            let count = missions.count { $0.domain == domain }
            #expect(count >= 1, "\(domain.rawValue) has no missions")
        }
    }

    @Test func everyDomainHasAtLeastOneTaskAndOneQuiz() {
        let missions = MissionSeedData.starterMissions
        for domain in HazardDomain.allCases {
            let inDomain = missions.filter { $0.domain == domain }
            #expect(inDomain.contains { $0.kind == .task }, "\(domain.rawValue) has no task")
            #expect(inDomain.contains { $0.kind == .quiz }, "\(domain.rawValue) has no quiz")
        }
    }

    // The raw values are the Resource Hub category id suffixes; if the two
    // libraries ever drift this is what catches it.
    @Test func everyDomainResolvesToAResourceCategory() {
        for domain in HazardDomain.allCases {
            #expect(domain.resourceCategory != nil, "\(domain.rawValue) has no Resource Hub category")
        }
    }

    @Test func everySeededMissionHasAPositiveRefreshInterval() {
        for mission in MissionSeedData.starterMissions {
            #expect(mission.refreshIntervalDays > 0, "\(mission.id) would never decay")
        }
    }

    @Test func refreshIntervalsAreSixMonthsOrOneYear() {
        let allowed: Set<Int> = [MissionSeedData.halfYearDays, MissionSeedData.yearDays]
        for mission in MissionSeedData.starterMissions {
            #expect(allowed.contains(mission.refreshIntervalDays), "\(mission.id) has an off-cadence interval")
        }
    }

    @Test func seedSortOrdersAreUniqueAndContiguous() {
        let orders = MissionSeedData.starterMissions.map(\.sortOrder)
        #expect(Set(orders).count == orders.count)
        #expect(Set(orders) == Set(0..<orders.count))
    }

    @Test func seedSetHasExpectedShape() {
        let missions = MissionSeedData.starterMissions
        #expect(missions.count == 30)
        #expect(missions.count { $0.kind == .task } == 18)
        #expect(missions.count { $0.kind == .quiz } == 12)
    }

    @Test func allSeededIDsAreUnique() {
        let ids = MissionSeedData.starterMissions.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func domainDisplayStringsAreNonEmpty() {
        for domain in HazardDomain.allCases {
            #expect(!domain.displayName.isEmpty)
            #expect(!domain.shortName.isEmpty)
            #expect(!domain.iconSystemName.isEmpty)
            #expect(!domain.subtitle.isEmpty)
        }
    }
}
