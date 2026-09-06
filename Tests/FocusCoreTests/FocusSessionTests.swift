import Foundation
import Testing
@testable import FocusCore

@Suite(.serialized)
struct FocusSessionTests {
    let start = Date(timeIntervalSince1970: 1_000)
    func makeSession() -> FocusSession { FocusSession(issue: .examples[0], duration: 1_500, now: start, isDemo: true) }

    @Test func testCountdownUsesDeadlineAcrossSleep() {
        var session = makeSession()
        #expect(session.remaining(at: start.addingTimeInterval(420)) == 1080)
        let expired = session.reconcile(at: start.addingTimeInterval(1800))
        #expect(expired)
        #expect(session.phase == .finished)
        #expect(session.remaining(at: start.addingTimeInterval(1800)) == 0)
        #expect(session.finishedAt == start.addingTimeInterval(1500))
        let expiredAgain = session.reconcile(at: start.addingTimeInterval(1801))
        #expect(!expiredAgain)
    }

    @Test func testPausedTimeDoesNotCountTowardSession() {
        var session = makeSession()
        session.pause(at: start.addingTimeInterval(100))
        #expect(session.remaining(at: start.addingTimeInterval(900)) == 1400)
        session.resume(at: start.addingTimeInterval(900))
        #expect(session.remaining(at: start.addingTimeInterval(1000)) == 1300)
        #expect(session.elapsed(at: start.addingTimeInterval(1000)) == 200)
    }

    @Test func testAddTimeWhileRunningKeepsElapsedTime() {
        var session = makeSession()
        session.addTime(300, at: start.addingTimeInterval(100))
        #expect(session.remaining(at: start.addingTimeInterval(100)) == 1700)
        #expect(session.elapsed(at: start.addingTimeInterval(100)) == 100)
    }

    @Test func testAddTimeWhilePausedStaysPaused() {
        var session = makeSession()
        session.pause(at: start.addingTimeInterval(100))
        session.addTime(300, at: start.addingTimeInterval(1000))
        #expect(session.phase == .paused)
        #expect(session.remaining(at: start.addingTimeInterval(2000)) == 1700)
        #expect(session.deadline == nil)
    }

    @Test func testAddTimeAfterExpiryStartsFromNow() {
        var session = makeSession()
        session.addTime(300, at: start.addingTimeInterval(4000))
        #expect(session.phase == .running)
        #expect(session.remaining(at: start.addingTimeInterval(4000)) == 300)
        #expect(session.elapsed(at: start.addingTimeInterval(4000)) == 1500)
        #expect(session.finishedAt == nil)
    }

    @Test func testPauseAfterExpiryFinishesInsteadOfFreezingZero() {
        var session = makeSession()
        session.pause(at: start.addingTimeInterval(1501))
        #expect(session.phase == .finished)
        session.resume(at: start.addingTimeInterval(1502))
        #expect(session.phase == .finished)
    }

    @Test func testRestoringRunningSessionPreservesDeadline() throws {
        let data = try JSONEncoder().encode(makeSession())
        var restored = try JSONDecoder().decode(FocusSession.self, from: data)
        #expect(restored.remaining(at: start.addingTimeInterval(800)) == 700)
        restored.reconcile(at: start.addingTimeInterval(2000))
        #expect(restored.phase == .finished)
    }

    @Test func testRestoringPausedSessionPreservesRemainingTime() throws {
        var session = makeSession()
        session.pause(at: start.addingTimeInterval(99))
        let restored = try JSONDecoder().decode(FocusSession.self, from: JSONEncoder().encode(session))
        #expect(restored.remaining(at: start.addingTimeInterval(90_000)) == 1401)
        #expect(restored.phase == .paused)
    }

    @Test func testHistoryExcludesPauseAndPreservesIssueStatus() {
        var session = makeSession()
        session.pause(at: start.addingTimeInterval(90))
        let record = SessionRecord(session: session, now: start.addingTimeInterval(500))
        #expect(record.focusedSeconds == 90)
        #expect(!(record.completed))
        #expect(record.issue.state == session.issue.state)
    }

    @Test func testClockRoundsUpAndNeverShowsNegativeTime() {
        #expect(FocusSession.clockString(0.2) == "00:01")
        #expect(FocusSession.clockString(-5) == "00:00")
        #expect(FocusSession.clockString(1500) == "25:00")
        #expect(FocusSession.clockString(7200) == "120:00")
    }

    @Test func testWorkingStateUsesOnlyActiveStatuses() {
        let misleading = WorkflowState(id: "bad", name: "Working", type: "completed")
        let active = WorkflowState(id: "a", name: "In Progress", type: "started", position: 2)
        let custom = WorkflowState(id: "b", name: "Building", type: "started", position: 1)
        #expect(WorkflowState.workingState(in: [misleading, custom, active])?.id == "a")
        #expect(WorkflowState.workingState(in: [active, custom], preferredID: "b")?.id == "b")
        #expect(WorkflowState.workingState(in: [custom], preferredID: "deleted")?.id == "b")
        #expect(WorkflowState.workingState(in: [misleading]) == nil)
    }
}
