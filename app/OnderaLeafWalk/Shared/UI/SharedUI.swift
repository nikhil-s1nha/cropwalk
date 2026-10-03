import SwiftUI

/// Large, high-contrast button for outdoor use with gloves/dirty hands. Min height 60 pt.
struct BigButtonStyle: ButtonStyle {
    var prominent = true
    var tint: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 16)
            .foregroundStyle(prominent ? Color.white : tint)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(prominent ? tint : tint.opacity(0.12))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Visible on every screen showing synthetic / simulated data (hard rule 9).
struct DemoBadge: View {
    var body: some View {
        Text("demo.badge", tableName: "Infra")
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.purple.opacity(0.15)))
            .foregroundStyle(.purple)
            .accessibilityIdentifier("demo.badge")
    }
}

#Preview {
    VStack {
        DemoBadge()
        Button("Anza") {}.buttonStyle(BigButtonStyle())
        Button("Ruka") {}.buttonStyle(BigButtonStyle(prominent: false))
    }
    .padding()
}
