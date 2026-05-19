# Contributing to Whisper Hotkey

Thank you for contributing to Whisper Hotkey! We welcome pull requests, bug reports, and suggestions to make this offline speech-to-text utility even better.

---

## Code Review Expectations
* **Performance Focus:** whisper-hotkey is optimized for swift, offline operation on macOS. Avoid introducing heavy external runtime dependencies.
* **Apple Silicon Optimization:** Ensure SwiftWhisper dependencies build correctly across both Intel and Apple Silicon Macs.
* **Security & Sandboxing:** Audio data must stay strictly offline. No network requests are permitted.

---

## Local Development Workflow

### 1. Build from Source
Ensure you have Xcode Command Line Tools installed (`xcode-select --install`).
```bash
make build
```

### 2. Testing Changes
Run the built application locally:
```bash
make run
```

### 3. Cleaning Build Artifacts
```bash
make clean
```
