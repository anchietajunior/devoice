import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKeyInput: String = ""
    @State private var showKey: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configurações")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("OpenAI API Key")
                    .font(.headline)

                HStack {
                    if showKey {
                        TextField("sk-...", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("sk-...", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: { showKey.toggle() }) {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                Text("Sua API key é armazenada de forma segura no Keychain.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Permissões")
                    .font(.headline)

                HStack {
                    Image(systemName: TextInjector.checkAccessibilityPermission() ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(TextInjector.checkAccessibilityPermission() ? .green : .red)
                    Text("Acessibilidade")
                    Spacer()
                    if !TextInjector.checkAccessibilityPermission() {
                        Button("Habilitar") {
                            TextInjector.requestAccessibilityPermission()
                        }
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Salvar") {
                    appState.saveAPIKey(apiKeyInput)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(apiKeyInput.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400, height: 280)
        .onAppear {
            apiKeyInput = appState.apiKey
        }
    }
}
