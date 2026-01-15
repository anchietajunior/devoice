# DeVoice - Design Document

App de menu bar para macOS que converte voz em texto usando a API Whisper da OpenAI.

## Resumo

- **Tecnologia:** Swift/SwiftUI (nativo macOS)
- **Ativação:** Pressionar e segurar tecla `fn`
- **Feedback visual:** Menu bar com ícones coloridos + floating window no canto inferior direito
- **STT:** OpenAI Whisper API
- **Inicialização:** Manual (sem auto-start)

## Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                      DeVoice App                        │
├─────────────────────────────────────────────────────────┤
│  Menu Bar Controller                                    │
│  ├── StatusItem (ícone com cores)                       │
│  ├── Menu (Configurações, Sair)                         │
│  └── SettingsWindow (API Key)                           │
├─────────────────────────────────────────────────────────┤
│  Floating Window Controller                             │
│  └── StatusOverlay (canto inferior direito)             │
├─────────────────────────────────────────────────────────┤
│  Core Services                                          │
│  ├── HotkeyManager (captura tecla fn)                   │
│  ├── AudioRecorder (grava microfone)                    │
│  ├── WhisperService (OpenAI STT API)                    │
│  └── TextInjector (simula digitação)                    │
└─────────────────────────────────────────────────────────┘
```

## Estados do App

| Estado | Ícone Menu Bar | Floating Window |
|--------|---------------|-----------------|
| `idle` | Cinza | Oculta |
| `recording` | Vermelho | "Gravando..." |
| `processing` | Amarelo | "Transcrevendo..." |

## Fluxo Principal

1. Usuário pressiona e segura `fn`
2. App muda para `recording`, começa a gravar
3. Usuário solta `fn`
4. App muda para `processing`, envia áudio para OpenAI
5. Recebe texto, injeta onde o cursor está (via Cmd+V)
6. App volta para `idle`

## Componentes

### HotkeyManager

- Usa `CGEventTap` para capturar eventos de teclado globalmente
- Detecta `NSEvent.ModifierFlags.function` para a tecla `fn`
- Requer permissão de **Acessibilidade**
- Fallback: opção de usar tecla alternativa se `fn` for problemática

### AudioRecorder

- Framework: `AVFoundation`
- Formato: M4A (AAC), 16kHz, mono
- Arquivo temporário em `/tmp/devoice_recording.m4a`
- Limite: 25MB (~30 minutos)
- Requer permissão de **Microfone**

### WhisperService

- Endpoint: `POST https://api.openai.com/v1/audio/transcriptions`
- Modelo: `whisper-1`
- Detecção automática de idioma
- API Key armazenada no **Keychain** (seguro)

### TextInjector

- Método: Clipboard + Paste (Cmd+V)
- Preserva conteúdo anterior do clipboard
- Restaura clipboard original após 100ms
- Funciona em qualquer app

## Interface

### Menu Bar

- Ícone de microfone que muda de cor conforme estado
- Menu com:
  - "Configurações..." (Cmd+,)
  - Separador
  - "Sair" (Cmd+Q)

### Floating Window

- Posição: canto inferior direito, 20px de margem
- Estilo: pill escura com texto claro
- Aparece apenas durante `recording` e `processing`
- Conteúdo: indicador de cor + texto do estado

### Janela de Configurações

- Campo SecureField para API Key
- Botão "Salvar"
- Status da permissão de Acessibilidade

## Permissões Necessárias

1. **Acessibilidade** - Para capturar teclas globalmente e injetar texto
2. **Microfone** - Para gravar áudio

## Estrutura de Arquivos

```
DeVoice/
├── DeVoiceApp.swift          # Entry point
├── AppDelegate.swift         # Menu bar setup
├── AppState.swift            # Estado global do app
├── Services/
│   ├── HotkeyManager.swift   # Captura tecla fn
│   ├── AudioRecorder.swift   # Gravação de áudio
│   ├── WhisperService.swift  # API OpenAI
│   └── TextInjector.swift    # Injeção de texto
├── Views/
│   ├── FloatingOverlay.swift # Floating window
│   └── SettingsView.swift    # Configurações
├── Utilities/
│   └── KeychainHelper.swift  # Armazenamento seguro
└── Resources/
    └── Assets.xcassets/      # Ícones do menu bar
```
