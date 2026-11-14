# HelloFenix

A first Connect IQ "watch app" for the **Garmin fēnix® 7 Pro**, written in Monkey C.

It's a **water drinking reminder**: log glasses through the day toward a goal of
8 glasses (8 × 250 ml = 2 L), and get a watch notification when it's time to drink.

| Button | Action |
| ------ | ------ |
| START  | +1 glass |
| DOWN   | undo last glass |
| BACK   | exit (reminders keep running) |

- A segmented ring fills one segment per glass (blue, turning green at the goal).
- The center shows glasses, millilitres, and "Next drink in N min" / "Time to drink!".
- **Reminders while the app is closed:** a background service checks every 15 min and
  posts a notification ("Drink water", with a **+1 glass** action) when:
  - 60 min have passed since your last glass,
  - you're under today's goal,
  - it's not quiet hours (21:00–08:00), and
  - you weren't already reminded in the last 30 min.
- Tapping **+1 glass** on the notification logs a glass (applied the next time the app runs).
- If a drink becomes due while the app is open, the watch vibrates once.
- The count resets at local midnight. State lives in `Application.Storage`.

All the tunables (goal, glass size, interval, quiet hours, check period) are
constants at the top of `source/WaterLog.mc`.

## Project layout

```
manifest.xml                    App id, type, target device, permissions
monkey.jungle                   Build config: where source/resources live
Makefile                        build / run / sim / clean helpers
source/
  HelloFenixApp.mc              AppBase: registers background check, handles notification taps
  HelloFenixView.mc             WatchUi.View: ring, counts, next-drink status
  HelloFenixDelegate.mc         BehaviorDelegate: START +1, DOWN undo
  WaterLog.mc                   (:background) shared state + reminder rules + settings
  WaterServiceDelegate.mc       (:background) temporal event -> posts the notification
resources/
  strings/strings.xml           Localizable text (notification strings are scope="background")
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
- `minApiLevel="5.1.0"` is required by `Toybox.Notifications`. The manifest requests the
  `Background` and `Notifications` permissions.
- Anything the background service touches (code *and* strings) must be marked for the
  background: `(:background)` on code, `scope="background"` on strings. `make build`
  uses strict type checking (`-l 3`) so mistakes here fail the build instead of crashing
  on the watch.
- `id` is a unique app UUID. Generate a new one if you clone this project.

## Good next steps

- Add a **menu**: `resources/menus/menu.xml` + `WatchUi.Menu2` and override `onMenu()` in the delegate.
- Add **settings** with `Application.Properties` or a configurable app (`properties.xml`).
- Read **sensors** (heart rate, steps) via `Toybox.ActivityMonitor` — remember to add the
  matching `<iq:permission>`/`<iq:uses-permission>` entries in the manifest.
- Run in the simulator with logs attached: `monkeydo bin/HelloFenix.prg fenix7pro`.
