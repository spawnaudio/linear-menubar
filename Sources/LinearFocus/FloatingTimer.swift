import AppKit
import SwiftUI
import FocusCore

final class TimerPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class FloatingTimerController {
    let panel: TimerPanel
    private let model: AppModel
    private var collapseTask: DispatchWorkItem?
    private let defaults: UserDefaults
    private var moveObserver: NSObjectProtocol?
    private var screenObserver: NSObjectProtocol?
    private var resizing = false

    init(model: AppModel, defaults: UserDefaults = .standard) {
        self.model = model; self.defaults = defaults
        panel = TimerPanel(contentRect: NSRect(x: 0, y: 0, width: 302, height: 72), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true; panel.acceptsMouseMovedEvents = true
        panel.title = "Linear Focus Timer"
        panel.contentView = NSHostingView(rootView: FloatingTimerView(model: model, hover: { [weak self] in self?.hover($0) }))
        positionInitially()
        moveObserver = NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.savePosition() }
        }
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.keepOnScreen() }
        }
    }

    func show() { keepOnScreen(); panel.orderFrontRegardless() }
    func hide() { collapseTask?.cancel(); setExpanded(false); panel.orderOut(nil) }

    func hover(_ inside: Bool) {
        collapseTask?.cancel()
        if inside { setExpanded(true) }
        else {
            let task = DispatchWorkItem { [weak self] in self?.setExpanded(false) }
            collapseTask = task; DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: task)
        }
    }

    func setExpanded(_ expanded: Bool) {
        guard model.panelExpanded != expanded else { return }
        resizing = true
        var frame = panel.frame
        let top = frame.maxY
        frame.size.height = expanded ? 124 : 72
        frame.origin.y = top - frame.height
        model.panelExpanded = expanded
        panel.setFrame(frame, display: true)
        resizing = false
        keepOnScreen()
    }

    private func positionInitially() {
        if let saved = defaults.string(forKey: "timerPosition") { panel.setFrameOrigin(NSPointFromString(saved)) }
        else if let screen = NSScreen.main?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: screen.maxX - 324, y: screen.maxY - 94))
        }
        keepOnScreen()
    }

    private func keepOnScreen() {
        guard let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(panel.frame) }) ?? NSScreen.main else { return }
        let visible = screen.visibleFrame.insetBy(dx: 8, dy: 8)
        var origin = panel.frame.origin
        origin.x = min(max(origin.x, visible.minX), visible.maxX - panel.frame.width)
        origin.y = min(max(origin.y, visible.minY), visible.maxY - panel.frame.height)
        if origin != panel.frame.origin { panel.setFrameOrigin(origin) }
    }

    private func savePosition() {
        guard !resizing else { return }
        // Save the collapsed origin so the top edge returns to the same position.
        defaults.set(NSStringFromPoint(NSPoint(x: panel.frame.minX, y: panel.frame.maxY - 72)), forKey: "timerPosition")
    }
}

struct FloatingTimerView: View {
    @ObservedObject var model: AppModel
    var hover: (Bool) -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().stroke(.white.opacity(0.09), lineWidth: 2)
                    Circle().trim(from: 0, to: 1 - (model.session?.progress(at: model.now) ?? 0))
                        .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round)).rotationEffect(.degrees(-90))
                    Image(systemName: model.session?.phase == .finished ? "checkmark" : (model.session?.phase == .paused ? "pause.fill" : "scope"))
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(color)
                }.frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.session?.phase == .finished ? "Session complete" : (model.session?.issue.identifier ?? "Linear Focus"))
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(color).lineLimit(1)
                    Text(model.session?.issue.title ?? "One thing at a time.").font(.system(size: 10)).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Text(model.clockText).font(.system(size: 26, weight: .light, design: .rounded)).monospacedDigit().foregroundStyle(.white)
                    .fixedSize(horizontal: true, vertical: false)
            }.padding(.horizontal, 17).frame(height: 70)
            if model.panelExpanded {
                Rectangle().fill(.white.opacity(0.08)).frame(height: 1).padding(.horizontal, 14)
                HStack(spacing: 6) {
                    floatingButton("5 min", icon: "plus", help: "Add five minutes") { model.addTime() }
                    if model.session?.phase == .finished {
                        floatingButton("Finish", icon: "checkmark", help: "Save and finish session") { model.endSession() }
                    } else {
                        floatingButton(model.session?.phase == .paused ? "Resume" : "Pause", icon: model.session?.phase == .paused ? "play.fill" : "pause.fill", help: "Pause or resume timer") { model.togglePause() }
                    }
                    floatingButton("Open", icon: "arrow.up.right", help: "Open main window") { model.showMain?() }
                }.padding(.horizontal, 12).frame(height: 51)
            }
        }.frame(width: 300, height: model.panelExpanded ? 122 : 70, alignment: .top)
            .background(Theme.background.opacity(0.97), in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.14), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 17)).padding(1)
            .preferredColorScheme(.dark).onHover(perform: hover)
            .help("Drag to move. Hover for timer controls.")
            .accessibilityElement(children: .contain).accessibilityLabel("Floating focus timer, \(model.clockText)")
    }

    private var color: Color { model.session?.phase == .finished ? Theme.green : Theme.accent }
    private func floatingButton(_ title: String, icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) { Image(systemName: icon).font(.system(size: 9)); Text(title).font(.system(size: 10, weight: .medium)) }
                .frame(maxWidth: .infinity).padding(.vertical, 8).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
        }.buttonStyle(.plain).foregroundStyle(.white.opacity(0.8)).help(help)
    }
}

struct MenuView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack { FocusMark(size: 25); Text("Linear Focus").font(.system(size: 13, weight: .semibold)); Spacer(); if model.isDemo { Text("DEMO").font(.system(size: 9)).foregroundStyle(Theme.accent) } }
            if let session = model.session {
                Text(session.issue.title).font(.system(size: 12)).lineLimit(2)
                HStack {
                    Text(model.clockText).font(.system(size: 32, weight: .light, design: .rounded)).monospacedDigit()
                    Spacer()
                    Text(session.phase == .finished ? "Finished" : (session.phase == .paused ? "Paused" : "Focusing")).font(.system(size: 11)).foregroundStyle(Theme.accent)
                }
                HStack {
                    Button("+5 min") { model.addTime() }.buttonStyle(QuietButton())
                    if session.phase == .finished { Button("Finish") { model.endSession() }.buttonStyle(QuietButton()) }
                    else { Button(session.phase == .paused ? "Resume" : "Pause") { model.togglePause() }.buttonStyle(QuietButton()) }
                    Button { model.showTimer?() } label: { Image(systemName: "macwindow") }.buttonStyle(QuietButton()).help("Show floating timer")
                }
            } else { Text("Ready when you are.").font(.system(size: 12)).foregroundStyle(Theme.muted) }
            Button(model.session == nil ? "Choose an issue" : "Open main window") { model.showMain?() }.buttonStyle(PrimaryButton())
            HStack {
                Button("Settings…") { model.page = .settings; model.showMain?() }.buttonStyle(.plain)
                Spacer()
                Button("Quit") { model.persist(); NSApp.terminate(nil) }.buttonStyle(.plain)
            }.font(.system(size: 11)).foregroundStyle(Theme.muted)
        }.padding(20).frame(width: 285).background(Theme.background).preferredColorScheme(.dark)
    }
}
