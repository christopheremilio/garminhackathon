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

.PHONY: all build run sim clean

all: build

# Compile for the target device. -w shows warnings, -l 3 = strict type checking
# (catches background-scope mistakes the default level misses).
build:
	@mkdir -p $(BUILD)
	$(MONKEYC) -f monkey.jungle -w -l 3 -o $(BUILD)/$(APP).prg -d $(DEVICE) -y "$(KEY)"

# Build, then load the app into a running simulator.
run: build
	$(MONKEYDO) $(BUILD)/$(APP).prg $(DEVICE)

# Launch the Connect IQ simulator (leave it running for `make run`).
sim:
	open "$(SDK)/bin/ConnectIQ.app"

clean:
	rm -rf $(BUILD)
