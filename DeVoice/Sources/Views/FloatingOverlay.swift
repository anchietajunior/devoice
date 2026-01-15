import SwiftUI

struct FloatingOverlay: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor)
                .frame(width: 10, height: 10)

            Text(stateText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize()
        }
        .frame(width: 140, height: 32)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
        )
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
            return "Ready"
        case .recording:
            return "Recording..."
        case .processing:
            return "Texting..."
        }
    }
}
