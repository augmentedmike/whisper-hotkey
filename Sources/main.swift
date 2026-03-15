import AppKit
import AVFoundation
import Carbon.HIToolbox
import SwiftWhisper

// MARK: - Audio Recorder

class AudioRecorder {
    private var audioEngine = AVAudioEngine()
    private var audioBuffer = [Float]()
    private let sampleRate: Double = 16000

    var isRecording: Bool { audioEngine.isRunning }

    func startRecording() throws {
        audioBuffer.removeAll()

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw NSError(domain: "WhisperHotkey", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * self.sampleRate / inputFormat.sampleRate
            )
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else { return }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if status == .error { return }

            if let channelData = convertedBuffer.floatChannelData {
                let frames = Array(UnsafeBufferPointer(start: channelData[0], count: Int(convertedBuffer.frameLength)))
                self.audioBuffer.append(contentsOf: frames)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() -> [Float] {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        return audioBuffer
    }

    func cancelRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioBuffer.removeAll()
    }
}

// MARK: - Whisper Transcriber

class Transcriber {
    private var whisper: Whisper?
    private let modelDir: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        modelDir = appSupport.appendingPathComponent("WhisperHotkey")
        try? FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
    }

    private var modelPath: URL {
        modelDir.appendingPathComponent("ggml-base.en.bin")
    }

    func ensureModel() async throws {
        if FileManager.default.fileExists(atPath: modelPath.path) {
            if whisper == nil {
                whisper = Whisper(fromFileURL: modelPath)
            }
            return
        }

        print("Downloading whisper model (base.en, ~142MB)...")
        let url = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin")!
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: tempURL, to: modelPath)
        print("Model downloaded to \(modelPath.path)")

        whisper = Whisper(fromFileURL: modelPath)
    }

    func transcribe(audioFrames: [Float]) async throws -> String {
        guard let whisper = whisper else {
            throw NSError(domain: "WhisperHotkey", code: 2, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }

        let segments = try await whisper.transcribe(audioFrames: audioFrames)
        return segments.map(\.text).joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Type into focused element

func typeText(_ text: String) {
    let pasteboard = NSPasteboard.general
    let oldContents = pasteboard.string(forType: .string)

    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)

    // Simulate Cmd+V to paste into focused element
    let source = CGEventSource(stateID: .hidSystemState)

    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(0x09), keyDown: true)
    keyDown?.flags = .maskCommand
    keyDown?.post(tap: .cghidEventTap)

    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(0x09), keyDown: false)
    keyUp?.flags = .maskCommand
    keyUp?.post(tap: .cghidEventTap)

    // Restore clipboard after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        if let old = oldContents {
            pasteboard.clearContents()
            pasteboard.setString(old, forType: .string)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let recorder = AudioRecorder()
    private let transcriber = Transcriber()
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        registerHotKey()

        Task {
            do {
                try await transcriber.ensureModel()
                print("Whisper model ready.")
            } catch {
                print("Failed to load model: \(error)")
            }
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Whisper Hotkey")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Whisper Hotkey", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let recordItem = NSMenuItem(title: "Talk (Ctrl+T)", action: #selector(startRecordingAction), keyEquivalent: "")
        recordItem.target = self
        menu.addItem(recordItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5748_4B59) // 'WHKY'
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            appDelegate.startRecordingAction()
            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        // Ctrl+T
        RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            UInt32(controlKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        print("Global hotkey registered: Ctrl+T (talk), Escape (cancel), Return (send)")
    }

    private func startKeyMonitor() {
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.recorder.isRecording else { return }

            if event.keyCode == UInt16(kVK_Escape) {
                // Escape — cancel recording, discard audio
                self.cancelRecording()
            } else if event.keyCode == UInt16(kVK_Return) {
                // Return — stop and transcribe
                self.stopAndTranscribe()
            }
        }
    }

    private func stopKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    @objc func startRecordingAction() {
        if recorder.isRecording {
            // Already recording — treat as send (same as Return)
            stopAndTranscribe()
            return
        }

        do {
            try recorder.startRecording()
            startKeyMonitor()
            if let button = statusItem.button {
                button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Recording... (Esc=cancel, Return=send)")
            }
            print("Recording... Press Return to send, Escape to cancel")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    private func cancelRecording() {
        recorder.cancelRecording()
        stopKeyMonitor()
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Whisper Hotkey")
        }
        print("Recording cancelled.")
    }

    private func stopAndTranscribe() {
        let audioFrames = recorder.stopRecording()
        stopKeyMonitor()
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.badge.ellipsis", accessibilityDescription: "Transcribing...")
        }
        print("Transcribing \(audioFrames.count) frames...")

        Task {
            do {
                let text = try await transcriber.transcribe(audioFrames: audioFrames)
                if !text.isEmpty {
                    print("Transcription: \(text)")
                    await MainActor.run {
                        typeText(text)
                        if let button = statusItem.button {
                            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Whisper Hotkey")
                        }
                    }
                } else {
                    print("No speech detected.")
                    await MainActor.run {
                        if let button = statusItem.button {
                            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Whisper Hotkey")
                        }
                    }
                }
            } catch {
                print("Transcription error: \(error)")
                await MainActor.run {
                    if let button = statusItem.button {
                        button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Whisper Hotkey")
                    }
                }
            }
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
