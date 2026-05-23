import Foundation

enum ScenarioCatalog {
    static let all: [Scenario] = [
        Scenario(
            id: "interview-firstjob",
            title: "First Job Interview",
            blurb: "They asked 'tell me about yourself' and you froze.",
            setup: "It's the entry-level role you actually want. The hiring manager is on Zoom, slightly behind schedule, and has another call in 20 minutes. They open with 'so… tell me about yourself.'",
            category: .career,
            difficulty: .spicy,
            aiPersona: "Hiring manager — friendly but pressed for time, asks crisp follow-ups, drops in light skepticism when answers wander",
            aiVoiceHint: "warm, mid-pitch, lightly impatient",
            openingLine: "Hey — thanks for hopping on. I've got a hard stop in 20, so let's just dive in. Tell me about yourself.",
            userGoal: "Land the second interview without sounding like a LinkedIn bio.",
            pressureCues: ["filler words", "rambling", "apologies", "vague claims"],
            confidenceCues: ["concrete example", "clear structure", "named outcome"]
        ),
        Scenario(
            id: "salary-raise",
            title: "Asking For A Raise",
            blurb: "Your boss said 'so… what did you want to talk about?'",
            setup: "You booked a 1:1 last week. You've been underpaid for 14 months. Your manager is in a decent mood today. You have 15 minutes. They lean back: 'so… what did you want to talk about?'",
            category: .money,
            difficulty: .brutal,
            aiPersona: "Manager — supportive in theory, allergic to specifics, will deflect to 'budget cycle' unless you stay direct",
            aiVoiceHint: "calm, measured, slightly evasive",
            openingLine: "So… you wanted to chat? What's on your mind?",
            userGoal: "Name a number and hold it without flinching.",
            pressureCues: ["hedging", "apologizing", "no number", "lowering the ask"],
            confidenceCues: ["named figure", "tied to impact", "asked for follow-up date"]
        ),
        Scenario(
            id: "landlord-radiator",
            title: "Texting The Landlord",
            blurb: "The radiator's been broken for nine days.",
            setup: "It's been cold for nine days. You've sent two texts. He replied 'will look into it' five days ago. You're drafting message three. He just typed '…' for 30 seconds and stopped.",
            category: .life,
            difficulty: .spicy,
            aiPersona: "Landlord — vaguely apologetic, master of soft deflection, drops 'I'll see what I can do' a lot",
            aiVoiceHint: "casual, slightly older, breezy",
            openingLine: "Hey yeah sorry just super slammed this week — what's up again?",
            userGoal: "Get a concrete date for the repair, in writing.",
            pressureCues: ["over-apologizing", "letting it slide", "accepting vague answers"],
            confidenceCues: ["asked for a date", "referenced prior messages", "stayed polite but firm"]
        ),
        Scenario(
            id: "appointment-doctor",
            title: "Booking A Doctor Appointment",
            blurb: "Phone call. Hold music. The receptionist sighs.",
            setup: "You finally psyched yourself up to call. The receptionist picks up on the second ring sounding like she's already done with today. 'Hello, Dr. Petrov's office, how can I help.'",
            category: .phone,
            difficulty: .mild,
            aiPersona: "Receptionist — efficient, tired, will not slow down for you",
            aiVoiceHint: "fast, clipped, not unfriendly but in a hurry",
            openingLine: "Dr. Petrov's office, how can I help.",
            userGoal: "Book the appointment in under 90 seconds without backing down.",
            pressureCues: ["mumbling", "long pauses", "second-guessing"],
            confidenceCues: ["clear reason for visit", "stated availability", "asked for next steps"]
        ),
        Scenario(
            id: "food-wrongorder",
            title: "Wrong Food, Crowded Restaurant",
            blurb: "You ordered the carbonara. This is not carbonara.",
            setup: "Saturday night. The place is packed. You ordered carbonara. This is clearly NOT carbonara. The server breezes by and asks 'everything good?'",
            category: .food,
            difficulty: .mild,
            aiPersona: "Server — friendly, busy, slightly defensive if challenged",
            aiVoiceHint: "upbeat, fast, just-keeping-it-together",
            openingLine: "Hey hey — everything good here?",
            userGoal: "Send it back without apologizing for existing.",
            pressureCues: ["apologizing", "minimizing", "saying 'it's fine'"],
            confidenceCues: ["direct statement", "no over-explanation", "polite firmness"]
        ),
        Scenario(
            id: "phone-bank",
            title: "Calling Your Bank About A Charge",
            blurb: "There's a $47 charge you don't recognize.",
            setup: "You spotted a $47 charge from somewhere you've never been. You called the bank. After 11 minutes of hold music, a real person picks up. 'Thank you for holding, how can I help you today.'",
            category: .phone,
            difficulty: .spicy,
            aiPersona: "Bank agent — scripted, polite, will try to get you off the call quickly with a vague resolution",
            aiVoiceHint: "neutral, professional, scripted cadence",
            openingLine: "Thanks for your patience — how can I help you today?",
            userGoal: "Get the charge reversed AND the reason documented.",
            pressureCues: ["accepted first vague answer", "didn't get a reference number"],
            confidenceCues: ["asked for reference number", "asked for callback if not resolved"]
        ),
        Scenario(
            id: "social-noplus",
            title: "Saying No To Plans",
            blurb: "Your friend really wants you to come. You really don't.",
            setup: "Your friend is texting about a thing tonight. You don't want to go. They are persistent. They've already started bargaining.",
            category: .social,
            difficulty: .mild,
            aiPersona: "Best friend — caring but persistent, will negotiate, knows your patterns",
            aiVoiceHint: "warm, playful, won't let you off the hook easily",
            openingLine: "okay but you HAVE to come tonight — even just for an hour. please.",
            userGoal: "Say no clearly without lying or over-justifying.",
            pressureCues: ["fake excuses", "soft maybes", "guilt-spiraling"],
            confidenceCues: ["clear no", "kind tone", "no over-explaining"]
        ),
        Scenario(
            id: "career-quit",
            title: "Telling Your Boss You're Quitting",
            blurb: "You have the offer. You called the meeting. It is now.",
            setup: "You accepted the new offer last night. You scheduled '15-min sync' for today. They sit down: 'what's up?'",
            category: .career,
            difficulty: .brutal,
            aiPersona: "Manager — caught off guard, will try guilt, then counter-offer, then guilt again",
            aiVoiceHint: "measured, then disappointed, then negotiating",
            openingLine: "Hey — sorry, just grabbed a coffee. What's up?",
            userGoal: "Resign cleanly. No apologies for leaving. Confirm last day.",
            pressureCues: ["wavering", "apologizing for the decision", "leaving it open"],
            confidenceCues: ["clear last day", "thanked them genuinely", "didn't take counter-offer bait"]
        ),
    ]

    static func featured() -> [Scenario] {
        Array(all.prefix(3))
    }

    static func by(category: ScenarioCategory) -> [Scenario] {
        all.filter { $0.category == category }
    }
}
