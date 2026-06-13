import Foundation

struct Persona: Hashable, Identifiable, Codable {
    let id: String
    let label: String
    let description: String        // short hook for the picker card
    let weakpoint: String          // ⚠ chip on the picker card
    let briefDescription: String   // long form for the "the persona" brief card
    let pressureCues: [String]     // persona-specific avoid-this list
    let aiPersona: String          // injected into Gemini system prompt
    let aiVoiceHint: String        // routed to TTS voice profile
    let openingLine: String        // AI's first spoken line
}

struct Scenario: Hashable, Identifiable, Codable {
    let id: String
    let title: String
    let blurb: String              // one-liner for cards
    let setup: String              // longer scene description (Brief screen)
    let personaBrief: String       // "the persona" card content when no picker
    let personaLabel: String       // shown under title on the challenge screen
    let personaTypeLabel: String   // qualifier for the home badge ("manager", "HR", …)
    let aiPersona: String          // injected into Gemini system prompt
    let aiVoiceHint: String        // routed to TTS voice profile
    let openingLine: String        // AI's first spoken line
    let userGoal: String           // what the user is trying to accomplish
    let pressureCues: [String]     // "avoid this" list — phrases / moves
    let confidenceCues: [String]   // things that read as holding the line
    let personas: [Persona]?       // optional roster the user picks from
    let comingSoon: Bool           // dim + lock + "coming soon" tag on Home

    init(
        id: String,
        title: String,
        blurb: String,
        setup: String,
        personaBrief: String = "",
        personaLabel: String = "",
        personaTypeLabel: String = "",
        aiPersona: String,
        aiVoiceHint: String,
        openingLine: String,
        userGoal: String,
        pressureCues: [String],
        confidenceCues: [String],
        personas: [Persona]? = nil,
        comingSoon: Bool = false
    ) {
        self.id = id
        self.title = title
        self.blurb = blurb
        self.setup = setup
        self.personaBrief = personaBrief
        self.personaLabel = personaLabel
        self.personaTypeLabel = personaTypeLabel
        self.aiPersona = aiPersona
        self.aiVoiceHint = aiVoiceHint
        self.openingLine = openingLine
        self.userGoal = userGoal
        self.pressureCues = pressureCues
        self.confidenceCues = confidenceCues
        self.personas = personas
        self.comingSoon = comingSoon
    }

    /// Bakes a selected persona into a copy of the scenario so downstream code
    /// reads the persona's voice, opening line, brief, label, and avoid-this
    /// list as if they were the scenario's own.
    func resolved(with persona: Persona) -> Scenario {
        Scenario(
            id: id,
            title: title,
            blurb: blurb,
            setup: setup,
            personaBrief: persona.briefDescription,
            personaLabel: persona.label,
            personaTypeLabel: personaTypeLabel,
            aiPersona: persona.aiPersona,
            aiVoiceHint: persona.aiVoiceHint,
            openingLine: persona.openingLine,
            userGoal: userGoal,
            pressureCues: persona.pressureCues,
            confidenceCues: confidenceCues,
            personas: nil,
            comingSoon: comingSoon
        )
    }
}
