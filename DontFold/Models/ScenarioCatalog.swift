import Foundation

/// Hot Girl CEO scenario set — girl-coded high-pressure conversations.
/// Subtitles match the wireframe verbatim where possible.
enum ScenarioCatalog {
    static let all: [Scenario] = [
        Scenario(
            id: "raise",
            title: "Asking For A Raise",
            blurb: "Boss said 'so… what did you want to talk about?'",
            setup: "You booked a 1:1 last week. You've been underpaid for 14 months. Your manager is in a decent mood today. You have 15 minutes. They lean back: 'so… what did you want to talk about?'",
            category: .money,
            difficulty: .brutal,
            aiPersona: "Manager — supportive in theory, allergic to specifics, will deflect to 'budget cycle' unless you stay direct",
            aiVoiceHint: "calm, measured, slightly evasive",
            openingLine: "So… you wanted to chat? What's on your mind?",
            userGoal: "Name a number and hold it without flinching.",
            pressureCues: [
                "hedging on the number",
                "apologising for asking",
                "lowering your ask",
                "saying 'whenever it's good for you'"
            ],
            confidenceCues: [
                "named a concrete figure",
                "tied it to impact you delivered",
                "asked for a follow-up date"
            ]
        ),
        Scenario(
            id: "mom-moving",
            title: "Telling Mom You're Moving",
            blurb: "She thinks you're 'coming home for a bit'. You're not.",
            setup: "Mom's on the phone, already planning your old bedroom and which neighbour's daughter to set you up with. She's been telling everyone you're 'coming home for a bit'. You're moving cities for the new job. You need to tell her right now.",
            category: .life,
            difficulty: .brutal,
            aiPersona: "Mom — loving, guilt-fluent, switches to soft sighs and 'I just thought…' on a dime",
            aiVoiceHint: "warm, older, quietly disappointed when she lands the guilt",
            openingLine: "So I told Marta from next door you'd be here by Sunday — she's so excited to see you, sweetheart.",
            userGoal: "Say you're moving — without softening it into 'maybe' or 'we'll see'.",
            pressureCues: [
                "saying 'we'll see'",
                "promising visits you don't mean",
                "blaming work to dodge the decision",
                "matching her tone of disappointment"
            ],
            confidenceCues: [
                "stated the move clearly",
                "named a specific date",
                "stayed warm without backing down"
            ]
        ),
        Scenario(
            id: "him",
            title: "Hard Convo With Him",
            blurb: "He texted 'wyd'. It's been three weeks.",
            setup: "Three weeks of crumbs. He texted 'wyd' at 11:47pm. You opened it on purpose. You're done — and this is the conversation where you say so without leaving the door cracked open.",
            category: .social,
            difficulty: .brutal,
            aiPersona: "Him — performatively confused, will pivot to 'i thought we were chill', then 'damn ok' when called",
            aiVoiceHint: "casual, slightly cocky, plays dumb under pressure",
            openingLine: "wyd",
            userGoal: "Tell him you're done — no 'maybe later', no soft exit, no door left open.",
            pressureCues: [
                "'i think we should talk'",
                "'maybe later'",
                "softening with lol / 😅",
                "asking for closure you don't owe him"
            ],
            confidenceCues: [
                "stated you're done in one line",
                "didn't justify or apologise",
                "no door left open"
            ]
        ),
        Scenario(
            id: "bridesmaid",
            title: "Saying No To Bridesmaid",
            blurb: "Dress is $480. Bachelorette is in Tulum. You're broke.",
            setup: "It's your college roommate. The dress is $480, the bachelorette is in Tulum, and she's about to FaceTime you 'just to chat'.",
            category: .social,
            difficulty: .spicy,
            aiPersona: "Best friend / bride — sweet, then negotiating, then quietly hurt — fluent in 'i can help with the dress'",
            aiVoiceHint: "warm, fast, switches to wounded when she doesn't get a yes",
            openingLine: "babe i literally can't get married without you 😭 it's just one dress",
            userGoal: "Decline without apologising, hedging, or offering a cheaper version of yes.",
            pressureCues: [
                "'I'll think about it'",
                "'things have been crazy'",
                "inventing a wedding to skip it",
                "half-yes"
            ],
            confidenceCues: [
                "clear no on the first turn",
                "warm tone without softening the answer",
                "no counter-offer"
            ]
        ),
        Scenario(
            id: "sephora",
            title: "Sephora Refund Drama",
            blurb: "They sent the wrong shade. Twice.",
            setup: "You ordered foundation. They sent the wrong shade. You ordered again. They sent the wrong shade again. Customer service just opened the chat: 'Hi! How can I help today?'",
            category: .food,
            difficulty: .mild,
            aiPersona: "CS rep — polite, scripted, will try to re-ship instead of refund and offer a 10% coupon",
            aiVoiceHint: "upbeat, scripted, faintly tired",
            openingLine: "Hi babe! 💕 How can I help you today?",
            userGoal: "Get a full refund — not a re-ship, not a coupon.",
            pressureCues: [
                "accepting a re-ship",
                "saying 'it's fine, just send it again'",
                "agreeing to a coupon instead",
                "over-explaining why you're frustrated"
            ],
            confidenceCues: [
                "asked for a refund by name",
                "referenced both wrong orders",
                "stayed polite without backing off"
            ]
        ),
    ]

    static func featured() -> [Scenario] {
        Array(all.prefix(3))
    }

    static func by(category: ScenarioCategory) -> [Scenario] {
        all.filter { $0.category == category }
    }
}
