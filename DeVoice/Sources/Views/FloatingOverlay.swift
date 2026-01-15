import SwiftUI

struct FloatingOverlay: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(stateColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(stateColor.opacity(0.5), lineWidth: 2)
                        .scaleEffect(appState.state == .recording ? 1.5 : 1.0)
                        .opacity(appState.state == .recording ? 0 : 1)
                        .animation(
                            appState.state == .recording
                                ? .easeOut(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: appState.state
                        )
                )

            Text(stateText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private var stateColor: Color {
        switch appState.state {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .processing:
            return .yellow
        }
    }

    private var stateText: String {
        switch appState.state {
        case .idle:
            return "Pronto"
        case .recording:
            return "Gravando..."
        case .processing:
            return "Transcrevendo..."
        }
    }
}
