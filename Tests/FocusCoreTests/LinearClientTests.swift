import Foundation
import Testing
@testable import FocusCore

private final class MockLinearProtocol: URLProtocol {
    static var respond: ((URLRequest) throws -> (Int, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, data) = try Self.respond!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

@Suite(.serialized)
struct LinearClientTests {
    private func client(_ handler: @escaping (URLRequest) throws -> (Int, String)) -> LinearClient {
        MockLinearProtocol.respond = { request in let (status, json) = try handler(request); return (status, Data(json.utf8)) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLinearProtocol.self]
        return LinearClient(key: "test-personal-key", session: URLSession(configuration: configuration))
    }

    @Test func testPersonalAPIKeyUsesRawAuthorizationHeader() async throws {
        let api = client { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "test-personal-key")
            #expect(request.url?.host == "api.linear.app")
            return (200, #"{"data":{"viewer":{"id":"me","name":"Alex"},"organization":{"id":"org","name":"Studio"}}}"#)
        }
        let profile = try await api.profile()
        #expect(profile.organization.name == "Studio")
    }

    @Test func testGraphQLErrorsAreRejectedEvenWithHTTP200AndData() async {
        let api = client { _ in (200, #"{"data":{"viewer":{"id":"me","name":"Alex"},"organization":{"id":"org","name":"Studio"}},"errors":[{"message":"Access denied"}]}"#) }
        do { _ = try await api.profile(); Issue.record("Partial GraphQL failure must not count as success") }
        catch { #expect(error.localizedDescription == "Access denied") }
    }

    @Test func testUnauthorizedAndRateLimitHaveActionableErrors() async {
        for status in [401, 403, 429, 503] {
            let api = client { _ in (status, "{}") }
            do { _ = try await api.profile(); Issue.record("HTTP \(status) must fail") }
            catch {
                switch status {
                case 401, 403: #expect(error.localizedDescription.contains("authenticate"))
                case 429: #expect(error.localizedDescription.contains("limit"))
                default: #expect(error.localizedDescription.contains("503"))
                }
            }
        }
    }

    @Test func testPartialNullDataStillShowsGraphQLError() async {
        let api = client { _ in (200, #"{"data":{"viewer":null},"errors":[{"message":"Missing read permission"}]}"#) }
        do { _ = try await api.profile(); Issue.record("Null partial data must fail") }
        catch { #expect(error.localizedDescription == "Missing read permission") }
    }

    @Test func testPaginationReturnsCursorAndHandlesNoIssues() async throws {
        let api = client { _ in (200, #"{"data":{"viewer":{"assignedIssues":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":"page-2"}}}}}"#) }
        let page = try await api.issues(after: "page-1")
        #expect(page.nodes.isEmpty)
        #expect(page.pageInfo.hasNextPage)
        #expect(page.pageInfo.endCursor == "page-2")
    }

    @Test func testCompletedIssueIsNeverReopenedByStartingTimer() async throws {
        var completed = LinearIssue.examples[0]
        completed.state = .init(id: "done", name: "Done", type: "completed")
        let json = String(data: try JSONEncoder().encode(completed), encoding: .utf8)!
        var requests = 0
        let api = client { _ in requests += 1; return (200, "{\"data\":{\"issue\":\(json)}}") }
        do { _ = try await api.markWorking(.examples[0]); Issue.record("Completed issue must be rejected") }
        catch { #expect(error.localizedDescription.contains("already completed")) }
        #expect(requests == 1)
    }

    @Test func testAlreadyStartedIssueAvoidsMutation() async throws {
        let issue = LinearIssue.examples[1]
        let json = String(data: try JSONEncoder().encode(issue), encoding: .utf8)!
        var requests = 0
        let api = client { _ in requests += 1; return (200, "{\"data\":{\"issue\":\(json)}}") }
        let result = try await api.markWorking(issue)
        #expect(result.state.type == "started")
        #expect(requests == 1)
    }

    @Test func testStartMovesIssueToWorkingStatusAndReturnsServerResult() async throws {
        let issue = LinearIssue.examples[0]
        var updated = issue
        updated.state = .init(id: "working", name: "Working", type: "started")
        let originalJSON = String(data: try JSONEncoder().encode(issue), encoding: .utf8)!
        let updatedJSON = String(data: try JSONEncoder().encode(updated), encoding: .utf8)!
        var requests = 0
        let api = client { _ in
            requests += 1
            switch requests {
            case 1: return (200, "{\"data\":{\"issue\":\(originalJSON)}}")
            case 2: return (200, #"{"data":{"team":{"states":{"nodes":[{"id":"working","name":"Working","type":"started","color":"888888","position":1}]}}}}"#)
            default: return (200, "{\"data\":{\"issueUpdate\":{\"success\":true,\"issue\":\(updatedJSON)}}}")
            }
        }
        let result = try await api.markWorking(issue)
        #expect(result.state.id == "working")
        #expect(requests == 3)
    }
}
