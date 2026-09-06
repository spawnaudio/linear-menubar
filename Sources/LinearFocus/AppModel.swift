import AppKit
import Combine
import FocusCore

@MainActor
final class AppModel: ObservableObject {
    enum Page: String, CaseIterable { case focus = "My issues", history = "Sessions", settings = "Settings" }
    @Published var page: Page = .focus
    @Published var issues: [LinearIssue] = []
    @Published var selectedID: String?
    @Published var profile: LinearProfile?
    @Published var isDemo = false
    @Published var isLoading = false
    @Published var isStarting = false
    @Published var error: String?
    @Published var search = ""
    @Published var filter = "All issues"
    @Published var minutes = "25"
    @Published var session: FocusSession?
    @Published var history: [SessionRecord] = []
    @Published var now = Date()
    @Published var panelExpanded = false
    @Published var nextCursor: String?
    @Published var hasMore = false
    @Published var states: [WorkflowState] = []
    @Published var statesTeamID: String?
    @Published var isLoadingStates = false
    @Published var updateLinear: Bool { didSet { defaults.set(updateLinear, forKey: "updateLinear") } }
    @Published var playSound: Bool { didSet { defaults.set(playSound, forKey: "playSound") } }
    @Published var defaultMinutes: Int { didSet { defaults.set(defaultMinutes, forKey: "defaultMinutes") } }
    @Published var preferredStates: [String: String] { didSet { defaults.set(preferredStates, forKey: "preferredStates") } }
    var showMain: (() -> Void)?
    var showTimer: (() -> Void)?
    var hideTimer: (() -> Void)?
    var onTick: (() -> Void)?
    private var client: LinearClient?
    private var ticker: AnyCancellable?
    private let defaults: UserDefaults
    private var connectionGeneration = UUID()

    init(defaults: UserDefaults = .standard, preview: Bool = false) {
        self.defaults = defaults
        defaults.register(defaults: ["updateLinear": true, "playSound": true, "defaultMinutes": 25])
        updateLinear = defaults.bool(forKey: "updateLinear")
        playSound = defaults.bool(forKey: "playSound")
        defaultMinutes = defaults.integer(forKey: "defaultMinutes")
        preferredStates = defaults.dictionary(forKey: "preferredStates") as? [String: String] ?? [:]
        minutes = String(defaultMinutes)
        if let data = defaults.data(forKey: "session") { session = try? JSONDecoder().decode(FocusSession.self, from: data) }
        if let data = defaults.data(forKey: "history") { history = (try? JSONDecoder().decode([SessionRecord].self, from: data)) ?? [] }
        session?.reconcile(at: now)
        if preview || defaults.bool(forKey: "demo") {
            isDemo = true; issues = LinearIssue.examples; selectedID = issues.first?.id
        }
        ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect().sink { [weak self] date in
            self?.tick(date)
        }
    }

    var connected: Bool { profile != nil }
    var selectedIssue: LinearIssue? { issues.first { $0.id == selectedID } }
    var duration: Int? { Int(minutes).flatMap { (1...480).contains($0) ? $0 : nil } }
    var remaining: TimeInterval { session?.remaining(at: now) ?? 0 }
    var clockText: String { FocusSession.clockString(remaining) }
    var visibleIssues: [LinearIssue] {
        issues.filter {
            (filter != "In progress" || $0.state.type == "started") &&
            (search.isEmpty || "\($0.identifier) \($0.title) \($0.project?.name ?? "")".localizedCaseInsensitiveContains(search))
        }
    }
    var todayRecords: [SessionRecord] {
        history.filter { Calendar.current.isDateInToday($0.endedAt) && $0.isDemo == isDemo }
    }
    var todayMinutes: Int { Int(todayRecords.reduce(0) { $0 + $1.focusedSeconds } / 60) }

    func bootstrap() async {
        guard !isDemo else { return }
        do {
            if let key = try Keychain.read() { await connect(key: key, save: false) }
        } catch { self.error = error.localizedDescription }
    }

    func connect(key: String, save: Bool = true) async {
        guard !isLoading, !isStarting, (!save || session == nil) else { return }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { error = "Enter your Linear API key to connect."; return }
        isLoading = true; error = nil
        defer { isLoading = false }
        let candidate = LinearClient(key: trimmed)
        do {
            let account = try await candidate.profile()
            let firstPage = try await candidate.issues()
            if save { try Keychain.save(trimmed) }
            connectionGeneration = UUID(); client = candidate; profile = account; isDemo = false
            defaults.set(false, forKey: "demo")
            issues = firstPage.nodes; selectedID = issues.first?.id
            nextCursor = firstPage.pageInfo.endCursor; hasMore = firstPage.pageInfo.hasNextPage
            page = .focus; states = []; statesTeamID = nil
        } catch { self.error = error.localizedDescription }
    }

    func useDemo() {
        guard session == nil, !isLoading, !isStarting else { return }
        connectionGeneration = UUID(); isDemo = true; client = nil; profile = nil
        issues = LinearIssue.examples; selectedID = issues.first?.id; page = .focus
        hasMore = false; nextCursor = nil; error = nil; states = []; statesTeamID = nil
        defaults.set(true, forKey: "demo")
    }

    func disconnect() {
        guard session == nil, !isLoading, !isStarting else { return }
        do { try Keychain.delete() } catch { self.error = error.localizedDescription; return }
        connectionGeneration = UUID(); client = nil; profile = nil; isDemo = false; issues = []
        selectedID = nil; hasMore = false; nextCursor = nil; states = []; statesTeamID = nil
        preferredStates = [:]; defaults.set(false, forKey: "demo"); error = nil
    }

    func refresh(loadMore: Bool = false) async {
        guard !isLoading, !isStarting else { return }
        if isDemo { return }
        guard let client else { return }
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            let result = try await client.issues(after: loadMore ? nextCursor : nil)
            if loadMore {
                let existing = Set(issues.map(\.id))
                issues += result.nodes.filter { !existing.contains($0.id) }
            } else { issues = result.nodes }
            nextCursor = result.pageInfo.endCursor; hasMore = result.pageInfo.hasNextPage
            if !issues.contains(where: { $0.id == selectedID }) { selectedID = issues.first?.id }
        } catch { self.error = error.localizedDescription }
    }

    func loadStates() async {
        guard let issue = selectedIssue, let client else { return }
        let generation = connectionGeneration
        let teamID = issue.team.id
        isLoadingStates = true; states = []; statesTeamID = teamID
        defer { isLoadingStates = false }
        do {
            let result = try await client.states(teamID: teamID)
            guard generation == connectionGeneration, statesTeamID == teamID else { return }
            states = result.filter { $0.type == "started" }.sorted { ($0.position ?? 0) < ($1.position ?? 0) }
        } catch { if generation == connectionGeneration && !Task.isCancelled { self.error = error.localizedDescription } }
    }

    func start() async {
        guard session == nil, !isStarting, !isLoading, var issue = selectedIssue, let duration else { return }
        isStarting = true; error = nil
        defer { isStarting = false }
        do {
            if isDemo {
                if updateLinear { issue.state = .init(id: "progress", name: "In Progress", type: "started") }
            } else {
                guard let client else { error = "Connect to Linear before starting this issue."; return }
                if updateLinear { issue = try await client.markWorking(issue, preferredID: preferredStates[issue.team.id]) }
            }
            if let index = issues.firstIndex(where: { $0.id == issue.id }) { issues[index] = issue }
            now = Date(); session = FocusSession(issue: issue, duration: Double(duration * 60), now: now, isDemo: isDemo)
            persist(); showTimer?(); onTick?()
        } catch { self.error = "Couldn’t start the session. \(error.localizedDescription)" }
    }

    func togglePause() {
        guard session != nil else { return }
        now = Date()
        if session?.phase == .paused { session?.resume(at: now) } else { session?.pause(at: now) }
        persist(); onTick?()
    }

    func addTime(minutes: Int = 5) {
        now = Date(); session?.addTime(Double(minutes * 60), at: now)
        persist(); onTick?()
    }

    func endSession() {
        guard var ended = session else { return }
        now = Date(); ended.reconcile(at: now)
        history.insert(SessionRecord(session: ended, now: now), at: 0)
        history = Array(history.prefix(500))
        session = nil; persist(); hideTimer?(); onTick?()
    }

    func tick(_ date: Date) {
        now = date
        if session?.reconcile(at: date) == true {
            persist()
            if playSound { NSSound(named: "Glass")?.play() }
            showTimer?()
        }
        onTick?()
    }

    func persist() {
        if let session { defaults.set(try? JSONEncoder().encode(session), forKey: "session") }
        else { defaults.removeObject(forKey: "session") }
        defaults.set(try? JSONEncoder().encode(history), forKey: "history")
    }

    func openIssue(_ issue: LinearIssue) {
        guard let url = URL(string: issue.url), url.scheme == "https", url.host == "linear.app" else { return }
        NSWorkspace.shared.open(url)
    }
}
