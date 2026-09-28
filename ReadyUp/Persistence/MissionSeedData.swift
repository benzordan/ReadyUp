//
//  MissionSeedData.swift
//  ReadyUp
//

import Foundation

// Content is paraphrased from the SCDF Civil Defence Emergency Handbook
// (10th Edition, 2026); page citations are kept so content stays verifiable.
//
// Task missions are worth 3x a quiz mission. Paschmann et al. (2024) found that
// reward-seeking can decouple from the behaviour a system actually values, so
// low-effort quiz answers must not be able to dominate a score that is meant to
// represent real-world readiness.
//
// Refresh intervals encode how quickly readiness actually lapses: supplies that
// physically drift (Ready Bag batteries, stockpiled food, a shelter used as a
// storeroom) refresh every six months; annual checks and knowledge refresh
// yearly. This is what makes the score decay meaningful rather than arbitrary.
enum MissionSeedData {

    static let taskPointValue = 30
    static let quizPointValue = 10

    static let halfYearDays = 180
    static let yearDays = 365

    // ========================================
    // static var starterMissions: [Mission]
    // The full authored mission set, with sortOrder assigned from array position so display order survives being seeded onto an existing install. Rebuilt on each access, so callers get fresh unattached instances.
    // Returns: All 30 missions, tasks first then quizzes, each with sortOrder set.
    // ========================================
    static var starterMissions: [Mission] {
        (taskMissions + quizMissions).enumerated().map { index, mission in
            mission.sortOrder = index
            return mission
        }
    }

    static var taskMissions: [Mission] {
        [
            // p.50-51
            Mission(
                id: "task.ready_bag",
                title: "Assemble your Ready Bag",
                missionDescription: "Pack a torchlight, spare batteries, a first aid kit, a whistle, N95 masks and essential medication into one grab-and-go bag.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .householdReadiness,
                refreshIntervalDays: halfYearDays
            ),
            // p.5
            Mission(
                id: "task.first_aid_kit",
                title: "Stock a household first aid kit",
                missionDescription: "Include tweezers, scissors, a thermometer, disposable gloves, adhesive tape, dressings and bandages. Store it out of reach of children.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .householdReadiness,
                refreshIntervalDays: halfYearDays
            ),
            // p.53
            Mission(
                id: "task.food_stockpile",
                title: "Build a two-week food stockpile",
                missionDescription: "Follow the ABC rule: Adapt your food choices, Buy reasonable amounts of non-perishables, and Consume and rotate your stock.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .householdReadiness,
                refreshIntervalDays: halfYearDays
            ),
            // p.111
            Mission(
                id: "task.save_contacts",
                title: "Save the emergency numbers",
                missionDescription: "Store 995 for fire and ambulance, 999 for police, and 70995 and 70999 for the SMS emergency lines.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .householdReadiness,
                refreshIntervalDays: yearDays
            ),
            // p.41
            Mission(
                id: "task.assist_plan",
                title: "Plan for elderly or disabled household members",
                missionDescription: "Agree an evacuation route, identify a neighbour who can assist, and check they know to call 995 or 999.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .householdReadiness,
                refreshIntervalDays: yearDays
            ),
            // p.27
            Mission(
                id: "task.fire_safety_checklist",
                title: "Complete the home fire safety checklist",
                missionDescription: "Check your wiring, LPG ventilation, fire extinguisher and escape routes for clutter.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .fireSafety,
                refreshIntervalDays: halfYearDays
            ),
            // p.31
            Mission(
                id: "task.smoke_detector",
                title: "Install a Home Fire Alarm Device",
                missionDescription: "Mount at least one smoke detector along your escape route, and test it and replace its battery every year.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .fireSafety,
                refreshIntervalDays: yearDays
            ),
            // p.35-36
            Mission(
                id: "task.fire_extinguisher",
                title: "Get a dry chemical powder extinguisher",
                missionDescription: "One certified extinguisher covers combustible materials, flammable liquids and electrical fires.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .fireSafety,
                refreshIntervalDays: yearDays
            ),
            // p.28
            Mission(
                id: "task.lpg_check",
                title: "Do the five-point LPG safety check",
                missionDescription: "Inspect the regulator, hose, cylinder, hose clips and joint connections for wear at least once a year.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .fireSafety,
                refreshIntervalDays: yearDays
            ),
            // p.16-20
            Mission(
                id: "task.cpr_learn",
                title: "Learn the CPR sequence",
                missionDescription: "Walk through it: check responsiveness, call 995, check breathing, then compress hard and fast in the centre of the chest.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .firstAid,
                refreshIntervalDays: yearDays
            ),
            // p.13-14
            Mission(
                id: "task.choking_response",
                title: "Practise the Heimlich manoeuvre",
                missionDescription: "Know the hand position: a fist just above the navel, grasped with the other hand, thrusting inward and upward.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .firstAid,
                refreshIntervalDays: yearDays
            ),
            // p.73, p.76
            Mission(
                id: "task.find_shelter",
                title: "Find your nearest shelter",
                missionDescription: "Identify your Household or Storey Shelter, or your nearest Public Shelter such as an MRT station, void deck or community centre.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .shelterAndWarnings,
                refreshIntervalDays: yearDays
            ),
            // p.73-74
            Mission(
                id: "task.shelter_clear",
                title: "Clear your shelter space",
                missionDescription: "Make sure your Household Shelter is usable rather than packed as a storeroom, and keep water and a torchlight nearby.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .shelterAndWarnings,
                refreshIntervalDays: halfYearDays
            ),
            // p.78
            Mission(
                id: "task.icah_spot",
                title: "Pick your Improvised Cover At Home",
                missionDescription: "Choose a spot that is Far from windows, Enclosed, Solid overhead, and clear of combustible material.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .shelterAndWarnings,
                refreshIntervalDays: yearDays
            ),
            // p.55
            Mission(
                id: "task.flood_alerts",
                title: "Sign up for flood alerts",
                missionDescription: "Register for PUB's flood alert service and check myENV, covering the areas you travel through as well as home.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .naturalHazards,
                refreshIntervalDays: yearDays
            ),
            // p.65
            Mission(
                id: "task.secure_furniture",
                title: "Secure heavy furniture and glass",
                missionDescription: "Most tremor injuries come from falling objects and shattering glass, not the shaking. Anchor tall furniture and clear loose items from high shelves.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .naturalHazards,
                refreshIntervalDays: yearDays
            ),
            // p.101-103
            Mission(
                id: "task.run_hide_tell",
                title: "Rehearse Run, Hide, Tell",
                missionDescription: "Know the sequence before you need it: leave by the safest route, hide out of sight and silence your phone, then call 999 once safe.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .securityThreats,
                refreshIntervalDays: yearDays
            ),
            // p.101-103
            Mission(
                id: "task.bleeding_control",
                title: "Keep bleeding-control supplies to hand",
                missionDescription: "Press, Tie, Tell needs a bandage or cloth you can reach fast. Check what you have and where it is stored.",
                kind: .task,
                pointValue: taskPointValue,
                domain: .securityThreats,
                refreshIntervalDays: halfYearDays
            )
        ]
    }

    // One mission per QuizLibrary question; ids must match for the lookup to resolve.
    // Knowledge fades more slowly than supplies, so every quiz refreshes yearly.
    static var quizMissions: [Mission] {
        [
            ("quiz.emergency_number", "Know your emergency numbers", "A quick check on which number to call in an emergency.", HazardDomain.householdReadiness),
            ("quiz.fire_discovery", "Discovering a fire", "A quick check on what to do the moment you find a fire at home.", .fireSafety),
            ("quiz.highrise_evacuation", "Evacuating a high-rise", "A quick check on how to leave a tall building during a fire.", .fireSafety),
            ("quiz.fast_acronym", "The F.A.S.T. check", "A quick check on what F.A.S.T. helps you spot.", .firstAid),
            ("quiz.burn_treatment", "Treating a burn", "A quick check on the right way to treat a burn.", .firstAid),
            ("quiz.cpr_rate", "CPR compressions", "A quick check on how fast to give chest compressions.", .firstAid),
            ("quiz.thunderstorm_indoors", "Thunderstorm safety", "A quick check on what to avoid indoors during a storm.", .naturalHazards),
            ("quiz.flood_vehicle", "Stalled in floodwater", "A quick check on what to do if your vehicle stalls in a flood.", .naturalHazards),
            ("quiz.tsunami_sign", "Tsunami warning signs", "A quick check on how to recognise an incoming tsunami.", .naturalHazards),
            ("quiz.trapped_debris", "Trapped under debris", "A quick check on how to signal rescuers if you are trapped.", .shelterAndWarnings),
            ("quiz.public_warning_alarm", "The Public Warning System", "A quick check on what the wailing Alarm signal means.", .shelterAndWarnings),
            ("quiz.sgsecure_response", "Surviving an attack", "A quick check on the SGSecure response steps.", .securityThreats)
        ].map { id, title, description, domain in
            Mission(
                id: id,
                title: title,
                missionDescription: description,
                kind: .quiz,
                pointValue: quizPointValue,
                domain: domain,
                refreshIntervalDays: yearDays
            )
        }
    }
}
