# Connect IQ build helpers for macOS.
# Override on the command line if your paths differ, e.g.:
#   make run SDK="/path/to/connectiq-sdk" KEY="$HOME/Desktop/developer_key"

SDK    ?= $(HOME)/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b
DEVICE ?= fenix7pro
KEY    ?= $(HOME)/developer_key

APP    := HelloFenix
BUILD  := bin

MONKEYC  := "$(SDK)/bin/monkeyc"
MONKEYDO := "$(SDK)/bin/monkeydo"

.PHONY: all build run sim demo test autopilot clean

all: build

# Compile for the target device. -w shows warnings, -l 3 = strict type checking
# (catches background-scope mistakes the default level misses).
build:
	@mkdir -p $(BUILD)
	$(MONKEYC) -f monkey.jungle -w -l 3 -o $(BUILD)/$(APP).prg -d $(DEVICE) -y "$(KEY)"

# Build, then load the app into a running simulator.
run: build
	$(MONKEYDO) $(BUILD)/$(APP).prg $(DEVICE)

# One step: open the simulator if it isn't running, build, and load the app.
# With Demo.ENABLED = true (as committed) the demo plays straight away.
demo: build
	@pgrep -f "ConnectIQ.app/Contents/MacOS/simulator" >/dev/null || (open "$(SDK)/bin/ConnectIQ.app" && sleep 10)
	$(MONKEYDO) $(BUILD)/$(APP).prg $(DEVICE)

# Unit tests (source/Tests.mc): build with -t and run in the simulator.
# Results print here. Running them wipes the simulator app's storage.
test:
	@mkdir -p $(BUILD)
	$(MONKEYC) -f monkey.jungle -w -l 3 -t -o $(BUILD)/$(APP)-test.prg -d $(DEVICE) -y "$(KEY)"
	$(MONKEYDO) $(BUILD)/$(APP)-test.prg $(DEVICE) -t

# Scripted UI test (source/Autopilot.mc): a separate build with the autopilot
# switched on. Prints AUTO PASS/FAIL lines. Wipes the simulator app's storage.
autopilot:
	@mkdir -p $(BUILD)
	$(MONKEYC) -f "monkey.jungle;autopilot.jungle" -w -l 3 -o $(BUILD)/$(APP)-autopilot.prg -d $(DEVICE) -y "$(KEY)"
	@pgrep -f "ConnectIQ.app/Contents/MacOS/simulator" >/dev/null || (open "$(SDK)/bin/ConnectIQ.app" && sleep 10)
	$(MONKEYDO) $(BUILD)/$(APP)-autopilot.prg $(DEVICE)

# Launch the Connect IQ simulator (leave it running for `make run`).
sim:
	open "$(SDK)/bin/ConnectIQ.app"

clean:
	rm -rf $(BUILD)
