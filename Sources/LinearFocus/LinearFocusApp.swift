import AppKit
import SwiftUI
import FocusCore

@main
enum LinearFocusApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
        withExtendedLifetime(delegate) {}
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel!
    private var statusItem: NSStatusItem!
    private var mainWindow: NSWindow!
    private var floating: FloatingTimerController!
    private let popover = NSPopover()
    private var lastStatusText = ""
    private var wakeObserver: NSObjectProtocol?
    private var previewSuite: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let preview = CommandLine.arguments.contains("--smoke-test")
        let defaults: UserDefaults
        if preview {
            let suite = "app.linearfocus.preview.\(ProcessInfo.processInfo.processIdentifier)"
            previewSuite = suite
            defaults = UserDefaults(suiteName: suite)!
            defaults.removePersistentDomain(forName: suite)
        } else { defaults = .standard }
        model = AppModel(defaults: defaults, preview: preview)
        model.showMain = { [weak self] in self?.openMainWindow() }
        model.showTimer = { [weak self] in self?.floating.show() }
        model.hideTimer = { [weak self] in self?.floating.hide() }
        model.onTick = { [weak self] in self?.updateStatusItem() }
        floating = FloatingTimerController(model: model, defaults: defaults)
        setupMainWindow()
        setupMenuBar()
        setupApplicationMenu()
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.tick(Date()) }
        }
        if preview {
            Task { await runSmokeTest() }
        } else {
            openMainWindow()
            if model.session != nil { floating.show() }
            Task { await model.bootstrap() }
        }
    }

    private func setupMainWindow() {
        mainWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 940, height: 650),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        mainWindow.title = "Linear Focus"
        mainWindow.titlebarAppearsTransparent = true; mainWindow.titleVisibility = .hidden
        mainWindow.backgroundColor = NSColor(Theme.background)
        mainWindow.isReleasedWhenClosed = false; mainWindow.minSize = NSSize(width: 870, height: 600)
        mainWindow.contentView = NSHostingView(rootView: MainView(model: model))
        mainWindow.setFrameAutosaveName("LinearFocusMainWindow")
        mainWindow.center()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scope", accessibilityDescription: "Linear Focus")
            button.imagePosition = .imageLeading
            button.target = self; button.action = #selector(togglePopover)
            button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        }
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuView(model: model))
        updateStatusItem()
    }

    private func setupApplicationMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu()
        let open = NSMenuItem(title: "Open Linear Focus", action: #selector(openFromMenu), keyEquivalent: "0")
        open.target = self; appMenu.addItem(open)
        let settings = NSMenuItem(title: "Settings…", action: #selector(settingsFromMenu), keyEquivalent: ",")
        settings.target = self; appMenu.addItem(settings)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Linear Focus", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu
        let editItem = NSMenuItem(); menu.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        for (title, action, key) in [("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            edit.addItem(NSMenuItem(title: title, action: Selector(action), keyEquivalent: key))
        }
        editItem.submenu = edit; NSApp.mainMenu = menu
    }

    @objc private func togglePopover() {
        if popover.isShown { popover.performClose(nil) }
        else if let button = statusItem.button { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
    }
    @objc private func openFromMenu() { openMainWindow() }
    @objc private func settingsFromMenu() { model.page = .settings; openMainWindow() }

    func openMainWindow() {
        popover.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow.makeKeyAndOrderFront(nil)
    }

    private func updateStatusItem() {
        let title = model.session == nil ? "" : "  \(model.session?.phase == .paused ? "Ⅱ " : "")\(model.clockText)"
        if title != lastStatusText { statusItem.button?.title = title; lastStatusText = title }
        statusItem.button?.toolTip = model.session.map { "\($0.issue.identifier) · \($0.issue.title) — \(model.clockText)" } ?? "Linear Focus — choose an issue"
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { openMainWindow(); return true }
    func applicationWillTerminate(_ notification: Notification) {
        if let previewSuite { UserDefaults(suiteName: previewSuite)?.removePersistentDomain(forName: previewSuite) }
        else { model.persist() }
    }

    private func snapshot<V: View>(_ view: V, size: NSSize, to url: URL) throws {
        let host = NSHostingView(rootView: view)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host; host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded(); host.displayIfNeeded()
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { throw LinearError.malformed }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw LinearError.malformed }
        try data.write(to: url)
        window.close()
    }

    // This isolated demo harness never reads Keychain or contacts Linear.
    private func runSmokeTest() async {
        do {
            guard let index = CommandLine.arguments.firstIndex(of: "--smoke-test"), CommandLine.arguments.count > index + 1 else { throw LinearError.malformed }
            let output = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            model.playSound = false
            try snapshot(MainView(model: model), size: NSSize(width: 940, height: 650), to: output.appendingPathComponent("01-issues.png"))
            await model.start()
            guard model.session?.phase == .running, floating.panel.isVisible else { throw LinearError.malformed }
            model.togglePause()
            let paused = model.remaining
            model.addTime()
            guard model.session?.phase == .paused, abs(model.remaining - paused - 300) < 0.1 else { throw LinearError.malformed }
            let restored = AppModel(defaults: UserDefaults(suiteName: previewSuite!)!, preview: true)
            guard restored.session?.id == model.session?.id, restored.session?.phase == .paused,
                  abs(restored.remaining - model.remaining) < 0.1 else { throw LinearError.malformed }
            try snapshot(MainView(model: model), size: NSSize(width: 940, height: 650), to: output.appendingPathComponent("02-session.png"))
            try snapshot(FloatingTimerView(model: model, hover: { _ in }), size: NSSize(width: 302, height: 72), to: output.appendingPathComponent("03-floating.png"))
            floating.setExpanded(true)
            guard floating.panel.frame.height == 124, floating.panel.level == .floating,
                  floating.panel.collectionBehavior.contains(.canJoinAllSpaces),
                  floating.panel.collectionBehavior.contains(.fullScreenAuxiliary),
                  !floating.panel.hidesOnDeactivate, !floating.panel.canBecomeKey else { throw LinearError.malformed }
            try snapshot(FloatingTimerView(model: model, hover: { _ in }), size: NSSize(width: 302, height: 124), to: output.appendingPathComponent("04-hover.png"))
            model.togglePause()
            model.tick(Date().addingTimeInterval(3600))
            guard model.session?.phase == .finished, model.clockText == "00:00" else { throw LinearError.malformed }
            try snapshot(FloatingTimerView(model: model, hover: { _ in }), size: NSSize(width: 302, height: 124), to: output.appendingPathComponent("05-finished.png"))
            model.endSession()
            guard model.history.count == 1, model.session == nil, !floating.panel.isVisible else { throw LinearError.malformed }
            model.page = .history
            try snapshot(MainView(model: model), size: NSSize(width: 940, height: 650), to: output.appendingPathComponent("06-history.png"))
            model.page = .settings
            try snapshot(MainView(model: model), size: NSSize(width: 940, height: 650), to: output.appendingPathComponent("07-settings.png"))
            model.isDemo = false; model.issues = []; model.page = .focus
            try snapshot(MainView(model: model), size: NSSize(width: 940, height: 650), to: output.appendingPathComponent("08-welcome.png"))
            try "PASS: demo start, pause, add time while paused, resume, expiry, history, panel configuration, and 8 native view renders.\n".write(to: output.appendingPathComponent("smoke-test.txt"), atomically: true, encoding: .utf8)
            print("UI smoke test passed. Screenshots: \(output.path)")
            NSApp.terminate(nil)
        } catch {
            fputs("UI smoke test failed: \(error)\n", stderr)
            exit(1)
        }
    }
}
