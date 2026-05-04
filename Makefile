# LEVEL UP IRL — build/run shortcuts.
#
# Translates the gitignored .env file into Flutter's --dart-define
# flags so SupabaseConfig (and PhoneHasher) can read PROJECT_URL,
# PUBLISHABLE_KEY, and PHONE_HASH_SALT at compile time. .env is no
# longer bundled as an asset (P0-2), so this is the only way values
# reach the running app on dev machines.
#
# CI / production builds skip this Makefile and pass --dart-define
# values directly from the secret store.
#
# Usage:
#   make run               — local dev, sources .env
#   make run-prod          — local prod-config run (still --debug)
#   make run-release       — local release build
#   make build-apk         — release APK, prod flavor (Android)
#   make build-ipa         — release IPA (iOS, requires signing)
#   make test              — flutter test (no --dart-defines needed)
#   make analyze           — flutter analyze
#   make clean             — flutter clean + rm Pods + rm build/
#
# ─── iOS vs Android flavor handling ───────────────────────────────
# Android product flavors are wired in build.gradle.kts (dev / prod
# with applicationIdSuffix so both can install side-by-side).
# iOS flavors require Xcode schemes which must be created via the
# Xcode GUI — that work isn't done yet. So when targeting an iOS
# device we skip --flavor; Android targets keep it.
# Detection: iOS device IDs are 36-char UUIDs (8-4-4-4-12 hex with
# hyphens). Android device IDs are short alphanumeric (`emulator-5554`,
# physical-device serials, etc.).

# Read .env if it exists. Each KEY=VAL line becomes a -DKEY=VAL flag.
# `wildcard` returns empty if .env is missing → DART_DEFINES becomes
# empty → builds run in offline-only mode (gracefully).
ifneq (,$(wildcard .env))
  include .env
  export
  DART_DEFINES := \
    --dart-define=PROJECT_URL=$(PROJECT_URL) \
    --dart-define=PUBLISHABLE_KEY=$(PUBLISHABLE_KEY) \
    --dart-define=PHONE_HASH_SALT=$(PHONE_HASH_SALT)
else
  DART_DEFINES :=
endif

# Pass DEVICE=<id> to target a specific simulator/emulator/device.
# Example: make run DEVICE=F0A7DCBB-1891-41E2-8F89-7EE9142C87D7
DEVICE_FLAG := $(if $(DEVICE),-d $(DEVICE),)

# Detect iOS device by UUID format. If matched, IS_IOS=1 and we drop
# --flavor from run / run-prod / run-release.
IS_IOS := $(shell echo "$(DEVICE)" | grep -Eq '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$$' && echo 1)
FLAVOR_DEV  := $(if $(IS_IOS),,--flavor dev)
FLAVOR_PROD := $(if $(IS_IOS),,--flavor prod)

.PHONY: run run-prod run-release build-apk build-ipa test analyze clean help

# Default — `make` with no args prints help.
help:
	@echo "LEVEL UP IRL build targets:"
	@echo "  make run          — local dev run (.env values, dev flavor on Android)"
	@echo "  make run-prod     — debug run with prod flavor (Android only)"
	@echo "  make run-release  — local release build run"
	@echo "  make build-apk    — release APK (prod flavor)"
	@echo "  make build-ipa    — release IPA (iOS, no flavor — needs Xcode signing)"
	@echo "  make test         — flutter test"
	@echo "  make analyze      — flutter analyze"
	@echo "  make clean        — flutter clean + iOS Pods wipe"
	@echo ""
	@echo "Pass DEVICE=<id> to target a specific device:"
	@echo "  make run DEVICE=F0A7DCBB-1891-41E2-8F89-7EE9142C87D7   # iOS sim"
	@echo "  make run DEVICE=emulator-5554                            # Android emu"
	@echo ""
	@echo "iOS skips --flavor automatically until Xcode schemes are wired."

run:
	flutter run $(FLAVOR_DEV) $(DEVICE_FLAG) $(DART_DEFINES)

# Same backend wiring as `run`, but prod flavor on Android → prod
# bundle ID + "Level Up IRL" app label. iOS still ships as single
# target (no flavor flag passed). Useful for design QA on a build
# that matches the App Store target. Still --debug so hot-reload works.
run-prod:
	flutter run $(FLAVOR_PROD) $(DEVICE_FLAG) $(DART_DEFINES)

run-release:
	flutter run --release $(FLAVOR_PROD) $(DEVICE_FLAG) $(DART_DEFINES)

# Android release APK — flavor required. Always uses prod flavor.
build-apk:
	flutter build apk --release --flavor prod $(DART_DEFINES)

# iOS release IPA — no flavor (Xcode schemes not wired). Single
# target until we set up dev / prod schemes in Xcode.
build-ipa:
	flutter build ipa --release $(DART_DEFINES)

test:
	flutter test

analyze:
	flutter analyze

clean:
	flutter clean
	rm -rf ios/Pods ios/.symlinks ios/Podfile.lock
	rm -rf build/
