//
//  HazardDomain.swift
//  ReadyUp
//

import Foundation

// The hazard areas a user can practise, one per Resource Hub guidance category.
//
// There are six, not seven: `category.emergency_contacts` is a phone directory
// rather than a practice area, so its two related missions (saving the numbers,
// and the emergency-number quiz) sit under household readiness instead.
//
// The raw values are deliberately the Resource Hub category id suffixes, so
// `resourceCategoryID` is derived rather than hand-typed and the two lists
// cannot drift apart. `HazardDomainTests` pins this.
enum HazardDomain: String, Codable, CaseIterable, Identifiable, Hashable {
    case householdReadiness = "household_readiness"
    case fireSafety = "fire_safety"
    case firstAid = "first_aid"
    case shelterAndWarnings = "shelter_warnings"
    case naturalHazards = "natural_hazards"
    case securityThreats = "security_threats"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .householdReadiness: "Household Readiness"
        case .fireSafety: "Fire Safety"
        case .firstAid: "First Aid"
        case .shelterAndWarnings: "Shelter & Warnings"
        case .naturalHazards: "Natural Hazards"
        case .securityThreats: "Security Threats"
        }
    }

    // Short enough to fit a grid tile without wrapping to three lines.
    var shortName: String {
        switch self {
        case .householdReadiness: "Household"
        case .fireSafety: "Fire"
        case .firstAid: "First Aid"
        case .shelterAndWarnings: "Shelter"
        case .naturalHazards: "Weather"
        case .securityThreats: "Security"
        }
    }

    var subtitle: String {
        switch self {
        case .householdReadiness: "Stock up and plan before disaster strikes"
        case .fireSafety: "Prevent, detect, and respond to fire"
        case .firstAid: "Step-by-step emergency care"
        case .shelterAndWarnings: "Where to go and what the alarms mean"
        case .naturalHazards: "Storms, floods, tsunamis and earthquakes"
        case .securityThreats: "Responding to attacks and threats"
        }
    }

    var iconSystemName: String {
        switch self {
        case .householdReadiness: "bag.fill"
        case .fireSafety: "flame.fill"
        case .firstAid: "cross.case.fill"
        case .shelterAndWarnings: "building.2.fill"
        case .naturalHazards: "cloud.bolt.rain.fill"
        case .securityThreats: "shield.lefthalf.filled"
        }
    }

    var resourceCategoryID: String { "category.\(rawValue)" }

    // ========================================
    // var resourceCategory: ResourceCategory?
    // Resolves this domain to its matching Resource Hub category so a domain screen can deep-link into the fuller guidance articles. Optional by design: a nil result means the two libraries have drifted, which HazardDomainTests catches.
    // Returns: The matching ResourceCategory, or nil if no category carries this domain's id.
    // ========================================
    var resourceCategory: ResourceCategory? {
        ResourceHubLibrary.categories.first { $0.id == resourceCategoryID }
    }
}
