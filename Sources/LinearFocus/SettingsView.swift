import SwiftUI
import FocusCore

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var apiKey = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Make yourself at home.").font(.system(size: 23, weight: .medium))
                    Text("A few small settings for the way you work.").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }.padding(.top, 46)
                VStack(alignment: .leading, spacing: 16) {
                    SectionLabel(text: "Linear connection")
                    if model.connected {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.green)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(model.profile?.organization.name ?? "Linear").font(.system(size: 13, weight: .medium))
                                Text("Connected as \(model.profile?.viewer.name ?? "you")").font(.system(size: 11)).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Button("Disconnect") { model.disconnect() }.buttonStyle(QuietButton())
                                .disabled(model.session != nil || model.isLoading || model.isStarting)
                        }
                    } else {
                        Text("Connect with a personal API key").font(.system(size: 14, weight: .medium))
                        Text("In Linear, open Settings → Security & access → Personal API keys. Create a key with Read and Write permissions for the teams you want to use.")
                            .font(.system(size: 12)).foregroundStyle(Theme.muted).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                        Link("Open Linear settings ↗", destination: URL(string: "https://linear.app/settings/account/security")!)
                            .font(.system(size: 11)).foregroundStyle(Theme.accent)
                        SecureField("Paste your API key", text: $apiKey).textFieldStyle(.plain).font(.system(size: 12))
                            .padding(12).background(Theme.background, in: RoundedRectangle(cornerRadius: 8))
                            .accessibilityLabel("Linear personal API key").disabled(model.session != nil || model.isLoading)
                        Button {
                            let key = apiKey
                            Task { await model.connect(key: key); if model.connected { apiKey = "" } }
                        } label: {
                            HStack { if model.isLoading { ProgressView().controlSize(.mini) }; Text(model.isLoading ? "Connecting…" : "Connect to Linear") }
                        }.buttonStyle(PrimaryButton()).disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isLoading || model.session != nil)
                        Text("Your key is stored securely in macOS Keychain. It is sent only to Linear.")
                            .font(.system(size: 10)).foregroundStyle(Theme.muted)
                        if model.isDemo {
                            HStack {
                                Label("You’re exploring demo issues.", systemImage: "sparkle").font(.system(size: 11)).foregroundStyle(Theme.accent)
                                Spacer()
                                Button("Leave demo") { model.disconnect() }.buttonStyle(.plain).font(.system(size: 11))
                                    .disabled(model.session != nil || model.isLoading)
                            }
                        }
                    }
                    if model.session != nil {
                        Text("End the current session before changing accounts.").font(.system(size: 10)).foregroundStyle(Theme.accent)
                    }
                }.padding(20).background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 20) {
                    SectionLabel(text: "Focus preferences")
                    Toggle(isOn: $model.updateLinear) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Update Linear when I start").font(.system(size: 12, weight: .medium))
                            Text("Move the issue to a Working or In Progress status.").font(.system(size: 10)).foregroundStyle(Theme.muted)
                        }
                    }.toggleStyle(.switch).controlSize(.small)
                    if model.connected && model.updateLinear, let issue = model.selectedIssue {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Working status for \(issue.team.name)").font(.system(size: 11)).foregroundStyle(Theme.muted)
                            if model.isLoadingStates { ProgressView().controlSize(.small) }
                            else {
                                Picker("Working status", selection: Binding(get: { model.preferredStates[issue.team.id] ?? "" }, set: { value in
                                    if value.isEmpty { model.preferredStates.removeValue(forKey: issue.team.id) }
                                    else { model.preferredStates[issue.team.id] = value }
                                })) {
                                    Text("Automatic").tag("")
                                    ForEach(model.states) { state in Text(state.name).tag(state.id) }
                                }.labelsHidden()
                            }
                            Text("Choose an issue from a different team to configure that team.").font(.system(size: 10)).foregroundStyle(Theme.muted)
                        }.task(id: issue.team.id) { await model.loadStates() }
                    }
                    Rectangle().fill(Theme.line).frame(height: 1)
                    Toggle(isOn: $model.playSound) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Play a sound when time is up").font(.system(size: 12, weight: .medium))
                            Text("The floating timer also shows when your session is finished.").font(.system(size: 10)).foregroundStyle(Theme.muted)
                        }
                    }.toggleStyle(.switch).controlSize(.small)
                    HStack {
                        Text("Default session length").font(.system(size: 12))
                        Spacer()
                        Picker("Default duration", selection: $model.defaultMinutes) {
                            ForEach([15, 25, 45, 60], id: \.self) { Text("\($0) minutes").tag($0) }
                        }.labelsHidden().frame(width: 125)
                            .onChange(of: model.defaultMinutes) { _, value in if model.session == nil { model.minutes = String(value) } }
                    }
                }.padding(20).background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                Text("Linear Focus · v0.1\nMade for one issue at a time. Session history stays on this Mac.")
                    .font(.system(size: 10)).foregroundStyle(Theme.muted).lineSpacing(4)
            }.padding(.horizontal, 30).padding(.bottom, 28)
        }
    }
}
