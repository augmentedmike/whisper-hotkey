
.PHONY: build run clean install

build:
	swift build -c release

run:
	swift run

clean:
	swift package clean

install: build
	cp .build/release/WhisperHotkey /usr/local/bin/whisper-hotkey
	@echo "Installed to /usr/local/bin/whisper-hotkey"
