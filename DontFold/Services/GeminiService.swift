import Foundation

// MARK: - Public response shapes

struct AITurnResponse: Codable, Sendable {
    let say: String
    let pressureDelta: Int
    let confidenceDelta: Int
    let callout: String?
    let shouldEnd: Bool
}

struct AIVerdict: Codable, Sendable {
    let verdictTitle: String
    let verdictVibe: String
    let oneLinerToShare: String
    let highlights: [String]
    let stats: [VerdictStat]

    struct VerdictStat: Codable, Sendable {
        let label: String
        let value: String
        let detail: String?
    }
}

enum GeminiError: LocalizedError {
    case missingKey
    case http(Int, String)
    case decoding(String)
    case empty

    var errorDescription: String? {
        switch self {
        case .missingKey: "No Gemini API key found. Add GEMINI_API_KEY to Info.plist or set the env var."
        case .http(let code, let body): "Gemini returned HTTP \(code): \(body)"
        case .decoding(let s): "Couldn't decode Gemini response: \(s)"
        case .empty: "Gemini returned an empty response."
        }
    }
}

actor GeminiService {
    static let shared = GeminiService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Turn (during conversation)

    func nextTurn(scenario: Scenario, history: [Turn]) async throws -> AITurnResponse {
        guard let key = GeminiConfig.apiKey else {
            return MockGemini.nextTurn(scenario: scenario, history: history)
        }
        let systemPrompt = Prompts.turnSystemPrompt(scenario: scenario)
        let contents = Self.contents(from: history)
        let body = GeminiRequest(
            systemInstruction: .init(parts: [.init(text: systemPrompt)]),
            contents: contents,
            generationConfig: .init(
                temperature: 0.85,
                topP: 0.9,
                maxOutputTokens: 400,
                responseMimeType: "application/json",
                responseSchema: turnSchema
            )
        )
        let raw = try await call(body: body, apiKey: key)
        do {
            let cleaned = Self.extractJSON(from: raw)
            let data = Data(cleaned.utf8)
            return try JSONDecoder().decode(AITurnResponse.self, from: data)
        } catch {
            throw GeminiError.decoding("\(error.localizedDescription) — raw: \(raw.prefix(300))")
        }
    }

    // MARK: - Verdict (at end of session)

    func finalVerdict(scenario: Scenario, transcript: [Turn], finalPressure: Double, finalConfidence: Double) async throws -> AIVerdict {
        guard let key = GeminiConfig.apiKey else {
            return MockGemini.finalVerdict(scenario: scenario, transcript: transcript, finalPressure: finalPressure, finalConfidence: finalConfidence)
        }
        let systemPrompt = Prompts.verdictSystemPrompt(scenario: scenario)
        let userText = Prompts.verdictUserPrompt(transcript: transcript, finalPressure: finalPressure, finalConfidence: finalConfidence)
        let body = GeminiRequest(
            systemInstruction: .init(parts: [.init(text: systemPrompt)]),
            contents: [.init(role: "user", parts: [.init(text: userText)])],
            generationConfig: .init(
                temperature: 0.9,
                topP: 0.9,
                maxOutputTokens: 700,
                responseMimeType: "application/json",
                responseSchema: verdictSchema
            )
        )
        let raw = try await call(body: body, apiKey: key)
        do {
            let cleaned = Self.extractJSON(from: raw)
            return try JSONDecoder().decode(AIVerdict.self, from: Data(cleaned.utf8))
        } catch {
            throw GeminiError.decoding("\(error.localizedDescription) — raw: \(raw.prefix(300))")
        }
    }

    // MARK: - HTTP plumbing

    private func call(body: GeminiRequest, apiKey: String) async throws -> String {
        let url = URL(string: "\(GeminiConfig.endpointBase)/\(GeminiConfig.model):generateContent?key=\(apiKey)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        req.timeoutInterval = 30

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw GeminiError.http(0, "no response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw GeminiError.http(http.statusCode, String(body.prefix(400)))
        }
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates?.first?.content?.parts?.compactMap({ $0.text }).joined(),
              !text.isEmpty else {
            throw GeminiError.empty
        }
        return text
    }

    private static func contents(from history: [Turn]) -> [GeminiRequest.Content] {
        history.map { turn in
            GeminiRequest.Content(
                role: turn.speaker == .ai ? "model" : "user",
                parts: [.init(text: turn.text)]
            )
        }
    }

    /// Models sometimes wrap JSON in ```json fences. Strip them.
    private static func extractJSON(from raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            if let firstNewline = s.firstIndex(of: "\n") {
                s = String(s[s.index(after: firstNewline)...])
            }
            if s.hasSuffix("```") {
                s = String(s.dropLast(3))
            }
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Schemas (Gemini structured output)

    private let turnSchema: GeminiRequest.Schema = .init(
        type: "OBJECT",
        properties: [
            "say": .init(type: "STRING"),
            "pressureDelta": .init(type: "INTEGER"),
            "confidenceDelta": .init(type: "INTEGER"),
            "callout": .init(type: "STRING", nullable: true),
            "shouldEnd": .init(type: "BOOLEAN"),
        ],
        required: ["say", "pressureDelta", "confidenceDelta", "shouldEnd"],
        items: nil
    )

    private let verdictSchema: GeminiRequest.Schema = .init(
        type: "OBJECT",
        properties: [
            "verdictTitle": .init(type: "STRING"),
            "verdictVibe": .init(type: "STRING"),
            "oneLinerToShare": .init(type: "STRING"),
            "highlights": .init(
                type: "ARRAY",
                items: .init(type: "STRING")
            ),
            "stats": .init(
                type: "ARRAY",
                items: .init(
                    type: "OBJECT",
                    properties: [
                        "label": .init(type: "STRING"),
                        "value": .init(type: "STRING"),
                        "detail": .init(type: "STRING", nullable: true),
                    ],
                    required: ["label", "value"],
                    items: nil
                )
            ),
        ],
        required: ["verdictTitle", "verdictVibe", "oneLinerToShare", "highlights", "stats"],
        items: nil
    )
}

// MARK: - Gemini REST wire format

private struct GeminiRequest: Encodable {
    var systemInstruction: SystemInstruction?
    var contents: [Content]
    var generationConfig: GenerationConfig?

    struct SystemInstruction: Encodable {
        var parts: [Part]
    }
    struct Content: Encodable {
        var role: String
        var parts: [Part]
    }
    struct Part: Encodable {
        var text: String
    }
    struct GenerationConfig: Encodable {
        var temperature: Double?
        var topP: Double?
        var maxOutputTokens: Int?
        var responseMimeType: String?
        var responseSchema: Schema?
    }
    indirect enum SchemaType: String, Encodable {
        case object, array, string, integer, boolean, number
    }
    struct Schema: Encodable {
        var type: String
        var properties: [String: Schema]?
        var required: [String]?
        var items: SchemaItem?
        var nullable: Bool?

        init(
            type: String,
            properties: [String: Schema]? = nil,
            required: [String]? = nil,
            items: SchemaItem? = nil,
            nullable: Bool? = nil
        ) {
            self.type = type
            self.properties = properties
            self.required = required
            self.items = items
            self.nullable = nullable
        }
    }
    indirect enum SchemaItem: Encodable {
        case nested(Schema)
        init(type: String, properties: [String: Schema]? = nil, required: [String]? = nil, items: SchemaItem? = nil, nullable: Bool? = nil) {
            self = .nested(Schema(type: type, properties: properties, required: required, items: items, nullable: nullable))
        }
        func encode(to encoder: Encoder) throws {
            switch self {
            case .nested(let s): try s.encode(to: encoder)
            }
        }
    }
}

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    struct Candidate: Decodable {
        let content: ContentBlock?
    }
    struct ContentBlock: Decodable {
        let parts: [PartBlock]?
    }
    struct PartBlock: Decodable {
        let text: String?
    }
}

// MARK: - Prompts

private enum Prompts {
    static func turnSystemPrompt(scenario: Scenario) -> String {
        """
        You are role-playing a character in a Gen-Z communication-pressure-test app called "Don't Fold".

        ROLE: \(scenario.aiPersona)
        SCENE: \(scenario.setup)
        USER'S GOAL: \(scenario.userGoal)

        Your behavior in role:
        - Stay in character, never break the fourth wall.
        - Be realistic, not cruel. Mildly impatient. Push the user when they get vague.
        - Keep your spoken line to 1–2 sentences. No monologues.
        - If the user over-explains or apologizes unnecessarily, react like a real person (cut in, glance away).
        - If the user is clear and confident, ease off — but don't suddenly become best friends.

        Watch for and react to these pressure cues from the user:
        \(scenario.pressureCues.map { "- \($0)" }.joined(separator: "\n"))

        Watch for and reward these confidence cues:
        \(scenario.confidenceCues.map { "- \($0)" }.joined(separator: "\n"))

        Scoring rules — return JSON:
        - say: your in-character spoken response, 1–2 sentences max
        - pressureDelta: integer in [-20, +30]. Increase when user folds, decrease when user is composed.
        - confidenceDelta: integer in [-30, +20]. Reward clarity, penalize hedging.
        - callout: optional 1-line Gen-Z sass observation about what the user JUST did wrong — only when it's funny/true (e.g. "you apologized before explaining the issue"). Null if user did fine.
        - shouldEnd: true when the scene reaches a natural close OR after ~6-8 user turns.

        TONE for callouts: think Spotify Wrapped sass + Duolingo owl. Witty, knowing, NOT mean. NOT therapist-speak.

        Return JSON only — the schema is enforced.
        """
    }

    static func verdictSystemPrompt(scenario: Scenario) -> String {
        """
        You are the post-game commentator for "Don't Fold" — a Gen Z communication pressure-test app.

        The user just attempted this scenario:
        \(scenario.title) — \(scenario.blurb)
        Goal: \(scenario.userGoal)

        Generate a recap card. Tone: Spotify Wrapped sass + internet humor + slight roast.
        Stylistically: bold, short, screenshottable, NOT corporate, NOT therapist-y, NOT mean.

        JSON fields:
        - verdictTitle: 2-4 word title like "Recovering People Pleaser", "Professional Overexplainer",
          "Folded On Impact", "Main Character Energy", "Held The Line", "Quietly Devastating".
          Invent new ones if appropriate. ALL CAPS optional.
        - verdictVibe: ONE sentence (max 22 words) capturing the energy. Punchy. Witty. Could land on Twitter.
        - oneLinerToShare: ONE sentence under 80 chars, designed to be screenshotted/shared. Should land as a quote.
        - highlights: 2–4 specific moments from the transcript, each a single line in roast-y observation form
          (e.g. "Apologized 3 times before naming the actual issue").
        - stats: 3-4 short stat chips with label + value. Examples:
            {label: "FILLER WORDS", value: "7", detail: "above average"}
            {label: "TIME TO FOLD", value: "0:42"}
            {label: "FINAL VIBE", value: "Recovered"}.
          Make them feel like Spotify-Wrapped factoids.

        Return JSON only.
        """
    }

    static func verdictUserPrompt(transcript: [Turn], finalPressure: Double, finalConfidence: Double) -> String {
        let convo = transcript.map { t in
            "\(t.speaker == .ai ? "AI" : "USER"): \(t.text)"
        }.joined(separator: "\n")
        return """
        Transcript:
        \(convo)

        Final pressure: \(Int(finalPressure * 100))/100
        Final confidence: \(Int(finalConfidence * 100))/100
        """
    }
}

// MARK: - Mock fallback (used when no API key is set)

enum MockGemini {
    static func nextTurn(scenario: Scenario, history: [Turn]) -> AITurnResponse {
        let userTurns = history.filter { $0.speaker == .user }.count
        if userTurns == 0 {
            return AITurnResponse(
                say: scenario.openingLine,
                pressureDelta: 0,
                confidenceDelta: 0,
                callout: nil,
                shouldEnd: false
            )
        }
        let lines = [
            "Mm. Can you be more specific?",
            "Okay — and what does that look like in practice?",
            "Right. So what are you actually asking for?",
            "Sure, sure. But — concretely?",
        ]
        let callouts = [
            "you apologized before answering 🙃",
            "filler word count just spiked",
            "you softened the ask mid-sentence",
            "the silence was working FOR you and you broke it",
        ]
        let lastUser = history.last(where: { $0.speaker == .user })?.text.lowercased() ?? ""
        let folded = lastUser.contains("sorry") || lastUser.contains("just") || lastUser.contains("kind of") || lastUser.contains("maybe")
        return AITurnResponse(
            say: lines.randomElement()!,
            pressureDelta: folded ? 12 : -5,
            confidenceDelta: folded ? -10 : 6,
            callout: folded ? callouts.randomElement() : nil,
            shouldEnd: userTurns >= 6
        )
    }

    static func finalVerdict(scenario: Scenario, transcript: [Turn], finalPressure: Double, finalConfidence: Double) -> AIVerdict {
        let title = VerdictTemplates.fallback(pressure: finalPressure, confidence: finalConfidence)
        return AIVerdict(
            verdictTitle: title,
            verdictVibe: "You walked in confident and left… negotiating with yourself. Iconic.",
            oneLinerToShare: "i went to ask for a raise and accidentally apologized for existing",
            highlights: [
                "Apologized before stating the issue",
                "Softened the ask 2 separate times",
                "Recovered in the final line — barely",
            ],
            stats: [
                .init(label: "FINAL PRESSURE", value: "\(Int(finalPressure * 100))", detail: nil),
                .init(label: "FINAL CONFIDENCE", value: "\(Int(finalConfidence * 100))", detail: nil),
                .init(label: "TURNS", value: "\(transcript.filter { $0.speaker == .user }.count)", detail: nil),
            ]
        )
    }
}
