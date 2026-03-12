import Foundation

public struct ElevenLabsVoice: Decodable, Sendable {
    public let voiceId: String
    public let name: String?

    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case name
    }

    public init(voiceId: String, name: String? = nil) {
        self.voiceId = voiceId
        self.name = name
    }
}

public struct ElevenLabsTTSRequest: Sendable {
    public var text: String
    public var modelId: String?
    public var outputFormat: String?
    public var speed: Double?
    public var stability: Double?
    public var similarity: Double?
    public var style: Double?
    public var speakerBoost: Bool?
    public var seed: UInt32?
    public var normalize: String?
    public var language: String?
    public var latencyTier: Int?

    public init(
        text: String,
        modelId: String? = nil,
        outputFormat: String? = nil,
        speed: Double? = nil,
        stability: Double? = nil,
        similarity: Double? = nil,
        style: Double? = nil,
        speakerBoost: Bool? = nil,
        seed: UInt32? = nil,
        normalize: String? = nil,
        language: String? = nil,
        latencyTier: Int? = nil)
    {
        self.text = text
        self.modelId = modelId
        self.outputFormat = outputFormat
        self.speed = speed
        self.stability = stability
        self.similarity = similarity
        self.style = style
        self.speakerBoost = speakerBoost
        self.seed = seed
        self.normalize = normalize
        self.language = language
        self.latencyTier = latencyTier
    }
}

public enum TalkTTSValidation: Sendable {
    private static let v3StabilityValues: Set<Double> = [0.0, 0.5, 1.0]

    public static func resolveSpeed(speed: Double?, rateWPM: Int?) -> Double? {
        if let rateWPM, rateWPM > 0 {
            let resolved = Double(rateWPM) / 175.0
            if resolved <= 0.5 || resolved >= 2.0 { return nil }
            return resolved
        }
        if let speed {
            if speed <= 0.5 || speed >= 2.0 { return nil }
            return speed
        }
        return nil
    }

    public static func validatedUnit(_ value: Double?) -> Double? {
        guard let value else { return nil }
        if value < 0 || value > 1 { return nil }
        return value
    }

    public static func validatedStability(_ value: Double?, modelId: String?) -> Double? {
        guard let value else { return nil }
        let normalizedModel = (modelId ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedModel == "eleven_v3" {
            return self.v3StabilityValues.contains(value) ? value : nil
        }
        return self.validatedUnit(value)
    }

    public static func validatedSeed(_ value: Int?) -> UInt32? {
        guard let value else { return nil }
        if value < 0 || value > 4_294_967_295 { return nil }
        return UInt32(value)
    }

    public static func validatedLatencyTier(_ value: Int?) -> Int? {
        guard let value else { return nil }
        if value < 0 || value > 4 { return nil }
        return value
    }

    public static func pcmSampleRate(from outputFormat: String?) -> Double? {
        let trimmed = (outputFormat ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.hasPrefix("pcm_") else { return nil }
        let parts = trimmed.split(separator: "_", maxSplits: 1)
        guard parts.count == 2, let rate = Double(parts[1]), rate > 0 else { return nil }
        return rate
    }
}

public struct StreamingPlaybackResult: Sendable {
    public let finished: Bool
    public let interruptedAt: Double?

    public init(finished: Bool, interruptedAt: Double?) {
        self.finished = finished
        self.interruptedAt = interruptedAt
    }
}

@MainActor
public final class StreamingAudioPlayer {
    public static let shared = StreamingAudioPlayer()

    private var startedAt: Date?
    private var playbackTask: Task<StreamingPlaybackResult, Never>?

    public func play(stream: AsyncThrowingStream<Data, Error>) async -> StreamingPlaybackResult {
        self.playbackTask?.cancel()
        self.startedAt = Date()

        let task = Task<StreamingPlaybackResult, Never> {
            do {
                for try await _ in stream {
                    if Task.isCancelled {
                        let interruptedAt = await MainActor.run { self.stop() }
                        return StreamingPlaybackResult(finished: false, interruptedAt: interruptedAt)
                    }
                }
                return StreamingPlaybackResult(finished: true, interruptedAt: nil)
            } catch {
                return StreamingPlaybackResult(finished: false, interruptedAt: nil)
            }
        }

        self.playbackTask = task
        let result = await task.value
        self.playbackTask = nil
        self.startedAt = nil
        return result
    }

    public func stop() -> Double? {
        let interruptedAt = self.startedAt.map { Date().timeIntervalSince($0) }
        self.playbackTask?.cancel()
        self.playbackTask = nil
        self.startedAt = nil
        return interruptedAt
    }
}

@MainActor
public final class PCMStreamingAudioPlayer {
    public static let shared = PCMStreamingAudioPlayer()

    private var startedAt: Date?
    private var playbackTask: Task<StreamingPlaybackResult, Never>?

    public func play(
        stream: AsyncThrowingStream<Data, Error>,
        sampleRate _: Double) async -> StreamingPlaybackResult
    {
        self.playbackTask?.cancel()
        self.startedAt = Date()

        let task = Task<StreamingPlaybackResult, Never> {
            do {
                for try await _ in stream {
                    if Task.isCancelled {
                        let interruptedAt = await MainActor.run { self.stop() }
                        return StreamingPlaybackResult(finished: false, interruptedAt: interruptedAt)
                    }
                }
                return StreamingPlaybackResult(finished: true, interruptedAt: nil)
            } catch {
                return StreamingPlaybackResult(finished: false, interruptedAt: nil)
            }
        }

        self.playbackTask = task
        let result = await task.value
        self.playbackTask = nil
        self.startedAt = nil
        return result
    }

    public func stop() -> Double? {
        let interruptedAt = self.startedAt.map { Date().timeIntervalSince($0) }
        self.playbackTask?.cancel()
        self.playbackTask = nil
        self.startedAt = nil
        return interruptedAt
    }
}

public struct ElevenLabsTTSClient: @unchecked Sendable {
    public var apiKey: String
    public var requestTimeoutSeconds: TimeInterval
    public var listVoicesTimeoutSeconds: TimeInterval
    public var baseUrl: URL

    private let urlSession: URLSession
    private let sleep: @Sendable (TimeInterval) async -> Void

    public init(
        apiKey: String,
        requestTimeoutSeconds: TimeInterval = 45,
        listVoicesTimeoutSeconds: TimeInterval = 15,
        baseUrl: URL = URL(string: "https://api.elevenlabs.io")!,
        urlSession: URLSession = .shared,
        sleep: (@Sendable (TimeInterval) async -> Void)? = nil)
    {
        self.apiKey = apiKey
        self.requestTimeoutSeconds = requestTimeoutSeconds
        self.listVoicesTimeoutSeconds = listVoicesTimeoutSeconds
        self.baseUrl = baseUrl
        self.urlSession = urlSession
        self.sleep = sleep ?? { seconds in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }

    public func synthesizeWithHardTimeout(
        voiceId: String,
        request: ElevenLabsTTSRequest,
        hardTimeoutSeconds: TimeInterval) async throws -> Data
    {
        try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                try await self.synthesize(voiceId: voiceId, request: request)
            }
            group.addTask {
                await self.sleep(hardTimeoutSeconds)
                throw NSError(
                    domain: "ElevenLabsTTS",
                    code: 408,
                    userInfo: [NSLocalizedDescriptionKey: "ElevenLabs TTS timed out after \(hardTimeoutSeconds)s"])
            }
            let data = try await group.next()!
            group.cancelAll()
            return data
        }
    }

    public func synthesize(voiceId: String, request: ElevenLabsTTSRequest) async throws -> Data {
        var url = self.baseUrl
        url.appendPathComponent("v1")
        url.appendPathComponent("text-to-speech")
        url.appendPathComponent(voiceId)

        let body = try JSONSerialization.data(withJSONObject: Self.buildPayload(request), options: [])
        let req = Self.buildSynthesizeRequest(
            url: url,
            apiKey: self.apiKey,
            body: body,
            timeoutSeconds: self.requestTimeoutSeconds,
            outputFormat: request.outputFormat)

        let (data, response) = try await self.urlSession.data(for: req)
        if let http = response as? HTTPURLResponse {
            let contentType = (http.value(forHTTPHeaderField: "Content-Type") ?? "unknown").lowercased()
            if http.statusCode >= 400 {
                throw NSError(
                    domain: "ElevenLabsTTS",
                    code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "ElevenLabs failed: \(http.statusCode) \(Self.truncatedErrorBody(data))"])
            }
            if !Self.isAudioContentType(contentType, outputFormat: request.outputFormat) {
                throw NSError(
                    domain: "ElevenLabsTTS",
                    code: 415,
                    userInfo: [NSLocalizedDescriptionKey: "ElevenLabs returned non-audio ct=\(contentType) \(Self.truncatedErrorBody(data))"])
            }
        }
        return data
    }

    public func streamSynthesize(
        voiceId: String,
        request: ElevenLabsTTSRequest) -> AsyncThrowingStream<Data, Error>
    {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let data = try await self.synthesize(voiceId: voiceId, request: request)
                    let chunkSize = 2048
                    var offset = 0
                    while offset < data.count {
                        if Task.isCancelled {
                            break
                        }
                        let end = min(offset + chunkSize, data.count)
                        continuation.yield(data.subdata(in: offset..<end))
                        offset = end
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func listVoices() async throws -> [ElevenLabsVoice] {
        var url = self.baseUrl
        url.appendPathComponent("v1")
        url.appendPathComponent("voices")

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = self.listVoicesTimeoutSeconds
        req.setValue(self.apiKey, forHTTPHeaderField: "xi-api-key")

        let (data, response) = try await self.urlSession.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw NSError(
                domain: "ElevenLabsTTS",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "ElevenLabs voices failed: \(http.statusCode) \(Self.truncatedErrorBody(data))"])
        }

        struct VoicesResponse: Decodable {
            let voices: [ElevenLabsVoice]
        }

        return try JSONDecoder().decode(VoicesResponse.self, from: data).voices
    }

    public static func validatedOutputFormat(_ value: String?) -> String? {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.hasPrefix("mp3_") || trimmed.hasPrefix("pcm_") else { return nil }
        return trimmed
    }

    public static func validatedLanguage(_ value: String?) -> String? {
        let normalized = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.count == 2, normalized.allSatisfy({ $0 >= "a" && $0 <= "z" }) else {
            return nil
        }
        return normalized
    }

    public static func validatedNormalize(_ value: String?) -> String? {
        let normalized = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard ["auto", "on", "off"].contains(normalized) else { return nil }
        return normalized
    }

    private static func buildPayload(_ request: ElevenLabsTTSRequest) -> [String: Any] {
        var payload: [String: Any] = ["text": request.text]
        if let modelId = request.modelId?.trimmingCharacters(in: .whitespacesAndNewlines), !modelId.isEmpty {
            payload["model_id"] = modelId
        }
        if let outputFormat = request.outputFormat?.trimmingCharacters(in: .whitespacesAndNewlines), !outputFormat.isEmpty {
            payload["output_format"] = outputFormat
        }
        if let seed = request.seed {
            payload["seed"] = seed
        }
        if let normalize = request.normalize {
            payload["apply_text_normalization"] = normalize
        }
        if let language = request.language {
            payload["language_code"] = language
        }

        var voiceSettings: [String: Any] = [:]
        if let speed = request.speed { voiceSettings["speed"] = speed }
        if let stability = request.stability { voiceSettings["stability"] = stability }
        if let similarity = request.similarity { voiceSettings["similarity_boost"] = similarity }
        if let style = request.style { voiceSettings["style"] = style }
        if let speakerBoost = request.speakerBoost { voiceSettings["use_speaker_boost"] = speakerBoost }
        if !voiceSettings.isEmpty {
            payload["voice_settings"] = voiceSettings
        }
        return payload
    }

    private static func truncatedErrorBody(_ data: Data) -> String {
        let raw = String(data: data.prefix(4096), encoding: .utf8) ?? "unknown"
        return raw.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " ")
    }

    private static func acceptHeader(for outputFormat: String?) -> String? {
        let normalized = (outputFormat ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.hasPrefix("pcm_") { return "audio/pcm" }
        if normalized.hasPrefix("mp3_") { return "audio/mpeg" }
        return nil
    }

    static func buildSynthesizeRequest(
        url: URL,
        apiKey: String,
        body: Data,
        timeoutSeconds: TimeInterval,
        outputFormat: String?) -> URLRequest
    {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        req.timeoutInterval = timeoutSeconds
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Self.acceptHeader(for: outputFormat) ?? "audio/mpeg", forHTTPHeaderField: "Accept")
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        return req
    }

    private static func isAudioContentType(_ contentType: String, outputFormat: String?) -> Bool {
        if contentType.contains("audio") { return true }
        let normalized = (outputFormat ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.hasPrefix("pcm_"), contentType.contains("octet-stream") {
            return true
        }
        return false
    }
}
