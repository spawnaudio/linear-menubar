import SwiftUI
import FocusCore

struct MainView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle().fill(Theme.line).frame(width: 1)
            VStack(spacing: 0) {
                if let error = model.error { errorBanner(error) }
                if model.page == .settings { SettingsView(model: model) }
                else if !model.connected && !model.isDemo && model.session == nil { WelcomeView(model: model) }
                else if model.page == .history { HistoryView(model: model) }
                else { focusPage }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background).preferredColorScheme(.dark)
        .frame(minWidth: 840, minHeight: 570)
        .tint(Theme.accent)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                FocusMark()
                VStack(alignment: .leading, spacing: 3) {
                    Text("Linear Focus").font(.system(size: 14, weight: .semibold))
                    Text("A little space to focus.").font(.system(size: 10)).foregroundStyle(Theme.muted)
                }
            }.padding(.top, 52).padding(.bottom, 34)
            SectionLabel(text: "Workspace").padding(.leading, 10).padding(.bottom, 12)
            navItem(.focus, icon: "tray")
            navItem(.history, icon: "clock.arrow.circlepath")
            Spacer()
            if model.connected || model.isDemo {
                VStack(alignment: .leading, spacing: 12) {
                    HStack { SectionLabel(text: model.isDemo ? "Demo sessions today" : "Today"); Spacer(); Image(systemName: "sun.max").foregroundStyle(Theme.muted) }
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(model.todayMinutes)").font(.system(size: 28, weight: .light, design: .rounded))
                        Text("min focused").font(.system(size: 11)).foregroundStyle(Theme.muted)
                    }
                    Text("\(model.todayRecords.count) \(model.todayRecords.count == 1 ? "session" : "sessions") saved").font(.system(size: 10)).foregroundStyle(Theme.muted)
                }.padding(14).background(Theme.surface, in: RoundedRectangle(cornerRadius: 10)).padding(.bottom, 20)
            }
            navItem(.settings, icon: "gearshape")
            Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 15)
            HStack(spacing: 8) {
                Circle().fill(model.isDemo ? Theme.accent : (model.connected ? Theme.green : Theme.muted)).frame(width: 6, height: 6)
                Text(model.isDemo ? "Demo workspace" : (model.profile?.organization.name ?? "Linear not connected"))
                    .font(.system(size: 11)).foregroundStyle(Theme.muted).lineLimit(1)
            }.padding(.horizontal, 8).padding(.bottom, 20)
        }.padding(.horizontal, 16).frame(width: 196).background(Theme.sidebar)
    }

    private func navItem(_ page: AppModel.Page, icon: String) -> some View {
        Button { model.page = page } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).frame(width: 16)
                Text(page.rawValue)
                Spacer()
                if page == .focus && !model.issues.isEmpty { Text("\(model.issues.count)").font(.system(size: 10)).foregroundStyle(Theme.muted) }
            }.font(.system(size: 12, weight: model.page == page ? .medium : .regular))
                .foregroundStyle(model.page == page ? .white : Theme.muted)
                .padding(.horizontal, 11).padding(.vertical, 11)
                .background(model.page == page ? Theme.elevated : .clear, in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain).padding(.bottom, 4)
    }

    private var focusPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("One issue. Your full attention.").font(.system(size: 23, weight: .medium))
                    Text("Choose your next step, and give it a little time.").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                Spacer()
                if model.isDemo { Text("DEMO").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Theme.accent).padding(7).background(Theme.accent.opacity(0.1), in: Capsule()) }
            }.padding(.top, 46).padding(.bottom, 28)
            HStack(alignment: .top, spacing: 22) {
                issueList.frame(maxWidth: .infinity, maxHeight: .infinity)
                Rectangle().fill(Theme.line).frame(width: 1)
                SessionView(model: model).frame(width: 254)
            }
        }.padding(.horizontal, 28).padding(.bottom, 24)
    }

    private var issueList: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                SectionLabel(text: "Assigned to you")
                Spacer()
                Button { Task { await model.refresh() } } label: {
                    if model.isLoading { ProgressView().controlSize(.mini) }
                    else { Image(systemName: "arrow.clockwise").foregroundStyle(Theme.muted) }
                }.buttonStyle(.plain).disabled(model.isLoading || model.isStarting || model.isDemo).help("Refresh Linear issues")
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.muted)
                TextField("Search issues…", text: $model.search).textFieldStyle(.plain).font(.system(size: 12))
                    .accessibilityLabel("Search loaded Linear issues")
                if !model.search.isEmpty { Button { model.search = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain).foregroundStyle(Theme.muted) }
            }.padding(10).background(Theme.surface, in: RoundedRectangle(cornerRadius: 8))
            HStack(spacing: 6) {
                ForEach(["All issues", "In progress"], id: \.self) { filter in
                    Button { model.filter = filter } label: {
                        Text(filter).font(.system(size: 10, weight: .medium)).padding(.horizontal, 10).padding(.vertical, 6)
                            .foregroundStyle(model.filter == filter ? .white : Theme.muted)
                            .background(model.filter == filter ? Theme.elevated : .clear, in: Capsule())
                    }.buttonStyle(.plain)
                }
            }
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(model.visibleIssues) { issue in issueRow(issue) }
                    if model.visibleIssues.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray").font(.system(size: 25)).foregroundStyle(Theme.muted)
                            Text(model.search.isEmpty ? "Nothing here just yet" : "No matching issues").font(.system(size: 13, weight: .medium))
                            Text(model.search.isEmpty ? "Open issues assigned to you in Linear appear here." : "Try another title or issue ID. Search covers loaded issues.")
                                .font(.system(size: 11)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                        }.padding(.vertical, 34).padding(.horizontal, 10)
                    }
                    if model.hasMore {
                        Button("Load more issues") { Task { await model.refresh(loadMore: true) } }
                            .buttonStyle(QuietButton()).disabled(model.isLoading || model.isStarting).padding(.top, 10)
                    }
                }
            }.scrollIndicators(.hidden)
            HStack(spacing: 5) {
                Image(systemName: model.isDemo ? "sparkle" : "arrow.triangle.2.circlepath")
                Text(model.isDemo ? "Sample issues. Try the whole timer." : "Your issues, connected to Linear.")
            }.font(.system(size: 10)).foregroundStyle(Theme.muted)
        }
    }

    private func issueRow(_ issue: LinearIssue) -> some View {
        Button { model.selectedID = issue.id } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    StatusDot(state: issue.state)
                    Text(issue.identifier).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(Theme.muted)
                    Spacer()
                    if model.session?.issue.id == issue.id {
                        Image(systemName: "waveform").foregroundStyle(Theme.accent)
                    } else if model.selectedID == issue.id { Image(systemName: "checkmark").font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.accent) }
                }
                Text(issue.title).font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Text(issue.project?.name ?? issue.team.name).font(.system(size: 10)).foregroundStyle(Theme.muted).lineLimit(1)
            }.padding(13).frame(maxWidth: .infinity, alignment: .leading)
                .background(model.selectedID == issue.id ? Theme.accent.opacity(0.075) : Theme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(model.selectedID == issue.id ? Theme.accent.opacity(0.4) : Theme.line, lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 9))
        }.buttonStyle(.plain).accessibilityLabel("\(issue.identifier), \(issue.title), \(issue.state.name)")
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle").foregroundStyle(.orange)
            Text(error).font(.system(size: 12)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
            Button { model.error = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain).help("Dismiss error")
        }.padding(14).background(Color.orange.opacity(0.09)).padding(.top, 30)
    }
}

struct SessionView: View {
    @ObservedObject var model: AppModel
    @State private var confirmEnd = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionLabel(text: model.session == nil ? "Your next session" : "Current session")
            if let session = model.session { active(session) }
            else if let issue = model.selectedIssue { ready(issue) }
            else {
                Spacer()
                Image(systemName: "scope").font(.system(size: 36, weight: .ultraLight)).foregroundStyle(Theme.accent)
                Text("Start small.").font(.system(size: 20, weight: .medium))
                Text("Select an issue to make space for your next step.").font(.system(size: 12)).foregroundStyle(Theme.muted)
                Spacer()
            }
        }.frame(maxHeight: .infinity, alignment: .top)
            .confirmationDialog("End this focus session?", isPresented: $confirmEnd, titleVisibility: .visible) {
                Button("End session", role: .destructive) { model.endSession() }
                Button("Keep focusing", role: .cancel) { }
            } message: { Text("Your focused time will be saved. The issue will stay in its current Linear status.") }
    }

    private func issueHeading(_ issue: LinearIssue) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 7) {
                StatusDot(state: issue.state)
                Text(issue.identifier).font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.muted)
                Spacer()
                if !issue.url.isEmpty {
                    Button { model.openIssue(issue) } label: { Image(systemName: "arrow.up.right").font(.system(size: 10)) }
                        .buttonStyle(.plain).foregroundStyle(Theme.muted).help("Open issue in Linear")
                }
            }
            Text(issue.title).font(.system(size: 18, weight: .medium)).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            Text(issue.project?.name ?? issue.team.name).font(.system(size: 11)).foregroundStyle(Theme.muted)
        }
    }

    private func ready(_ issue: LinearIssue) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            issueHeading(issue)
            Rectangle().fill(Theme.line).frame(height: 1)
            VStack(alignment: .leading, spacing: 12) {
                Text("How long would you like to focus?").font(.system(size: 12)).foregroundStyle(.white.opacity(0.75))
                HStack(spacing: 7) {
                    ForEach([15, 25, 45, 60], id: \.self) { minutes in
                        Button { model.minutes = String(minutes) } label: {
                            Text("\(minutes)m").font(.system(size: 12, weight: .medium)).frame(maxWidth: .infinity).padding(.vertical, 10)
                                .foregroundStyle(model.minutes == String(minutes) ? Theme.accent : Theme.muted)
                                .background(model.minutes == String(minutes) ? Theme.accent.opacity(0.12) : Theme.surface, in: RoundedRectangle(cornerRadius: 7))
                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(model.minutes == String(minutes) ? Theme.accent.opacity(0.35) : .clear))
                        }.buttonStyle(.plain)
                    }
                }
                HStack {
                    Text("Or set your own").font(.system(size: 11)).foregroundStyle(Theme.muted)
                    Spacer()
                    TextField("25", text: $model.minutes).textFieldStyle(.plain).multilineTextAlignment(.trailing)
                        .font(.system(size: 13, design: .monospaced)).frame(width: 42).padding(7)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6)).accessibilityLabel("Session duration in minutes")
                    Text("min").font(.system(size: 11)).foregroundStyle(Theme.muted)
                }
                if model.duration == nil { Text("Enter a whole number from 1 to 480.").font(.system(size: 10)).foregroundStyle(.orange) }
            }
            Button { Task { await model.start() } } label: {
                HStack(spacing: 8) {
                    if model.isStarting { ProgressView().controlSize(.mini) } else { Image(systemName: "play.fill").font(.system(size: 10)) }
                    Text(model.isStarting ? "Updating Linear…" : "Start focusing")
                    Spacer()
                    Text("↵").opacity(0.6)
                }.padding(.horizontal, 14)
            }.buttonStyle(PrimaryButton()).keyboardShortcut(.return, modifiers: [])
                .disabled(model.duration == nil || model.isStarting || model.isLoading).opacity(model.duration == nil ? 0.4 : 1)
            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "arrow.triangle.2.circlepath").padding(.top, 1)
                Text(model.isDemo ? "Demo mode lets you try the timer without changing Linear." : (model.updateLinear ? "Starting moves this issue to an active status in Linear." : "Status updates are off. Only the timer will start."))
                    .fixedSize(horizontal: false, vertical: true)
            }.font(.system(size: 10)).foregroundStyle(Theme.muted)
            Spacer(minLength: 0)
            HStack(spacing: 7) {
                Image(systemName: "macwindow")
                Text("Your timer floats above your work.")
            }.font(.system(size: 10)).foregroundStyle(Theme.muted)
        }.disabled(model.isStarting)
    }

    private func active(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            issueHeading(session.issue)
            VStack(spacing: 12) {
                Text(session.phase == .finished ? "TIME WELL SPENT" : (session.phase == .paused ? "TAKE A BREATH" : "YOU’RE FOCUSING"))
                    .font(.system(size: 9, weight: .semibold)).tracking(1.5).foregroundStyle(session.phase == .finished ? Theme.green : Theme.accent)
                Text(model.clockText).font(.system(size: 54, weight: .ultraLight, design: .rounded)).monospacedDigit().contentTransition(.numericText())
                ProgressView(value: session.progress(at: model.now)).tint(session.phase == .finished ? Theme.green : Theme.accent)
                Text(session.phase == .finished ? "Nice work. Take a moment to reset." : (session.phase == .paused ? "Your time is paused." : "Just this one thing, for now."))
                    .font(.system(size: 11)).foregroundStyle(Theme.muted)
            }.padding(.vertical, 20).padding(.horizontal, 15).frame(maxWidth: .infinity)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            HStack(spacing: 8) {
                Button { model.addTime() } label: { Label("5 min", systemImage: "plus").frame(maxWidth: .infinity) }.buttonStyle(QuietButton())
                if session.phase != .finished {
                    Button { model.togglePause() } label: { Label(session.phase == .paused ? "Resume" : "Pause", systemImage: session.phase == .paused ? "play.fill" : "pause.fill").frame(maxWidth: .infinity) }.buttonStyle(QuietButton())
                }
            }
            if session.phase == .finished {
                Button("Finish session") { model.endSession() }.buttonStyle(PrimaryButton(bodyColor: Theme.green))
                Text("The issue stays in progress in Linear.").font(.system(size: 10)).foregroundStyle(Theme.muted)
            } else {
                HStack {
                    Button { model.showTimer?() } label: { Label("Show timer", systemImage: "macwindow") }.buttonStyle(.plain)
                    Spacer()
                    Button("End session") { confirmEnd = true }.buttonStyle(.plain)
                }.font(.system(size: 10)).foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
        }
    }
}

struct WelcomeView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            FocusMark(size: 64)
            VStack(spacing: 10) {
                Text("Less switching.\nMore doing.").font(.system(size: 34, weight: .medium)).multilineTextAlignment(.center)
                Text("Bring a Linear issue into focus with a small,\nalways-visible timer. One thing at a time.")
                    .font(.system(size: 13)).lineSpacing(5).multilineTextAlignment(.center).foregroundStyle(Theme.muted)
            }
            VStack(spacing: 12) {
                Button("Connect to Linear") { model.page = .settings }.buttonStyle(PrimaryButton())
                Button("Try it with demo issues") { model.useDemo() }.buttonStyle(.plain).foregroundStyle(Theme.muted).font(.system(size: 12))
            }.frame(width: 220).padding(.top, 8).disabled(model.isLoading)
            if model.isLoading { ProgressView("Connecting to Linear…").controlSize(.small) }
            Spacer()
            HStack(spacing: 22) {
                Label("Lives in your menu bar", systemImage: "menubar.rectangle")
                Label("Made for your Mac", systemImage: "apple.logo")
            }.font(.system(size: 10)).foregroundStyle(Theme.muted).padding(.bottom, 30)
        }.frame(maxWidth: .infinity)
    }
}

struct HistoryView: View {
    @ObservedObject var model: AppModel
    var records: [SessionRecord] { model.history.filter { $0.isDemo == model.isDemo } }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 7) {
                Text("A little progress adds up.").font(.system(size: 23, weight: .medium))
                Text(model.isDemo ? "Your saved demo sessions." : "Your recent focus sessions, saved on this Mac.").font(.system(size: 12)).foregroundStyle(Theme.muted)
            }.padding(.top, 46)
            if records.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 35, weight: .light)).foregroundStyle(Theme.accent)
                    Text("Your first session starts with one issue.").font(.system(size: 14))
                    Text("End or finish a session to save it here.").font(.system(size: 12)).foregroundStyle(Theme.muted)
                    Button("Choose an issue") { model.page = .focus }.buttonStyle(QuietButton()).padding(.top, 8)
                }.frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(records) { record in
                            HStack(spacing: 14) {
                                Image(systemName: record.completed ? "checkmark.circle" : "stop.circle").foregroundStyle(record.completed ? Theme.green : Theme.muted)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(record.issue.title).font(.system(size: 12, weight: .medium)).lineLimit(2)
                                    Text("\(record.issue.identifier) · \(record.endedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.system(size: 10)).foregroundStyle(Theme.muted)
                                }
                                Spacer()
                                Text(record.focusedSeconds < 60 ? "< 1 min" : "\(Int(record.focusedSeconds / 60)) min")
                                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Theme.accent)
                            }.padding(15).background(Theme.surface)
                        }
                    }.clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }.padding(.horizontal, 30).padding(.bottom, 28).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
