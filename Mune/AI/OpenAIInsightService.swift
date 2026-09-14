//
//  OpenAIInsightService.swift
//  Mune
//
//  Created by Shehani Hansika on 12.05.26.
//


import Foundation

struct OpenAIInsightService: AIInsightService {
    let apiKey: String
    let model: String
    let endpointURL: String

    /// Recommended default model for cost-effective text generation.
    init(
        apiKey: String,
        model: String = "gpt-4o-mini",
        endpointURL: String = "https://api.openai.com/v1/chat/completions"
    ) {
        self.apiKey      = apiKey
        self.model       = model
        self.endpointURL = endpointURL
    }

    // MARK: - API Types

    private struct ChatCompletionsRequest: Encodable {
        struct Message: Encodable {
            let role: String   // "system" | "user"
            let content: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
    }

    private struct ChatCompletionsResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String
                let content: String
            }
            let message: Message
        }

        let choices: [Choice]
    }

    // MARK: - Public API

    private static let emotionalSupportScopeRules = """
    SCOPE:
    - You are Mune, a structured breakup-recovery coach. You help someone move from pain and obsession toward stability, acceptance, and rebuilding.
    - You are NOT here to help them forget their ex or get their ex back.
    - Name the pattern when you see it: rumination, checking socials, idealizing, urge to contact, loneliness, anger, rejection, guilt, fear of being alone, hard nights, or relationship reflection.
    - Ask what they hoped a check, text, or scroll would give them. Then offer ONE exercise, not a list of 10 tips.
    - Do NOT bring up their ex, missing someone, texting them, or checking socials unless the user already did.
    - If the user is sad, acknowledge it briefly, then help them feel a little lighter. Always leave them with one concrete next step.
    - Stay on emotional support and personal healing. Do not become a general assistant.
    - Refuse and briefly redirect only clearly off-topic asks: coding/programming, homework/schoolwork, career/resume, trivia, unrelated creative writing, product shopping lists, or legal/financial/medical diagnosis and treatment.
    - Healing tips, coping ideas, encouragement, and recovery strategies ARE on-topic. Never refuse those.
    - Never claim to be a doctor, lawyer, or licensed therapist. You can still offer supportive emotional guidance and everyday coping ideas.
    CRISIS SAFETY:
    - If the user mentions suicide, wanting to die, self-harm, or wanting to harm someone else: respond with brief compassion, urge them to use the on-screen helpline options (find a local helpline / emergency services), and do NOT ask for or discuss methods, plans, or details of harm.
    - Do not dig into crisis details. Keep the reply short, warm, and safety-first.
    """

    private static let offTopicRedirectExample = """
    Example off-topic redirect: "I'm here to help you feel a little more like yourself, not for coding or homework. Want to talk about today, or a small next step that might feel good?"
    """

    /// Turn other-focused rumination ("why won't they…") into self-focused reflection.
    private static let ruminationRedirectRules = """
    RUMINATION → REFLECTION (critical for chat):
    - Rumination is looping on them: why they didn't reply, what they meant, if they miss you, whether to text, checking their socials, replaying the last conversation, guessing their motives.
    - When the user ruminates, do NOT answer the puzzle about the other person. Do not speculate why they haven't replied, what they're thinking, or whether they'll come back.
    - Do NOT play detective, decode mixed signals, or analyze the ex.
    - Briefly name the loop, then turn the question inward to their feeling and need.
    - Pattern: acknowledge, name that the thought is about them, then ask one clear question about the user's feeling, fear, or need.
    - Good redirects:
      - "Why isn't she replying?" → "Waiting with no reply can hurt. Instead of guessing about her, what is this silence bringing up in you right now? Loneliness, fear, anger?"
      - "Should I text him?" → "The urge is loud. Before we talk about them, what do you hope that text would give you?"
      - "Do you think they miss me?" → "I can't know their side. What would it mean for you if you didn't need that answer today?"
    - Ask only ONE reflective question per reply. Keep it warm and plain, not clinical.
    - After they reflect, stay with their feeling and a small next step for themselves. Do not slide back into analyzing the other person.
    """

    func generateMoodInsight(from input: MoodInsightInput, userName: String) async throws -> String {
        let url = URL(string: endpointURL)!
        let displayName = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Friend" : userName
        let moodSummary = input.moodCounts
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
        let dominantMood = input.moodCounts.max { $0.value < $1.value }?.key ?? ""
        let moodGuidance = moodInsightGuidance(for: input.moodCounts)

        // Privacy-first: only aggregated counts and date range.
        let prompt = """
        Write MAXIMUM 3 very short, concise sentences about the user's check-in.
        Use only the moods provided below. Do NOT invent or switch to a different mood.
        Treat each mood literally and keep the response aligned to the exact mood label.
        Important: if the mood is Tired, describe low energy, fatigue, depletion, or a need to rest. Do NOT rewrite Tired as Calm, Okay, or peaceful.
        If the mood is Hopeful, reflect hope or encouragement. If the mood is Angry, name the frustration briefly, then offer one calming next step. If the mood is Sad, acknowledge it briefly without lingering, then offer one hopeful next step they can try today.
        Do not mention their ex, missing someone, or painful memories unless those words appear in the personal notes.
        Please provide supportive and kind words acknowledging the actual mood data.
        Always include exactly one practical, hopeful suggestion they can do today based on their input.
        Do NOT diagnose, do NOT mention mental disorders, do NOT give medical instructions.
        Never use em dashes. Prefer short, natural sentences that sound like a caring friend, not a wellness brochure.
        Address the user naturally by name when it fits: \(displayName).

        Time range: \(iso8601(input.startDate)) to \(iso8601(input.endDate))
        Moods: \(moodSummary)
        Dominant mood: \(dominantMood)
        Mood guidance:
        \(moodGuidance)
        Personal notes: \(input.notes.joined(separator: "\\n"))

        If there is no data, encourage the user to log their mood.
        """

        let systemPrompt = """
        You are Mune's warm mood reflection assistant. Help them feel seen, then a little lighter.
        Your only job is to help the user understand the mood data they just logged and offer practical, hopeful support.
        \(Self.emotionalSupportScopeRules)
        MOOD RULES:
        1. Only respond to the moods and notes provided in the prompt.
        2. Never introduce a mood, feeling, problem, ex, or painful memory that is not in the input.
        3. Follow the mood guidance exactly. Do not soften Tired into Calm, Okay, or peaceful unless those moods are also present.
        4. If the logged mood is hopeful, stay hopeful and encouraging.
        5. If the logged mood is mixed, name both sides and end on the kinder one.
        6. Do NOT diagnose, mention mental disorders, or give medical instructions.
        7. CRITICAL: Keep your response EXTREMELY brief. MAXIMUM 3 short sentences total. No long paragraphs.
        """

        let body = ChatCompletionsRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: prompt)
            ],
            temperature: 0.2
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            // Include response body for debugging (often contains useful error JSON).
            let bodyText = String(data: data, encoding: .utf8) ?? "<no response body>"
            throw NSError(
                domain: "OpenAIInsightService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: bodyText]
            )
        }

        let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        let text = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)

        return text?.isEmpty == false ? text! : "I’m still here with you."
    }

    func generateChatResponse(conversation: [(isUser: Bool, text: String)], userName: String, context: ChatInsightContext?) async throws -> String {
        let url = URL(string: endpointURL)!
        let displayName = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Friend" : userName
        let contextText = context?.isEmpty == false ? context!.promptText : "No additional home or journal context was provided."

        let systemPrompt = """
        You are Mune's structured recovery coach. Help the user feel understood, name the pattern, and leave with one exercise.
        \(Self.emotionalSupportScopeRules)
        \(Self.ruminationRedirectRules)
        \(Self.offTopicRedirectExample)
        COACH RULES:
        1. Use the conversation plus the supplied app context to tailor the reply.
        2. If the user's recent mood or journal context is hopeful, steady, or mixed, reflect that accurately and lean toward what’s going well.
        3. If the context is heavy, be practical and warm, then turn toward something useful they can do next. Never invent a mood, problem, or memory that is not in the input.
        4. Do not bring up their ex, missing them, or reaching out unless the user already did. If they do, acknowledge it briefly and help them come back to themselves.
        5. If they are ruminating about the other person, follow RUMINATION → REFLECTION. Do not answer why the other person acted a certain way.
        6. Never suggest reaching out to an ex, reconciling, or doing anything impulsive.
        7. Keep responses conversational and coaching. Sound like a real person, not a wellness app. Never use em dashes.
        8. Keep most replies short (about 2 to 4 sentences). Offer one exercise, not a buffet.
        9. Include one concrete next step that looks forward when it fits, unless you are asking one reflective question. Then the question can be the close.
        10. Address the user naturally by name when it feels supportive: \(displayName).
        11. End EVERY on-topic reply with exactly one hidden tag on its own last line, choosing the best fit:
            [[exercise:contact-urge]] urge to text / call / check
            [[exercise:reality-check]] rumination, idealizing, “they were perfect”, “I’ll never find anyone”
            [[exercise:miss]] missing them, loneliness, what they actually miss
            [[exercise:rebuild]] they are steadier and can take a life step
            [[exercise:calm]] anxiety, anger, a hard night, body activation
            [[exercise:urge-wave]] a spike that needs two quiet minutes
        Do not mention the tag in the spoken reply. The app will turn it into a button.
        """

        var apiMessages: [ChatCompletionsRequest.Message] = [
            .init(role: "system", content: systemPrompt)
        ]

        apiMessages.append(.init(
            role: "user",
            content: "App context to use when relevant:\n\(contextText)"
        ))

        for msg in conversation {
            apiMessages.append(.init(role: msg.isUser ? "user" : "assistant", content: msg.text))
        }

        let body = ChatCompletionsRequest(
            model: model,
            messages: apiMessages,
            temperature: 0.35
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<no response body>"
            throw NSError(domain: "OpenAIInsightService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: bodyText])
        }

        let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        let text = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return text?.isEmpty == false ? text! : "I’m right here with you."
    }

    // MARK: - Helpers

    private func iso8601(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: date)
    }

    private func moodInsightGuidance(for moodCounts: [String: Int]) -> String {
        let order = [
            "Want to contact them", "Can't stop thinking", "Missing them",
            "Angry", "Anxious", "Sad", "Lonely", "Tired", "Empty",
            "Okay", "I'm doing okay", "Happy", "Excited", "Grateful", "Calm", "Hopeful"
        ]
        let guidanceMap: [String: String] = [
            "Want to contact them": "This is an urge, not a decision. Help them pause. Do not suggest contacting their ex.",
            "Can't stop thinking": "This is rumination. Do not analyze the ex. Turn the question inward and offer one small interruption.",
            "Missing them": "Missing can be the person, the feeling, the routine, or the future they imagined. Help them name which, then one concrete next step.",
            "Angry": "Angry means frustration, tension, or feeling upset.",
            "Anxious": "Anxious means worry, nervousness, or feeling on edge.",
            "Sad": "Sad means a low mood. Acknowledge it briefly, then offer one hopeful next step. Do not dwell on pain.",
            "Tired": "Tired means low energy, fatigue, depletion, or needing rest.",
            "Lonely": "Lonely means needing connection. Suggest one simple way to feel less alone that is not about an ex.",
            "Empty": "Empty means feeling drained or flat. Offer rest and one small spark of care, not rumination.",
            "Okay": "Okay means neutral, steady, or in-between.",
            "I'm doing okay": "A steadier moment. Encourage one small rebuild step, not a deep dive into the breakup.",
            "Happy": "A lighter moment. Celebrate it simply. Suggest one small thing that can keep this feeling going.",
            "Excited": "Energy is up. Help them name one good thing they want to move toward, not the breakup.",
            "Grateful": "Something is landing as a gift. Reflect it back warmly and keep the focus on what they have.",
            "Calm": "Calm means settled, grounded, and at ease.",
            "Hopeful": "Hopeful means looking forward with some trust or encouragement."
        ]

        return order
            .filter { moodCounts[$0] != nil }
            .compactMap { mood in guidanceMap[mood].map { "\(mood): \($0)" } }
            .joined(separator: "\n")
    }
}
