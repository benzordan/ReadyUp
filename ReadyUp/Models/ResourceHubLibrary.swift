//
//  ResourceHubLibrary.swift
//  ReadyUp
//

import Foundation

// The curated, offline-available repository behind the Resource Hub tab.
//
// Content is paraphrased from the SCDF Civil Defence Emergency Handbook
// (10th Edition, 2026); every article carries its page citation so the guidance
// stays verifiable. Held as static Swift values rather than SwiftData models
// because it ships with the app, is never user-edited, and must be available
// with no network by construction.
//
// Articles are deliberately deeper than the Prepare tab's missions and quizzes,
// which cover the same hazard domains as single facts. Here they are full
// procedures.
enum ResourceHubLibrary {

    private static let handbook = "SCDF Civil Defence Emergency Handbook (10th Ed., 2026)"

    private static func citation(_ page: String) -> String {
        "\(handbook), \(page)"
    }

    static let categories: [ResourceCategory] = [
        householdReadiness,
        fireSafety,
        firstAid,
        shelterAndWarnings,
        naturalHazards,
        securityThreats,
        emergencyContacts
    ]

    // MARK: - Household Readiness

    private static let householdReadiness = ResourceCategory(
        id: "category.household_readiness",
        title: "Household Readiness",
        subtitle: "Stock up and plan before disaster strikes",
        iconSystemName: "bag.fill",
        content: .articles([
            ResourceArticle(
                id: "article.ready_bag",
                title: "Pack Your Ready Bag",
                summary: "The grab-and-go bag you take when you have seconds to leave.",
                steps: [
                    "Pack a torchlight with spare batteries stored separately, so you are not relying on your phone for light.",
                    "Add a basic first aid kit and any regular medication your household depends on.",
                    "Include a whistle to signal for help, and N95 masks for smoke or haze.",
                    "Add copies of important documents and a little cash in small notes.",
                    "Store the bag where every household member can find and reach it in the dark."
                ],
                sourceCitation: citation("p.50-51")
            ),
            ResourceArticle(
                id: "article.first_aid_kit",
                title: "Stock a Household First Aid Kit",
                summary: "What belongs in the kit, and where to keep it.",
                steps: [
                    "Keep tweezers, scissors and a thermometer together in one container.",
                    "Add disposable gloves, adhesive tape, sterile dressings and bandages in several sizes.",
                    "Store it somewhere adults can reach quickly but children cannot.",
                    "Check it every few months and replace anything used or expired."
                ],
                sourceCitation: citation("p.5")
            ),
            ResourceArticle(
                id: "article.food_stockpile",
                title: "Build a Two-Week Food Stockpile",
                summary: "The ABC rule for stocking up without waste.",
                steps: [
                    "Adapt: choose non-perishable food your household will actually eat.",
                    "Buy: build up a reasonable two-week supply gradually, rather than panic-buying.",
                    "Consume: eat and replace from the stockpile so nothing expires unused.",
                    "Include drinking water and a manual can opener that needs no power."
                ],
                sourceCitation: citation("p.53")
            ),
            ResourceArticle(
                id: "article.power_outage",
                title: "Prepare for a Power Outage",
                summary: "What to have ready before the lights go out.",
                steps: [
                    "Keep a torchlight, spare batteries and a charged power bank within easy reach.",
                    "Know where your fuse box or distribution board is, and how to reset it.",
                    "Keep the fridge and freezer shut to hold the cold as long as possible.",
                    "Unplug sensitive electronics to protect them from the surge when power returns."
                ],
                sourceCitation: citation("p.60")
            ),
            ResourceArticle(
                id: "article.assist_plan",
                title: "Plan for Elderly or Disabled Household Members",
                summary: "Agree the plan in advance, while there is time to think.",
                steps: [
                    "Agree an evacuation route that accounts for mobility, hearing or vision needs.",
                    "Identify a neighbour who can check on them and assist if you are not home.",
                    "Make sure both they and the neighbour know to call 995 or 999.",
                    "Keep mobility aids, glasses and hearing aids near the main exit at night."
                ],
                sourceCitation: citation("p.41")
            )
        ])
    )

    // MARK: - Fire Safety

    private static let fireSafety = ResourceCategory(
        id: "category.fire_safety",
        title: "Fire Safety",
        subtitle: "Prevent, detect, and respond to fire",
        iconSystemName: "flame.fill",
        content: .articles([
            ResourceArticle(
                id: "article.fire_checklist",
                title: "Home Fire Safety Checklist",
                summary: "The four checks that prevent most household fires.",
                steps: [
                    "Check that wiring is not frayed and that sockets are not overloaded.",
                    "Make sure any LPG cylinder is well ventilated and kept away from heat sources.",
                    "Confirm you have a working fire extinguisher and know where it is.",
                    "Keep corridors, stairwells and escape routes clear of clutter."
                ],
                sourceCitation: citation("p.27")
            ),
            ResourceArticle(
                id: "article.smoke_detector",
                title: "Install and Maintain a Smoke Detector",
                summary: "A Home Fire Alarm Device buys you the time to get out.",
                steps: [
                    "Mount at least one detector along your main escape route.",
                    "Test it monthly using the test button.",
                    "Replace the battery every year, or as soon as it starts chirping.",
                    "Replace the whole unit at the end of its stated service life."
                ],
                sourceCitation: citation("p.31")
            ),
            ResourceArticle(
                id: "article.fire_extinguisher",
                title: "Using a Fire Extinguisher: P.A.S.S.",
                summary: "Pull, Aim, Squeeze, Sweep — and know when not to fight the fire.",
                steps: [
                    "Pull the safety pin out of the handle.",
                    "Aim the nozzle at the base of the fire, not at the flames.",
                    "Squeeze the handle to discharge.",
                    "Sweep from side to side across the base until the fire is out.",
                    "A certified dry chemical powder extinguisher covers combustible materials, flammable liquids and electrical fires.",
                    "If the fire is spreading or between you and the exit, leave instead and call 995."
                ],
                sourceCitation: citation("p.35-36")
            ),
            ResourceArticle(
                id: "article.lpg_check",
                title: "The Five-Point LPG Safety Check",
                summary: "Check your gas cylinder setup at least once a year.",
                steps: [
                    "Regulator: seated firmly and free of damage.",
                    "Hose: no cracks, splits or perishing along its length.",
                    "Cylinder: no dents, rust or bulging.",
                    "Hose clips: present and tight at both ends.",
                    "Joint connections: brush on soapy water and watch for bubbles, which mean a leak."
                ],
                sourceCitation: citation("p.28")
            ),
            ResourceArticle(
                id: "article.fire_response",
                title: "If You Discover a Fire",
                summary: "When to fight it, when to leave, and when to stay put.",
                steps: [
                    "If your clothing catches fire: stop, drop and roll to smother the flames.",
                    "If you cannot put the fire out quickly and safely, evacuate and call 995.",
                    "Use the exit stairs. Never use the lift during a fire.",
                    "Evacuate if you are on the fire floor or within two floors above it.",
                    "Otherwise stay put with doors and windows closed, unless told to leave."
                ],
                sourceCitation: citation("p.33, p.42")
            )
        ])
    )

    // MARK: - First Aid & Medical

    private static let firstAid = ResourceCategory(
        id: "category.first_aid",
        title: "First Aid & Medical",
        subtitle: "Step-by-step emergency care",
        iconSystemName: "cross.case.fill",
        content: .articles([
            ResourceArticle(
                id: "article.fast_stroke",
                title: "Recognise a Stroke: F.A.S.T.",
                summary: "Four quick checks that identify a stroke in seconds.",
                steps: [
                    "Face: ask them to smile. Does one side droop?",
                    "Arms: ask them to raise both arms. Does one drift downward?",
                    "Speech: ask them to repeat a simple phrase. Is it slurred or confused?",
                    "Time: if any check fails, call 995 immediately and note the time symptoms started."
                ],
                sourceCitation: citation("p.11")
            ),
            ResourceArticle(
                id: "article.burn_treatment",
                title: "Treating a Burn",
                summary: "Cool it properly — and avoid the common mistakes that make it worse.",
                steps: [
                    "Cool the burn under running water for at least 10 minutes.",
                    "Remove nearby jewellery or tight clothing before the area swells.",
                    "Cover loosely with a clean, non-stick dressing.",
                    "Never apply toothpaste, ice, butter or cotton wool to a burn.",
                    "Seek medical care for large, deep, or facial burns."
                ],
                sourceCitation: citation("p.9")
            ),
            ResourceArticle(
                id: "article.cpr",
                title: "CPR Step by Step",
                summary: "What to do when someone is unresponsive and not breathing.",
                steps: [
                    "Check responsiveness: tap the shoulders and shout.",
                    "Call 995, or get someone else to call while you continue.",
                    "Check for breathing for no more than 10 seconds.",
                    "If they are not breathing normally, begin chest compressions.",
                    "Push hard and fast in the centre of the chest, at least 100 per minute, about 5cm deep.",
                    "If trained and willing, give 2 rescue breaths after every 30 compressions.",
                    "Continue until help arrives, an AED is ready, or they start breathing."
                ],
                sourceCitation: citation("p.16-20")
            ),
            ResourceArticle(
                id: "article.rice_sprain",
                title: "Treating a Sprain: R.I.C.E.",
                summary: "The four steps for sprains and soft tissue injuries.",
                steps: [
                    "Rest the injured joint and stop any activity.",
                    "Ice for 15 to 20 minutes at a time, wrapped rather than applied directly to skin.",
                    "Compress gently with a bandage, not so tight that it cuts off circulation.",
                    "Elevate the limb above heart level to reduce swelling."
                ],
                sourceCitation: citation("p.12")
            ),
            ResourceArticle(
                id: "article.heimlich",
                title: "Choking: The Heimlich Manoeuvre",
                summary: "Clearing a blocked airway in a conscious adult.",
                steps: [
                    "Ask \"are you choking?\" — if they cannot speak or cough, act.",
                    "Stand behind them and put your arms around their waist.",
                    "Make a fist just above the navel and grasp it with your other hand.",
                    "Pull sharply inward and upward, repeating until the blockage clears.",
                    "If they become unresponsive, call 995 and begin CPR."
                ],
                sourceCitation: citation("p.13-14")
            )
        ])
    )

    // MARK: - Shelter & Warnings

    private static let shelterAndWarnings = ResourceCategory(
        id: "category.shelter_warnings",
        title: "Shelter & Warnings",
        subtitle: "Where to go and what the alarms mean",
        iconSystemName: "building.2.fill",
        content: .articles([
            ResourceArticle(
                id: "article.pws",
                title: "Understanding the Public Warning System",
                summary: "What each island-wide siren signal is telling you to do.",
                steps: [
                    "Alarm, a rising and falling wailing tone: move to a shelter now.",
                    "All Clear, a steady continuous tone: it is safe to leave the shelter.",
                    "Important Message, a pulsating tone: tune in to radio or TV for instructions.",
                    "The system is tested island-wide every 15 February and 15 September."
                ],
                sourceCitation: citation("p.72")
            ),
            ResourceArticle(
                id: "article.household_shelter",
                title: "Household & Storey Shelters",
                summary: "Using the shelter built into your own block.",
                steps: [
                    "Identify whether your unit has a Household Shelter or your block has a Storey Shelter.",
                    "Keep it clear enough to be usable, not packed as a storeroom.",
                    "Seal the ventilation openings and door gaps when instructed to do so.",
                    "Keep your Wi-Fi router within about 5 metres so you can still get information inside.",
                    "Store water, a torchlight and your Ready Bag nearby."
                ],
                sourceCitation: citation("p.73-74")
            ),
            ResourceArticle(
                id: "article.public_shelter",
                title: "Finding a Public Shelter",
                summary: "Where to go if you are away from home when the alarm sounds.",
                steps: [
                    "Public Shelters include MRT stations, HDB void decks and community centres.",
                    "Look for the Civil Defence shelter signage marking an official shelter.",
                    "On hearing the Alarm signal while out, head to the nearest one immediately.",
                    "Identify the shelters near your workplace and your children's school in advance."
                ],
                sourceCitation: citation("p.76")
            ),
            ResourceArticle(
                id: "article.icah",
                title: "Improvised Cover At Home (ICAH)",
                summary: "Choosing the safest spot when you have no dedicated shelter.",
                steps: [
                    "Far: as far as possible from windows, glass and exterior walls.",
                    "Enclosed: an interior space such as a corridor or windowless room.",
                    "Solid: with sturdy cover such as a strong table or a load-bearing wall.",
                    "Little combustible material: away from anything that burns easily."
                ],
                sourceCitation: citation("p.78")
            )
        ])
    )

    // MARK: - Natural Hazards & Severe Weather

    private static let naturalHazards = ResourceCategory(
        id: "category.natural_hazards",
        title: "Natural Hazards & Severe Weather",
        subtitle: "Storms, floods, tsunamis and earthquakes",
        iconSystemName: "cloud.bolt.rain.fill",
        content: .articles([
            ResourceArticle(
                id: "article.thunderstorm",
                title: "Thunderstorm Safety Indoors",
                summary: "Being indoors is not the same as being safe.",
                steps: [
                    "Avoid showering or bathing — plumbing can conduct a strike.",
                    "Avoid corded telephones and wired appliances.",
                    "Stay away from windows, doors and metal fixtures.",
                    "Unplug sensitive electronics if the storm is directly overhead."
                ],
                sourceCitation: citation("p.54")
            ),
            ResourceArticle(
                id: "article.flood_vehicle",
                title: "Floodwater: If Your Vehicle Stalls",
                summary: "Rising water rises fast — do not wait it out inside.",
                steps: [
                    "Switch on your hazard lights immediately.",
                    "Call 995 or 999 and give your exact location.",
                    "If it is safe to do so, leave the vehicle and move to higher ground.",
                    "Never try to restart the engine, and never wait inside as water rises."
                ],
                sourceCitation: citation("p.55")
            ),
            ResourceArticle(
                id: "article.flood_alerts",
                title: "Sign Up for Flood Alerts",
                summary: "Get warned before you set off, not after you are stuck.",
                steps: [
                    "Register for PUB's flood alert service for your area.",
                    "Check the myENV app for rainfall and flash flood advisories.",
                    "Set alerts for the areas you travel through, not only where you live."
                ],
                sourceCitation: citation("p.55")
            ),
            ResourceArticle(
                id: "article.tsunami",
                title: "Tsunami Warning Signs",
                summary: "Singapore's risk is low, but the warning sign is worth knowing.",
                steps: [
                    "A sudden, unusual retreat of the sea from the shore is the key natural warning.",
                    "If you see it, move to higher ground immediately and do not go down to look.",
                    "Singapore is largely shielded by surrounding landmasses, so a large tsunami is unlikely.",
                    "Coastal caution still applies during regional seismic events."
                ],
                sourceCitation: citation("p.63")
            ),
            ResourceArticle(
                id: "article.earthquake",
                title: "Earthquakes: What Actually Causes Injury",
                summary: "The shaking rarely hurts you — what it dislodges does.",
                steps: [
                    "Most injuries come from collapsing walls, shattering glass and falling objects.",
                    "Move away from windows, mirrors and unsecured furniture.",
                    "Take cover under a sturdy table and hold on.",
                    "Stay under cover until the shaking fully stops before moving."
                ],
                sourceCitation: citation("p.65")
            ),
            ResourceArticle(
                id: "article.trapped_debris",
                title: "Trapped Under Debris: How to Signal Rescuers",
                summary: "Conserve your air and energy while making yourself findable.",
                steps: [
                    "Tap on a pipe or wall in a steady, repeated rhythm.",
                    "Use a whistle if you have one — it carries much further than your voice.",
                    "Avoid shouting repeatedly: it exhausts you and risks inhaling dust.",
                    "Stay as still as possible to conserve air and energy between signals."
                ],
                sourceCitation: citation("p.67")
            )
        ])
    )

    // MARK: - Security & Community Threats

    private static let securityThreats = ResourceCategory(
        id: "category.security_threats",
        title: "Security & Community Threats",
        subtitle: "Responding to attacks and threats",
        iconSystemName: "shield.lefthalf.filled",
        content: .articles([
            ResourceArticle(
                id: "article.sgsecure",
                title: "SGSecure: Run, Hide, Tell",
                summary: "The response sequence for an attack, plus bleeding control.",
                steps: [
                    "Run: leave by the safest route and encourage others to come with you.",
                    "Hide: if you cannot run, get out of sight, stay silent and silence your phone.",
                    "Tell: once safe, call 999 with the location and what you saw.",
                    "For serious bleeding — Press: apply firm pressure directly on the wound.",
                    "Tie: bind a bandage or cloth over it to keep the pressure on.",
                    "Tell: tell responders what happened and how long the bleeding has gone on."
                ],
                sourceCitation: citation("p.101-103")
            ),
            ResourceArticle(
                id: "article.bomb_threat",
                title: "Responding to a Bomb Threat",
                summary: "What to do while the caller is still on the line.",
                steps: [
                    "Stay calm and keep the caller talking for as long as you can.",
                    "Note the exact time, the wording used, and any background noise.",
                    "Do not hang up first — leave the line open if you can.",
                    "Report to 999 immediately afterwards with everything you noted."
                ],
                sourceCitation: citation("p.89")
            ),
            ResourceArticle(
                id: "article.chemical_exposure",
                title: "Responding to Chemical Exposure",
                summary: "Do not become the second casualty.",
                steps: [
                    "Avoid contact with the substance and any contaminated surfaces.",
                    "Move away from the area, ideally upwind and uphill.",
                    "Call 995 and describe what you saw or smelled.",
                    "Follow decontamination instructions before coming into contact with others."
                ],
                sourceCitation: citation("p.83")
            )
        ])
    )

    // MARK: - Emergency Contacts

    private static let emergencyContacts = ResourceCategory(
        id: "category.emergency_contacts",
        title: "Emergency Contacts",
        subtitle: "Call or text for help, directly from the app",
        iconSystemName: "phone.fill",
        content: .contacts([
            EmergencyContact(
                id: "contact.995",
                name: "Fire & Ambulance",
                formattedNumber: "995",
                contactDescription: "Fires, medical emergencies and ambulance requests.",
                method: .call
            ),
            EmergencyContact(
                id: "contact.999",
                name: "Police",
                formattedNumber: "999",
                contactDescription: "Crimes in progress, threats to safety, or police assistance.",
                method: .call
            ),
            EmergencyContact(
                id: "contact.70995",
                name: "SMS Emergency (Fire & Ambulance)",
                formattedNumber: "70995",
                contactDescription: "For Deaf and Hard-of-Hearing users to reach fire and ambulance services.",
                method: .sms
            ),
            EmergencyContact(
                id: "contact.70999",
                name: "SMS Emergency (Police)",
                formattedNumber: "70999",
                contactDescription: "For Deaf and Hard-of-Hearing users to reach the police.",
                method: .sms
            ),
            EmergencyContact(
                id: "contact.scdf_hotline",
                name: "SCDF Hotline",
                formattedNumber: "1800 280 0000",
                contactDescription: "Non-emergency Singapore Civil Defence Force enquiries and fire hazard reports.",
                method: .call
            ),
            EmergencyContact(
                id: "contact.police_hotline",
                name: "Police Hotline",
                formattedNumber: "1800 255 0000",
                contactDescription: "Non-emergency police enquiries and information.",
                method: .call
            ),
            EmergencyContact(
                id: "contact.hdb_emsu",
                name: "HDB Essential Maintenance (EMSU)",
                formattedNumber: "1800 241 7711",
                contactDescription: "Power failures and structural defects in HDB estates.",
                method: .call
            ),
            EmergencyContact(
                id: "contact.pub",
                name: "PUB (Water)",
                formattedNumber: "1800 2255 782",
                contactDescription: "Water supply faults, leaks and flooding enquiries.",
                method: .call
            ),
            EmergencyContact(
                id: "contact.sp_powergrid",
                name: "SP PowerGrid (Electricity)",
                formattedNumber: "1800 778 8888",
                contactDescription: "Electrical faults and power supply interruptions.",
                method: .call
            ),
            EmergencyContact(
                id: "contact.city_energy",
                name: "City Energy (Piped Gas)",
                formattedNumber: "1800 752 1800",
                contactDescription: "Piped town gas leaks and supply issues.",
                method: .call
            ),
            EmergencyContact(
                id: "contact.nursefirst",
                name: "NurseFirst",
                formattedNumber: "6262 6262",
                contactDescription: "Advice from a registered nurse on where to seek non-emergency medical help.",
                method: .call
            )
        ])
    )
}
