# Architecture: Whisper Hotkey

Whisper Hotkey is a lightweight, local-first macOS utility that runs offline speech-to-text directly from the menu bar. 

---

## Technical Design & Overview

```
 [Menu App/Hotkey Listen] ──▶ [Audio Recording (AVFoundation)] ──▶ [whisper.cpp (Local Inference)] ──▶ [Clipboard & Paste Hook (AppleScript)]
```

### 1. Global Hotkey Registration
* Registers a global hotkey system via CoreGraphics/Carbon APIs on macOS (`Ctrl+T`).
* Listens in the background while staying low-impact on system memory.

### 2. Audio Capture Subsystem
* Captures high-fidelity audio directly from default system microphones using native `AVFoundation` interfaces.
* Encodes captured audio into 16kHz WAV format (the target input expected by Whisper models).

### 3. Native Local Inference Engine
* Leverages [whisper.cpp](https://github.com/ggml-org/whisper.cpp) for highly optimized C/C++ audio transcription.
* Integrated into Swift using native C bindings via [SwiftWhisper](https://github.com/exPHAT/SwiftWhisper), optimizing inference speeds via Metal/Apple Silicon hardware acceleration.

### 4. Focused Window Integration
* On completion, writes transcribed text using `NSPasteboard`.
* Executes a simulated `Cmd+V` keystroke via macOS Accessibility APIs, typing directly into the active text field.
* Immediately restores the user's prior clipboard data to ensure zero disruption.
