# Whisper Hotkey

**Free, offline speech-to-text for macOS. Press `Ctrl+T`, talk, press `Return`.**

Your voice becomes text in any app. No cloud. No API keys. No subscription. Just one binary and your microphone.

[Website](https://augmentedmike.github.io/whisper-hotkey/) · [Download](https://github.com/augmentedmike/whisper-hotkey/releases) · [Source](https://github.com/augmentedmike/whisper-hotkey)

---

## Features

- **Completely local** — audio never leaves your Mac. Powered by [whisper.cpp](https://github.com/ggml-org/whisper.cpp).
- **Free forever** — no API keys, no accounts, no usage limits.
- **Fast** — optimized for Apple Silicon via [SwiftWhisper](https://github.com/exPHAT/SwiftWhisper). Transcription takes seconds.
- **Works everywhere** — types directly into whatever text field is focused. Slack, Notes, your terminal, anywhere.
- **Menu bar app** — runs quietly in your menu bar. No Dock icon, no windows.

## Install

```bash
git clone https://github.com/augmentedmike/whisper-hotkey.git
cd whisper-hotkey
make install
```

The binary is copied to `/usr/local/bin/whisper-hotkey`. Run it once and it auto-downloads the Whisper model (~142 MB) on first launch.

## Usage

| Action | Key |
|---|---|
| Start recording | `Ctrl+T` |
| Send (transcribe and type) | `Return` |
| Cancel | `Escape` |

That's it. Press `Ctrl+T`, say what you want to type, press `Return`. The transcribed text is typed into whatever app has focus.

## Requirements

- macOS 13+
- Microphone permission (macOS will prompt on first use)
- Accessibility permission (System Settings → Privacy & Security → Accessibility)
- Xcode Command Line Tools (`xcode-select --install`) for building from source

## Why?

Every other speech-to-text tool for Mac has a catch:

- **Whisper-based apps** charge a subscription or require an OpenAI API key.
- **macOS Dictation** is decent but sends audio to Apple's servers and has limited formatting control.
- **Cloud APIs** cost money per minute and your audio leaves your machine.

Whisper Hotkey is different. It's a single binary that runs a local Whisper model on your Mac's hardware. No network requests. No accounts. No cost. You own your audio.

## How It Works

1. A menu bar app registers a global hotkey (`Ctrl+T`)
2. When triggered, it records audio from your microphone
3. On `Return`, it transcribes audio locally using whisper.cpp
4. The result is pasted into the focused text field via simulated `Cmd+V`
5. Your clipboard is preserved — the original contents are restored after paste

The app auto-downloads the `ggml-base.en` model on first launch and stores it in `~/Library/Application Support/WhisperHotkey/`. For better accuracy (at the cost of speed), you can swap in a larger model from [Hugging Face](https://huggingface.co/ggerganov/whisper.cpp).

## Building

```bash
make build    # Build release binary
make run      # Build and run
make clean    # Clean build artifacts
make install  # Build and copy to /usr/local/bin
```

## License

[MIT](LICENSE)
