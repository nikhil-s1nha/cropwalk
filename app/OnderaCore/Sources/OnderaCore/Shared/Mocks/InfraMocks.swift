import Foundation

// Deterministic in-memory mocks for Workstream A seams.

public final class InMemoryWalkStore: WalkStoring {
    public private(set) var sessions: [UUID: WalkSession] = [:]
    public private(set) var photos: [String: Data] = [:]

    public init(sessions: [WalkSession] = []) {
        for s in sessions { self.sessions[s.id] = s }
    }

    public func save(_ session: WalkSession) throws { sessions[session.id] = session }
    public func load(id: UUID) throws -> WalkSession? { sessions[id] }
    public func inProgress() throws -> WalkSession? {
        sessions.values.filter { $0.status != .finished }.max { $0.startedAt < $1.startedAt }
    }
    public func all() throws -> [WalkSession] { sessions.values.sorted { $0.startedAt > $1.startedAt } }

    public func savePhoto(_ data: Data) throws -> String {
        let id = "photo-\(photos.count + 1)"
        photos[id] = data
        return id
    }

    public func photoData(id: String) throws -> Data? { photos[id] }

    public func deleteAll() throws {
        sessions = [:]
        photos = [:]
    }
}

public final class MockConsentStore: ConsentStoring {
    public private(set) var current: ConsentRecord?

    public init(current: ConsentRecord? = nil) {
        self.current = current
    }

    public func accept(language: AppLanguage) throws -> ConsentRecord {
        let record = ConsentRecord(version: ConsentRecord.currentVersion, language: language)
        current = record
        return record
    }

    public func withdraw() throws { current = nil }
}

/// Enforces the outbox rules (confirmed + ≤ 160 chars) so callers are tested against them from day one.
public final class MockOutbox: OutboxStoring, OutboxSending {
    public private(set) var messages: [OutboxMessage] = []
    /// When false, flush() sends nothing (simulates no signal).
    public var isOnline: Bool

    public init(isOnline: Bool = false) {
        self.isOnline = isOnline
    }

    public func all() throws -> [OutboxMessage] { messages }

    public func enqueue(_ message: OutboxMessage) throws {
        guard message.confirmedAt != nil else { throw OutboxError.notConfirmed }
        guard message.body.count <= OutboxMessage.maxSMSLength else { throw OutboxError.tooLong(message.body.count) }
        var m = message
        m.status = .queued
        messages.append(m)
    }

    public func update(_ message: OutboxMessage) throws {
        guard let i = messages.firstIndex(where: { $0.id == message.id }) else { throw OutboxError.notFound }
        messages[i] = message
    }

    public func cancel(id: UUID) throws {
        guard let i = messages.firstIndex(where: { $0.id == id }) else { throw OutboxError.notFound }
        messages[i].status = .cancelled
    }

    public func flush() async -> [OutboxMessage] {
        guard isOnline else { return [] }
        var sent: [OutboxMessage] = []
        for i in messages.indices where messages[i].status == .queued {
            messages[i].status = .sent
            messages[i].attempts += 1
            sent.append(messages[i])
        }
        return sent
    }
}

public final class MockVoiceRecorder: VoiceRecording {
    public private(set) var isRecording = false
    private var count = 0

    public init() {}

    public func start() throws { isRecording = true }

    public func stop() async throws -> VoiceNote {
        isRecording = false
        count += 1
        return VoiceNote(id: "voice-\(count)", duration: 4)
    }
}

public final class MockKeywordSpotter: KeywordSpotting {
    public var hits: [KeywordHit]

    public init(hits: [KeywordHit] = []) {
        self.hits = hits
    }

    public func spot(in note: VoiceNote) async throws -> [KeywordHit] { hits }
}

public final class MockAudioPrompter: AudioPrompting {
    public private(set) var played: [String] = []

    public init() {}

    public func play(key: String) { played.append(key) }
    public func stop() {}
}
