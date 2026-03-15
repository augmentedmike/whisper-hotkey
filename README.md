# Whisper Hotkey

Local speech-to-text with a global hotkey. Free, offline, powered by [whisper.cpp](https://github.com/ggml-org/whisper.cpp).

Press **Cmd+Shift+Space** to start recording. Press again to stop. The transcribed text is pasted into the active app.

## Features

- Menu bar app (no dock icon)
- Global hotkey: Cmd+Shift+Space
- Completely local and offline (no API keys, no cloud)
- Uses whisper.cpp via [SwiftWhisper](https://github.com/exPHAT/SwiftWhisper)
- Auto-downloads the `base.en` model (~142MB) on first run

## Requirements

- macOS 13+
- Xcode Command Line Tools (`xcode-select --install`)
- Microphone permission
- Accessibility permission (for simulating paste)

## Install

```bash
git clone https://github.com/augmentedmike/whisper-hotkey.git
cd whisper-hotkey
make build
make install  # copies to /usr/local/bin
```

Or just run directly:

```bash
make run
```

## Permissions

On first run you'll need to grant:

1. **Microphone access** — macOS will prompt automatically
2. **Accessibility access** — Go to System Settings > Privacy & Security > Accessibility, and add the app (or Terminal if running from terminal)

## How It Works

1. Press Cmd+Shift+Space to start recording
2. Speak
3. Press Cmd+Shift+Space again to stop
4. Audio is transcribed locally via whisper.cpp
5. Result is placed on the clipboard and pasted (Cmd+V) into the active app

## Model

The app uses the `ggml-base.en` model (~142MB). It's downloaded automatically on first launch and stored in `~/Library/Application Support/WhisperHotkey/`.

For better accuracy at the cost of speed, you can manually replace it with a larger model from [Hugging Face](https://huggingface.co/ggerganov/whisper.cpp).
