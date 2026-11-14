# HelloFenix

A first Connect IQ "watch app" for the **Garmin fēnix® 7 Pro**, written in Monkey C.

It tracks today's steps against a **10,000-step daily goal**:

- A progress ring around the edge fills clockwise (yellow, turning green at the goal).
- The center shows the step count, percent of goal, and steps remaining.
- The screen refreshes every 5 seconds while visible; START forces a refresh.

Steps come from `ActivityMonitor.getInfo().steps` (steps since local midnight).
`Sensor.SensorData` was considered but only exposes raw accelerometer, gyroscope,
heart-rate and magnetometer samples. It has no step count.

## Project layout

```
manifest.xml                    App id, type, target device, permissions
monkey.jungle                   Build config: where source/resources live
Makefile                        build / run / sim / clean helpers
source/
  HelloFenixApp.mc              AppBase subclass: lifecycle + initial view
  HelloFenixView.mc             WatchUi.View: reads steps, draws ring + text
  HelloFenixDelegate.mc         BehaviorDelegate: START = refresh
resources/
  strings/strings.xml           Localizable text (AppName, StepsLabel, ToGo, GoalReached)
  drawables/drawables.xml       Launcher icon declaration
  drawables/launcher_icon.svg   40x40 icon shown in the watch app list
bin/                            Build output (git-ignored)
```

## Build and run

With the Connect IQ simulator running:

```sh
make sim     # launch the simulator for the first time
make run     # compile and load into the simulator
```

Or compile only:

```sh
make build   # -> bin/HelloFenix.prg
```

Override defaults if needed:

```sh
make run SDK="/path/to/sdk" DEVICE=fenix7pro KEY="$HOME/Desktop/developer_key"
```

### In VS Code

The Monkey C extension picks up the SDK from
`~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg` and the signing key from
`monkeyC.developerKeyPath`. Open this folder as the workspace, then use:

- **Monkey C: Build Current Project**
- **Monkey C: Run Current Project**
- **Monkey C: Start Simulator**

## Install on the actual watch

1. Build with `make build`.
2. Plug the fēnix 7 Pro in via USB and open its `GARMIN` volume.
3. Copy `bin/HelloFenix.prg` into `GARMIN/APPS/`.
4. Unplug, then launch **HelloFenix** from the watch's app list.

Only apps signed with your developer key will run; `make build` already signs with
`~/developer_key`.

## Things worth knowing

- `manifest.xml` targets only `fenix7pro`. To support more devices add more
  `<iq:product id="..."/>` entries (in VS Code: *Monkey C: Edit Products*).
- `minApiLevel="3.1.0"` keeps the app compatible with older CIQ versions while
  still running on the fēnix 7 Pro (API 5.2).
- `id` is a unique app UUID. Generate a new one if you clone this project.
- The goal is the `STEP_GOAL` constant in `HelloFenixView.mc`. `ActivityMonitor.Info.stepGoal`
  holds the user's own goal from Garmin Connect, if you'd rather use that.

## Good next steps

- Add a **menu**: `resources/menus/menu.xml` + `WatchUi.Menu2` and override `onMenu()` in the delegate.
- Add **settings** with `Application.Properties` or a configurable app (`properties.xml`).
- Read **sensors** (heart rate, steps) via `Toybox.ActivityMonitor` — remember to add the
  matching `<iq:permission>`/`<iq:uses-permission>` entries in the manifest.
- Run in the simulator with logs attached: `monkeydo bin/HelloFenix.prg fenix7pro`.
