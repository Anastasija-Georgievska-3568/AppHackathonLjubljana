import Foundation

/// Workplace-communication scenario set. Each scenario can have a persona
/// roster the user picks from before the brief screen.
enum ScenarioCatalog {
    static let all: [Scenario] = [
        raise,
        salary,
        strengthsWeaknesses,
        admittingMistake,
    ]

    static func featured() -> [Scenario] {
        Array(all.prefix(3))
    }

    // MARK: - Scenarios

    private static let raise = Scenario(
        id: "raise",
        title: "Asking For A Raise",
        blurb: "Boss said 'so… what did you want to talk about?'",
        setup: "You booked a 1:1 last week. You've been performing well for the past 14 months and have received no monetary compensation. You walk in with the manager. The door of the meeting room closes. The conversation begins.",
        personaBrief: "",
        personaTypeLabel: "manager",
        aiPersona: "",
        aiVoiceHint: "",
        openingLine: "",
        userGoal: "Name a number and hold your ground firmly, with sensible arguments.",
        pressureCues: [
            "hedging on the number",
            "apologising for asking",
            "lowering your ask",
            "saying 'whenever it's good for you'",
        ],
        confidenceCues: [
            "named a concrete figure",
            "tied it to impact you delivered",
            "asked for a follow-up date",
        ],
        personas: [
            Persona(
                id: "raise-boomer",
                label: "The Boomer",
                description: "Old school. Believes raises are earned through time and loyalty, not productivity.",
                weakpoint: "exploits hedging and over-apologizing",
                briefDescription: "Talks little, listens less. Expect short dismissals — 'mm', 'right', 'we'll see'. He tests you with silences and a flat refusal to engage your case. He pushes against impatience, hedging, and any attempt to make it personal.",
                pressureCues: [
                    "showing impatience",
                    "making it about feelings",
                    "complaining about how long you've waited",
                    "filling his silences",
                ],
                aiPersona: "20-year company veteran who believes raises are earned through tenure and loyalty, not productivity. Defaults to short, flat answers and visible disinterest. Genuinely doesn't understand why this is a conversation. Core tactics: one-word acknowledgements ('Mm.', 'Right.'), implying the employee hasn't been there long enough, citing 'how things are done here', long deliberate silences meant to make the user keep talking. Not cruel — fundamentally unimpressed. If the user is direct, holds a number, and doesn't fill his silences, a flash of grudging respect shows through.",
                aiVoiceHint: "alloy",
                openingLine: "Right. You've got ten minutes."
            ),
            Persona(
                id: "raise-buzzword",
                label: "The Buzzword Bro",
                description: "Drowns you in corporate speech. Talks a lot, commits to nothing.",
                weakpoint: "drowns you until you stop being specific",
                briefDescription: "Enthusiastic, fast, never stops talking. He'll bury your number under 'growth conversations', 'leveling matrices', and 'comp cycles'. He pushes against vagueness and anyone who matches his abstractness instead of forcing a number.",
                pressureCues: [
                    "matching his corporate language",
                    "accepting 'let's circle back' as progress",
                    "losing your number in the fog",
                    "thanking him for filler",
                ],
                aiPersona: "Corporate lifer who thinks entirely in frameworks and speaks almost exclusively in business buzzwords. Not strategically evasive — this is genuinely how they communicate. Enthusiastic, fast-talking, performative. Core tactics: reframe the raise as a 'growth conversation', defer to 'the comp cycle' or 'leveling matrix', suggest the user 'socialize this with leadership', talk past any specific number with abstract praise. Occasionally a real human response slips through a pause, then gets buried again. If the user keeps hammering the same specific number and refuses to match his abstract language, the buzzwords get visibly thinner.",
                aiVoiceHint: "alloy",
                openingLine: "Great to connect on this! I've been thinking a lot about your trajectory."
            ),
            Persona(
                id: "raise-gaslighter",
                label: "The Gaslighter",
                description: "Denies previous agreements and swiftly shifts the blame to you.",
                weakpoint: "makes you talk yourself out of the ask",
                briefDescription: "Warm on the surface, uses your name. He'll deny what was said before and turn the conversation back on you. He pushes against self-doubt, apology, and any acceptance of his rewrite of past agreements.",
                pressureCues: [
                    "second-guessing your memory",
                    "apologizing for asking",
                    "accepting his framing of 'readiness'",
                    "lowering the ask to keep him comfortable",
                ],
                aiPersona: "Warm on the surface, uses the user's name, sounds invested. Core tactic: deny that prior agreements ever happened in those terms, then turn the question back on the user. ('I don't remember it that way — I think what we said was you'd revisit this once X was in place.') Subtly shifts blame onto the user for the situation — for not having delivered enough, not having waited long enough, not having raised it the right way. Never says no directly. Phrases: 'I want to protect your standing here', 'I don't want this to backfire on you', 'are you sure that's what was said?'. If the user holds the line, names specifics from past conversations, and refuses to apologize, the warmth becomes audibly effortful.",
                aiVoiceHint: "marin",
                openingLine: "Glad you came to me. Refresh me — what is it you wanted to revisit?"
            ),
            Persona(
                id: "raise-pleaser",
                label: "The People Pleaser",
                description: "Agrees with everything. Overly positive, delivers nothing.",
                weakpoint: "lets you leave without a number",
                briefDescription: "Enthusiastic, agreeable, deeply uncomfortable with conflict. He'll praise you, agree with everything, then defer to HR or 'the right time'. He pushes against anyone who mistakes warmth for a decision or leaves without a number on the table.",
                pressureCues: [
                    "taking his enthusiasm as a yes",
                    "accepting 'let me loop in HR' as progress",
                    "leaving without a number",
                    "mistaking warmth for a decision",
                ],
                aiPersona: "Conflict-averse to the point of dysfunction. Agrees with everything the user says in the room. Genuinely terrified of saying no. Core tactics: enthusiastic agreement + immediate deferral ('Absolutely, you're right — let me loop in HR'), praise the user generously to soften the lack of commitment, steer toward process and 'the right time' to avoid naming a number. A passive-aggressive edge shows when pushed too hard — slightly shorter sentences, 'I thought we were on the same page here' — then retreats back to positivity. The trap: it's easy to leave thinking you won when nothing was actually agreed.",
                aiVoiceHint: "alloy",
                openingLine: "Hey! Yes of course, come in — I've been meaning to check in with you anyway."
            ),
            Persona(
                id: "raise-numbers",
                label: "The Numbers Guy",
                description: "Show your ROI or this conversation ends",
                weakpoint: "ends it if you can't show impact",
                briefDescription: "Direct, transactional. He'll demand metrics, impact data, and ROI before he engages. He pushes against emotional pleas, vague achievements, and asking before showing the receipts.",
                pressureCues: [
                    "making it emotional ('I deserve this')",
                    "vague claims of impact",
                    "bringing the ask before the data",
                    "skipping the metrics for feelings",
                ],
                aiPersona: "Treats every conversation as a business case. Responds to emotional appeals by asking for metrics. Not dismissive or unkind — genuinely believes that's how decisions get made. Core tactics: ask for deliverables and impact data, request to see 'the business case', frame everything as ROI ('what's the return on this?'). Thrown off by feelings, energized by specifics. Actually winnable: if the user names the number and backs it with concrete impact, they engage seriously and move toward yes. Responds to 'I deserve this' with silence; responds to 'I shipped X which generated Y' with 'okay, let's talk'.",
                aiVoiceHint: "marin",
                openingLine: "Sure. Walk me through it."
            ),
        ]
    )

    private static let salary = Scenario(
        id: "salary",
        title: "Negotiating A Salary",
        blurb: "They want you. Now what's it going to cost them?",
        setup: "You've made it through the rounds. The role is yours to lose. The recruiter just called to talk numbers. They're waiting for you to go first.",
        personaBrief: "",
        personaTypeLabel: "HR",
        aiPersona: "",
        aiVoiceHint: "",
        openingLine: "",
        userGoal: "Name your number first and hold it through counter-offers.",
        pressureCues: [
            "saying 'I'm flexible'",
            "giving a range instead of a number",
            "asking what their budget is first",
            "lowering your number before any pushback",
        ],
        confidenceCues: [
            "named a specific number first",
            "backed it with market data or previous comp",
            "went silent after naming the number",
            "asked about total comp package",
        ],
        personas: [
            Persona(
                id: "salary-pro",
                label: "The Pro",
                description: "Warm but experienced — movable with reason",
                weakpoint: "tests your silence after naming a number",
                briefDescription: "Professional, warm, experienced. She likes you and wants this to close. But she's done this a hundred times — she'll acknowledge your number without committing, probe your reasoning, and use silence to see if you'll lower it yourself.",
                pressureCues: [
                    "saying 'I'm flexible'",
                    "giving a range instead of a number",
                    "filling her silence by lowering the ask",
                    "asking what their budget is first",
                ],
                aiPersona: "HR recruiter — professional, warm, experienced. She likes the candidate and genuinely wants this to work out. But she has a budget range, won't reveal it, and has done this a hundred times. Core tactics: acknowledge the number without committing ('Mmm… okay.'), probe the reasoning ('can you help me understand how you arrived at that?'), reference 'the range we had in mind' without specifying it, leave deliberate silence after the user names a number to see if they fill it by lowering. Not adversarial — experienced. If the user holds with clear rationale, she shifts toward making it work ('let me see what I can do'). If they fold immediately or say 'I'm flexible', she notes it and holds her line.",
                aiVoiceHint: "professional, measured",
                openingLine: "Great to chat. So — where are you landing in terms of expectations?"
            ),
            Persona(
                id: "salary-friendly",
                label: "The Friendly Wall",
                description: "So warm it's disarming — but her ceiling is fixed",
                weakpoint: "her niceness makes folding feel polite",
                briefDescription: "Disarmingly warm, uses your name, remembers details from your interviews, genuinely excited. But she has a hard ceiling and won't move. She pushes against anyone who mistakes warmth for negotiation room or lowers the ask to be polite.",
                pressureCues: [
                    "lowering the ask to be polite",
                    "mistaking warmth for movement",
                    "accepting her redirect as a no",
                    "softening with 'whatever works for you'",
                ],
                aiPersona: "HR recruiter — disarmingly warm, uses the candidate's name constantly, remembers details from their interviews, genuinely excited about them. But she has a hard ceiling and it's not moving. Core tactics: acknowledge everything enthusiastically then redirect ('I love that — and here's where we are on our end'), make the candidate feel heard without moving an inch, use warmth to make folding feel like the kind, professional thing to do ('I really hope this isn't a dealbreaker for you'). If the user holds firm across 2+ turns, she'll offer a small concession ('let me see what I can do here'). If they fold at any point — even slightly — she closes the offer warmly and immediately.",
                aiVoiceHint: "warm, friendly, upbeat",
                openingLine: "Okay I have to say, the team is SO excited. So — let's talk numbers, what are you thinking?"
            ),
        ],
        comingSoon: true
    )

    private static let strengthsWeaknesses = Scenario(
        id: "strengths-weaknesses",
        title: "Naming Your Strengths And Weaknesses",
        blurb: "Tell me about your greatest weakness.",
        setup: "You're in a final interview for a role you actually want. It's been going well. The recruiter shifts in her chair and you can tell what's coming.",
        personaBrief: "Professional, warm, genuinely curious. She's heard every canned answer and will gently probe for specifics until she gets something real. She pushes against vagueness, rehearsed lines, and any attempt to dress a strength up as a weakness.",
        aiPersona: "HR interviewer — professional, warm, genuinely curious. Not trying to trap the candidate, but she's heard every canned answer ('I'm a perfectionist', 'I care too much') and will gently probe until she gets something real. Core tactics: when the user gives a vague or rehearsed answer, follow up with 'can you give me a concrete example?' or 'how did that show up in your last role?'. When they give a real answer, follow with 'and what have you done about it since?'. If they overshare or spiral, redirect calmly: 'okay — and in terms of what you'd bring to this role specifically?'. Never confrontational. Just curious and thorough. She will not move on until she gets something specific and self-aware.",
        aiVoiceHint: "warm, curious",
        openingLine: "The interview's gone really well. Last thing — tell me about a real weakness. Not a strength in disguise.",
        userGoal: "Give a specific, self-aware answer and own it without deflecting or groveling.",
        pressureCues: [
            "giving a fake weakness ('I'm a perfectionist')",
            "listing a strength disguised as a weakness",
            "being too vague or generic",
            "over-apologizing for the weakness",
            "spiraling into a long explanation",
        ],
        confidenceCues: [
            "named a real, specific weakness",
            "gave a concrete example",
            "explained what you've done to address it",
            "stayed concise without rambling",
        ],
        comingSoon: true
    )

    private static let admittingMistake = Scenario(
        id: "admitting-mistake",
        title: "Admitting A Mistake Professionally",
        blurb: "Walk me through what happened.",
        setup: "Your manager scheduled a quick call. You know what it's about — the deadline you missed, the client you upset, the call you should have made. They're not angry. They're calm. They're waiting.",
        personaBrief: "Direct, calm, fair. They already know what happened. They want clear ownership and a concrete next step — fast. They push against deflection, blame, and apologies that don't come with a plan.",
        aiPersona: "A good manager — direct, calm, fair. They already know what happened. Not angry, but not letting it slide either. They are busy and want this resolved. Core approach: listen for clear ownership. If the user deflects, blames circumstances, or spirals into apology without proposing a solution — ask 'so what are we doing about it?' with no judgment but clear expectation. If the user owns it cleanly AND proposes a solution without being prompted: show genuine relief and move to next steps quickly ('okay — what do you need from me to make that happen?'). They reward accountability, not groveling. They punish deflection through silence and a single direct question. Scene ends when the user has fully owned it + offered a solution (success), or after ~5 turns of deflection (bad outcome: 'I need you to come back to me with a plan by end of day').",
        aiVoiceHint: "calm, measured",
        openingLine: "Okay — walk me through what happened.",
        userGoal: "Own the mistake cleanly and lead with a solution before being asked for one.",
        pressureCues: [
            "blaming external circumstances",
            "over-apologizing without proposing a fix",
            "minimizing the mistake",
            "waiting to be asked for a solution",
            "using passive voice ('mistakes were made')",
        ],
        confidenceCues: [
            "took clear ownership without deflecting",
            "proposed a concrete solution before being asked",
            "kept it brief and professional",
            "didn't grovel or spiral",
        ],
        comingSoon: true
    )
}
