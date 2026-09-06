import Foundation

public struct WorkflowState: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let type: String
    public let color: String
    public let position: Double?

    public init(id: String, name: String, type: String, color: String = "#8B87F8", position: Double? = nil) {
        self.id = id; self.name = name; self.type = type; self.color = color; self.position = position
    }

    public static func workingState(in states: [Self], preferredID: String? = nil) -> Self? {
        let active = states.filter { $0.type == "started" }
        if let preferred = active.first(where: { $0.id == preferredID }) { return preferred }
        for name in ["working", "in progress"] {
            if let match = active.first(where: { $0.name.lowercased() == name }) { return match }
        }
        return active.sorted { ($0.position ?? 0, $0.name) < ($1.position ?? 0, $1.name) }.first
    }
}

public struct IssueTeam: Codable, Equatable {
    public let id: String
    public let name: String
    public let key: String
    public init(id: String, name: String, key: String) { self.id = id; self.name = name; self.key = key }
}

public struct IssueProject: Codable, Equatable {
    public let name: String
    public init(name: String) { self.name = name }
}

public struct LinearIssue: Codable, Identifiable, Equatable {
    public let id: String
    public let identifier: String
    public let title: String
    public let url: String
    public var state: WorkflowState
    public let team: IssueTeam
    public let project: IssueProject?
    public let priority: Int

    public init(id: String, identifier: String, title: String, url: String, state: WorkflowState, team: IssueTeam,
                project: IssueProject? = nil, priority: Int = 0) {
        self.id = id; self.identifier = identifier; self.title = title; self.url = url
        self.state = state; self.team = team; self.project = project; self.priority = priority
    }

    public static let examples: [LinearIssue] = [
        .init(id: "demo-1", identifier: "DEMO-12", title: "Shape the first version of the menu bar app", url: "", state: .init(id: "todo", name: "Todo", type: "unstarted"), team: .init(id: "demo", name: "Personal projects", key: "DEMO"), project: .init(name: "Linear Focus"), priority: 2),
        .init(id: "demo-2", identifier: "DEMO-18", title: "Explore a calmer floating timer", url: "", state: .init(id: "progress", name: "In Progress", type: "started"), team: .init(id: "demo", name: "Personal projects", key: "DEMO"), project: .init(name: "Linear Focus"), priority: 3),
        .init(id: "demo-3", identifier: "DEMO-24", title: "Review the next small step", url: "", state: .init(id: "todo", name: "Todo", type: "unstarted"), team: .init(id: "demo", name: "Personal projects", key: "DEMO"), project: .init(name: "Weekly routine")),
        .init(id: "demo-4", identifier: "DEMO-31", title: "Make room for a little focused work", url: "", state: .init(id: "backlog", name: "Backlog", type: "backlog", color: "#8B8D98"), team: .init(id: "demo", name: "Personal projects", key: "DEMO"), project: .init(name: "Weekly routine"))
    ]
}

public struct FocusSession: Codable, Identifiable, Equatable {
    public enum Phase: String, Codable { case running, paused, finished }
    public let id: UUID
    public var issue: LinearIssue
    public let startedAt: Date
    public private(set) var allocatedSeconds: TimeInterval
    public private(set) var phase: Phase
    public private(set) var deadline: Date?
    public private(set) var pausedRemaining: TimeInterval
    public private(set) var finishedAt: Date?
    public let isDemo: Bool

    public init(issue: LinearIssue, duration: TimeInterval, now: Date = Date(), isDemo: Bool = false) {
        id = UUID(); self.issue = issue; startedAt = now; self.isDemo = isDemo
        allocatedSeconds = max(1, duration); phase = .running
        deadline = now.addingTimeInterval(max(1, duration)); pausedRemaining = 0
    }

    public func remaining(at now: Date) -> TimeInterval {
        switch phase {
        case .running: return max(0, deadline?.timeIntervalSince(now) ?? 0)
        case .paused: return pausedRemaining
        case .finished: return 0
        }
    }

    public func elapsed(at now: Date) -> TimeInterval { max(0, allocatedSeconds - remaining(at: now)) }
    public func progress(at now: Date) -> Double { min(1, max(0, elapsed(at: now) / allocatedSeconds)) }

    @discardableResult public mutating func reconcile(at now: Date) -> Bool {
        guard phase == .running, let end = deadline, end <= now else { return false }
        phase = .finished; finishedAt = end; deadline = nil; pausedRemaining = 0
        return true
    }

    public mutating func pause(at now: Date) {
        reconcile(at: now)
        guard phase == .running else { return }
        pausedRemaining = remaining(at: now); deadline = nil; phase = .paused
    }

    public mutating func resume(at now: Date) {
        guard phase == .paused else { return }
        deadline = now.addingTimeInterval(pausedRemaining); phase = .running
    }

    public mutating func addTime(_ seconds: TimeInterval, at now: Date) {
        guard seconds.isFinite, seconds > 0 else { return }
        reconcile(at: now)
        allocatedSeconds += seconds
        switch phase {
        case .running: deadline = deadline?.addingTimeInterval(seconds)
        case .paused: pausedRemaining += seconds
        case .finished: phase = .running; deadline = now.addingTimeInterval(seconds); finishedAt = nil
        }
    }

    public static func clockString(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(ceil(seconds)))
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}

public struct SessionRecord: Codable, Identifiable {
    public let id: UUID
    public let issue: LinearIssue
    public let endedAt: Date
    public let focusedSeconds: TimeInterval
    public let completed: Bool
    public let isDemo: Bool
    public init(session: FocusSession, now: Date) {
        id = session.id; issue = session.issue; endedAt = session.finishedAt ?? now
        focusedSeconds = session.elapsed(at: now); completed = session.phase == .finished; isDemo = session.isDemo
    }
}
