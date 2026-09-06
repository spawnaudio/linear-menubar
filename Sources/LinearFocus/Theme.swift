import SwiftUI
import FocusCore

enum Theme {
    static let background = Color(red: 0.075, green: 0.078, blue: 0.094)
    static let sidebar = Color(red: 0.09, green: 0.095, blue: 0.112)
    static let surface = Color(red: 0.115, green: 0.12, blue: 0.14)
    static let elevated = Color(red: 0.15, green: 0.155, blue: 0.18)
    static let accent = Color(red: 0.66, green: 0.64, blue: 1)
    static let green = Color(red: 0.58, green: 0.81, blue: 0.67)
    static let muted = Color(red: 0.54, green: 0.55, blue: 0.61)
    static let line = Color.white.opacity(0.075)
}

struct FocusMark: View {
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28).fill(Theme.accent.opacity(0.13))
            Image(systemName: "scope").font(.system(size: size * 0.57, weight: .medium)).foregroundStyle(Theme.accent)
        }.frame(width: size, height: size)
    }
}

struct PrimaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var bodyColor = Theme.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.background).frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(bodyColor.opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4), in: RoundedRectangle(cornerRadius: 9))
            .contentShape(RoundedRectangle(cornerRadius: 9))
    }
}

struct QuietButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.055), in: RoundedRectangle(cornerRadius: 7))
    }
}

struct StatusDot: View {
    let state: WorkflowState
    var body: some View {
        Image(systemName: state.type == "started" ? "circle.lefthalf.filled" : "circle.dashed")
            .font(.system(size: 12, weight: .medium)).foregroundStyle(Color(hex: state.color))
            .accessibilityLabel(state.name)
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x8B87F8
        self.init(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(Theme.muted) }
}
