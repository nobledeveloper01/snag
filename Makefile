# Snag — the targets CI runs, so local and CI cannot disagree.
#
# iOS only, in Swift. No Docker target: Xcode does not run in a container, so
# the reproducible-build story is a pinned Xcode in the README and CI on macOS.

DOMAIN  := SnagDomain
PROJECT := Snag.xcodeproj
SCHEME  := Snag
DERIVED := .build/DerivedData

# The simulator to test on. A device named "Snag Tests" if one exists, so
# the tests never drive the simulator a person is looking at — the UI tests
# relaunch the app at the largest text size, and watching that happen on
# your own screen is alarming. Otherwise the first iPhone, which is what CI
# has. `xcrun simctl create "Snag Tests" "iPhone 17" <runtime>` to make one.
SIM ?= $(shell xcrun simctl list devices available 2>/dev/null | grep -m1 'Snag Tests' | grep -oE '[0-9A-F-]{36}')
ifeq ($(SIM),)
SIM := $(shell xcrun simctl list devices available 2>/dev/null | grep -m1 iPhone | grep -oE '[0-9A-F-]{36}')
endif
DEST := platform=iOS Simulator,id=$(SIM)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

# --- the gate ---------------------------------------------------------------

.PHONY: ci
ci: doc-check design-check counts-check copy-check l10n-check network-check splash-check verify-check analyze test coverage-gate ## Everything CI runs

.PHONY: gates
gates: doc-check design-check counts-check copy-check l10n-check network-check splash-check verify-check coverage-gate ## The blocking gates alone. These never go yellow.

.PHONY: doc-check
doc-check: ## Verify the documentation is present, well-formed and current
	@scripts/doc-check.sh

.PHONY: design-check
design-check: ## Fail if DESIGN.md disagrees with the tokens it documents
	@python3 scripts/design-check.py

.PHONY: counts-check
counts-check: ## Fail if a document quotes a figure the code does not produce
	@python3 scripts/counts-check.py

.PHONY: copy-check
copy-check: ## Fail if anything the app or the PDF says claims proof (ADR-0003)
	@python3 scripts/copy-check.py

.PHONY: network-check
network-check: ## Fail if the app has a network path
	@scripts/network-check.sh

.PHONY: splash-check
splash-check: ## Fail if the launch screen, icon or mark are not what the palette says
	@python3 scripts/splash-check.py

.PHONY: l10n-check
l10n-check: ## Fail if any language is missing a string the app has, or carries one it no longer has
	@python3 scripts/l10n-check.py

.PHONY: verify-check
verify-check: ## Fail if the Python verifier disagrees with the app's bundle, or fails to fire on a tampered one
	@bash scripts/verify-check.sh

.PHONY: brandmark
# Not run by `ci`, which checks rather than writes. `splash-check` fails if
# you forget to run this after a palette change.
brandmark: ## Redraw the icon and docs/mark.png from the palette
	@python3 scripts/brandmark.py

# No CODE_SIGNING_ALLOWED=NO here, unlike Tender: an unsigned app has no
# application identifier and the Keychain refuses it (-34018), and the
# sealing key lives in the Keychain. The simulator signs ad hoc by itself.

# --- code -------------------------------------------------------------------

.PHONY: setup
setup: ## Nothing to install: Xcode 26 and a simulator runtime
	@xcodebuild -version | head -1
	@xcrun simctl list runtimes | grep -m1 iOS || echo "\033[0;33m!\033[0m no iOS simulator runtime — install one from Xcode > Settings > Components"
	@python3 -c 'import PIL' 2>/dev/null || echo "\033[0;33m!\033[0m Pillow is needed by make brandmark:  python3 -m pip install --user Pillow"

.PHONY: analyze
# Warnings are errors in the project already (SWIFT_TREAT_WARNINGS_AS_ERRORS);
# this makes the package the same, then runs the purity lint so it cannot be
# skipped by running the analyzer alone.
analyze: ## Build the domain with warnings as errors, plus the domain-purity check
	cd $(DOMAIN) && swift build -Xswiftc -warnings-as-errors
	@$(MAKE) --no-print-directory domain-purity

.PHONY: domain-purity
domain-purity: ## Fail if the domain imports anything, or touches the clock or randomness
	@python3 scripts/domain-purity.py

.PHONY: test
# The domain first: seconds, no simulator. Then the app on the simulator,
# which is where the accessibility audit runs.
test: test-domain test-app ## Run the test suite

.PHONY: test-domain
test-domain: ## The domain package's tests, on macOS, in seconds
	cd $(DOMAIN) && swift test

.PHONY: test-app
test-app: ## The app's unit and UI tests on the simulator
	@[ -n "$(SIM)" ] || { echo "\033[0;33m!\033[0m no simulator found:  make test-app SIM=<udid>"; exit 64; }
	@# Built first, then the unit bundle, then the UI bundle. The unit bundle
	@# is hosted in the app, and one launch in three the host never reports
	@# to XCTest ("the test runner hung before establishing connection") —
	@# with or without a rebuild, a cold boot, or our scene delegate, each of
	@# which was blamed in turn. It is retried up to three times; the UI
	@# runner, a process of its own, has never hung. A hang is not a failed
	@# test: the retry starts from zero, and the summary counts the run that ran.
	@xcrun simctl boot $(SIM) >/dev/null 2>&1 || true; xcrun simctl bootstatus $(SIM) -b >/dev/null 2>&1 || true
	rm -rf $(DERIVED)/Logs/Test/*.xcresult
	xcodebuild build-for-testing -project $(PROJECT) -scheme $(SCHEME) -destination "$(DEST)" \
	  -derivedDataPath $(DERIVED) -quiet
	@rc=1; for attempt in 1 2 3; do \
	  rm -rf $(DERIVED)/Logs/Test/*.xcresult; \
	  xcodebuild test-without-building -project $(PROJECT) -scheme $(SCHEME) -destination "$(DEST)" \
	    -derivedDataPath $(DERIVED) -only-testing:SnagTests -quiet > $(DERIVED)/unit.log 2>&1; rc=$$?; \
	  if grep -q 'hung before establishing connection' $(DERIVED)/unit.log; then \
	    echo "\033[0;33m!\033[0m the unit-test host hung on attempt $$attempt; again"; xcrun simctl terminate $(SIM) ng.snag.app >/dev/null 2>&1; continue; fi; \
	  grep -vE 'IDELaunchParametersSnapshot|IDETestOperationsObserverDebug' $(DERIVED)/unit.log; break; done; \
	  [ $$rc -eq 0 ] && { xcodebuild test-without-building -project $(PROJECT) -scheme $(SCHEME) -destination "$(DEST)" \
	  -derivedDataPath $(DERIVED) -only-testing:SnagUITests -quiet; rc=$$?; }; \
	  xcrun simctl terminate $(SIM) ng.snag.app >/dev/null 2>&1; \
	  case "$$(xcrun simctl list devices | grep $(SIM))" in *"Snag Tests"*) xcrun simctl shutdown $(SIM) >/dev/null 2>&1;; esac; \
	  exit $$rc
	@python3 scripts/test-summary.py $(DERIVED)

.PHONY: build
build: ## Build the app for the simulator
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination "$(DEST)" \
	  -derivedDataPath $(DERIVED) -quiet

.PHONY: coverage
coverage: ## Domain coverage with the per-file breakdown
	cd $(DOMAIN) && swift test --enable-code-coverage >/dev/null
	@python3 scripts/coverage-report.py "$$(cd $(DOMAIN) && swift test --show-codecov-path)"

.PHONY: coverage-gate
coverage-gate: ## Fail if the domain drops below 95%
	cd $(DOMAIN) && swift test --enable-code-coverage >/dev/null
	@python3 scripts/coverage-report.py "$$(cd $(DOMAIN) && swift test --show-codecov-path)" --gate 95

.PHONY: device-check
# The half of Phase 3's gate a machine can reach. Skips on a simulator, by
# name; a skip is not a pass and R2 does not move on one.
#
#   make device-check D=<device id>     (xcrun xctrace list devices)
device-check: ## Run the on-device tests:  make device-check D=<device id>
	@if [ -z "$(D)" ]; then \
	  echo "\033[0;33m!\033[0m no device given. \`xcrun xctrace list devices\`, then: make device-check D=<id>"; \
	  exit 64; \
	fi
	@echo "\033[0;33m!\033[0m Have a room to measure for the first test, and a LiDAR phone for the second."
	@echo "  The phone asks for camera permission once."
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination "platform=iOS,id=$(D)" \
	  -only-testing:SnagUITests/DeviceTests -derivedDataPath $(DERIVED)

.PHONY: run
run: build ## Install and launch on the simulator
	xcrun simctl boot $(SIM) 2>/dev/null || true
	xcrun simctl install $(SIM) $(DERIVED)/Build/Products/Debug-iphonesimulator/Snag.app
	xcrun simctl launch $(SIM) ng.snag.app

# --- documentation ----------------------------------------------------------

.PHONY: screenshot screenshots
screenshots: ## Retake every README screenshot on the headless simulator
	@bash scripts/screenshots.sh

screenshot: ## Capture a booted simulator screen:  make screenshot N=02-camera
	@if [ -z "$(N)" ]; then \
	  echo "\033[0;33m!\033[0m no name given:  make screenshot N=02-camera"; \
	  ls docs/screenshots 2>/dev/null | sed 's/\.png$$//' | sed 's/^/    /'; \
	else \
	  SNAG_SIM=$(SIM) scripts/screenshot.sh "$(N)"; \
	fi

.PHONY: adr
adr: ## Scaffold the next ADR:  make adr T="the decision"
	@scripts/new-adr.sh "$(T)"

.PHONY: journal
journal: ## Add a session entry:  make journal T="what this session was about"
	@scripts/journal.sh "$(T)"

.PHONY: hooks
hooks: ## Install the git hooks
	@git config core.hooksPath .githooks
	@echo "\033[0;32m✓\033[0m hooks installed (core.hooksPath = .githooks)"

.PHONY: phase
phase: ## Print the current phase and its exit gate
	@p=$$(cat PHASE); \
	echo "Phase $$p"; \
	awk -v want="## Phase $$p" '$$0 ~ want {inside=1} /^## Phase/ && $$0 !~ want {inside=0} inside' docs/ROADMAP.md \
	  | grep -A6 '^\*\*Exit gate\*\*' || true
