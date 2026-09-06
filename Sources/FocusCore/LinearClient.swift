import Foundation

public struct LinearProfile: Decodable {
    public let viewer: Viewer
    public let organization: Organization
    public struct Viewer: Decodable { public let id: String; public let name: String }
    public struct Organization: Decodable { public let id: String; public let name: String }
}

public struct IssuePage: Decodable {
    public let nodes: [LinearIssue]
    public let pageInfo: PageInfo
    public struct PageInfo: Decodable { public let hasNextPage: Bool; public let endCursor: String? }
}

public enum LinearError: LocalizedError {
    case unauthorized, rateLimited, server(Int), graphql(String), malformed, noWorkingState, terminalIssue
    public var errorDescription: String? {
        switch self {
        case .unauthorized: return "Linear couldn’t authenticate this key. Check that it is valid and has access to your team."
        case .rateLimited: return "Linear’s request limit was reached. Wait a moment, then try again."
        case .server(let status): return "Linear is unavailable (HTTP \(status)). Try again shortly."
        case .graphql(let message): return message
        case .malformed: return "Linear returned an unexpected response. Please try refreshing."
        case .noWorkingState: return "This team has no active workflow status. Add an In Progress status in Linear or turn off status updates in Settings."
        case .terminalIssue: return "This issue is already completed or canceled in Linear. Refresh your issues and choose another."
        }
    }
}

public final class LinearClient {
    private let key: String
    private let session: URLSession
    public init(key: String, session: URLSession = .shared) { self.key = key; self.session = session }

    private struct Envelope<T: Decodable>: Decodable {
        let data: T?
    }
    private struct ErrorEnvelope: Decodable {
        let errors: [APIError]?
        struct APIError: Decodable { let message: String }
    }

    private func request<T: Decodable>(_ query: String, variables: [String: Any] = [:]) async throws -> T {
        var request = URLRequest(url: URL(string: "https://api.linear.app/graphql")!)
        request.httpMethod = "POST"; request.timeoutInterval = 25
        request.setValue(key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query, "variables": variables])
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw LinearError.malformed }
        switch response.statusCode {
        case 200...299: break
        case 401, 403: throw LinearError.unauthorized
        case 429: throw LinearError.rateLimited
        default: throw LinearError.server(response.statusCode)
        }
        let failure = try JSONDecoder().decode(ErrorEnvelope.self, from: data)
        if let errors = failure.errors, !errors.isEmpty {
            throw LinearError.graphql(errors.map(\.message).joined(separator: "\n"))
        }
        let decoded = try JSONDecoder().decode(Envelope<T>.self, from: data)
        guard let result = decoded.data else { throw LinearError.malformed }
        return result
    }

    public func profile() async throws -> LinearProfile {
        try await request("query FocusProfile { viewer { id name } organization { id name } }")
    }

    public func issues(after cursor: String? = nil) async throws -> IssuePage {
        struct Result: Decodable { let viewer: Viewer; struct Viewer: Decodable { let assignedIssues: IssuePage } }
        let result: Result = try await request("""
        query FocusIssues($after: String) {
          viewer {
            assignedIssues(first: 50, after: $after, orderBy: updatedAt,
              filter: { state: { type: { nin: ["completed", "canceled"] } } }) {
              nodes { \(Self.issueFields) }
              pageInfo { hasNextPage endCursor }
            }
          }
        }
        """, variables: ["after": cursor as Any? ?? NSNull()])
        return result.viewer.assignedIssues
    }

    public func states(teamID: String) async throws -> [WorkflowState] {
        struct Result: Decodable {
            let team: Team
            struct Team: Decodable { let states: States; struct States: Decodable { let nodes: [WorkflowState] } }
        }
        let result: Result = try await request("""
        query FocusStates($id: String!) {
          team(id: $id) { states(first: 100) { nodes { id name type color position } } }
        }
        """, variables: ["id": teamID])
        return result.team.states.nodes
    }

    public func markWorking(_ issue: LinearIssue, preferredID: String? = nil) async throws -> LinearIssue {
        struct IssueResult: Decodable { let issue: LinearIssue }
        let current: IssueResult = try await request("query FocusIssue($id: String!) { issue(id: $id) { \(Self.issueFields) } }", variables: ["id": issue.id])
        guard !["completed", "canceled"].contains(current.issue.state.type) else { throw LinearError.terminalIssue }
        // Keep an already active status unless the user explicitly selected another one.
        if current.issue.state.type == "started", preferredID == nil { return current.issue }
        let options = try await states(teamID: issue.team.id)
        guard let state = WorkflowState.workingState(in: options, preferredID: preferredID) else { throw LinearError.noWorkingState }
        if current.issue.state.id == state.id { return current.issue }
        struct Result: Decodable {
            let issueUpdate: Update
            struct Update: Decodable { let success: Bool; let issue: LinearIssue? }
        }
        let result: Result = try await request("""
        mutation FocusStart($id: String!, $state: String!) {
          issueUpdate(id: $id, input: { stateId: $state }) { success issue { \(Self.issueFields) } }
        }
        """, variables: ["id": issue.id, "state": state.id])
        guard result.issueUpdate.success, let updated = result.issueUpdate.issue else { throw LinearError.malformed }
        return updated
    }

    private static let issueFields = """
    id identifier title url priority
    state { id name type color position }
    team { id name key }
    project { name }
    """
}
