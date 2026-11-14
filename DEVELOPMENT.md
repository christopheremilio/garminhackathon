# Developing HelloFenix

Developer notes for the hamster water pet Connect IQ watch app (Garmin fēnix® 7 Pro,
Monkey C; listed on the watch as **Water Reminder**). For how to *use* the app, see
[README.md](README.md).

The long-term goal is a Tamagotchi-style habit tracker. Hydration is the first habit, so
shared pieces (pet mood, places, heart-rate context, reminders) are kept habit-agnostic
and habit-specific rules live in that habit's module.

**UI design source:** the "hamster-looks" looks-only prototype and its spec
(`2026-11-14-hamster-water-app-design.md`). Its hamster art, room, screens and colours are
ported here. We kept our own logic where the two overlapped; the decisions are listed
under [Design decisions](#design-decisions).

## Project layout

```
manifest.xml                    App id, type, target device, permissions
monkey.jungle                   Build config: where source/resources live
Makefile                        build / run / sim / clean helpers
source/
  HelloFenixApp.mc              AppBase: registers background check, handles notification taps
  HelloFenixView.mc             Main screen: Home room + Weekly page, reactions, rotating info line
  HelloFenixDelegate.mc         Buttons: START +250, UP/DOWN pages, hold UP menu
  Scenes.mc                     Room, bottle, water ring, text helpers, weekly + badges pages
  HamsterArt.mc                 Hamster drawing (ported design) + animations + wheel/stars
  Pet.mc                        (:background) mood from every habit's 0-100 score
  Prefs.mc                      (:background) hamster name, wake/bed times, waking-day fraction
  WaterLog.mc                   (:background) ml log, undo, history, streak, reminder timing, snooze
  Hydration.mc                  (:background) adaptive goal, exertion, place rules, pet score
  Reminders.mc                  (:background) "<name> is crying" wording, mood-drop detection
  Places.mc                     (:background) saved places + "where am I" matching
  WaterServiceDelegate.mc       (:background) temporal event -> arrival / mood-drop / interval notification
  Actions.mc                    Log water (picks sip/revive/goal reaction), undo, snooze, reset
  Screen.mc                     Page, "data changed" and "play a reaction" signals
  Menus.mc                      Hold-UP menu + Hamster / Places / Settings submenus, "Back to hamster"
  Onboarding.mc                 First-launch questions 2-3 (age, gender) + settings editors
  QuickAdd.mc                   Add water screen: 150/250/500 (5/8/16 oz), undo last, add to yesterday
  Rewards.mc                    Goal-day count, 12 accessories (1 per 3 goal days), 9 badges, what's worn
  Closet.mc                     Closet browser: preview all 12 (locked too), wear one hat + one other; swipe/tap
  Units.mc                      (:background) ml/oz display and preset amounts (storage is always ml)
  HamsterGlance.mc              (:glance) glance view: face + name + today's water, from a stored summary
  NamePrompt.mc                 First-launch question 1 (name) + keyboard (also used to rename)
  ReminderScreen.mc             In-app reminder: red ring, +250 / Snooze
  PlacesMenu.mc                 Place names, forget-places confirmation, GPS save screen
  DrinkAlert.mc                 Foreground-only chime + vibration
  Demo.mc                       Demo switch + fake inputs the rules read while it runs
  DemoTour.mc                   Scripted looping feature walkthrough + title cards
  Autopilot.mc                  Scripted input replay test (39 steps, PASS/FAIL to the log)
  Tests.mc                      Unit tests ((:test), run with make test)
resources/
  strings/strings.xml           Text (background-used strings are scope="background")
  drawables/drawables.xml       Launcher icon declaration
  drawables/launcher_icon.svg   Water-drop icon shown in the watch app list
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

`make build` uses strict type checking (`-l 3`). Keep it: it catches background-scope
mistakes that the default level lets through and that would crash on the watch.

### In VS Code

The Monkey C extension picks up the SDK from
`~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg` and the signing key from
`monkeyC.developerKeyPath`. Open this folder as the workspace, then use
**Monkey C: Build Current Project**, **Run Current Project**, **Start Simulator**.

### Testing in the simulator

**Demo tour, "A day with <name>" (`Demo.ENABLED`, currently ON; set `false` for normal
use):** every time the app opens it auto-plays a looping 15-step story: a title card
(time of day, headline, one-line pitch, progress dots), then the real app reacting.
Meet → 7:30 rise and sip → 9:00 oops (undo) → 12:00 thirsty → 12:30 drink now! (angry
stomp + buzzes) → 14:30 red alert → 16:00 fainted → 16:05 back! → 17:30 at the gym →
17:45 working hard (wheel) → 20:00 goal reached (party hat) → dress up → badges → your
week → "Keep <name> happy". The time of day, heart rate, place, night and rewards are
faked (`Demo.mc`), so it runs at any hour. **Any button stops it** and clears today's
water. First-launch questions are skipped while it runs. Each step logs `DEMO step n/15`.

### Automated tests

- **Unit tests** (`source/Tests.mc`, 14 tests): `make test` builds with `-t` and runs them
  in the simulator. They cover units, moods and deficit scoring, the log/undo, streaks,
  add-to-yesterday, rewards and badges, the reminder cap/snooze/countdown, mood-drop
  reminders, age/gender rules, prefs and places. They wipe the simulator app's storage.
- **Autopilot** (`source/Autopilot.mc`, 39 steps): set `Autopilot.ENABLED = true` and
  `make run`. It drives the real input handlers on a timer through first launch, quick
  add/undo, every menu path and "Back to hamster", the closet (swipe, tap, locked items,
  wearing), page cycling, the angry reminder + snooze and reset. It prints
  `AUTO PASS/FAIL` lines and `AUTO DONE passed=… failed=…`. It can't judge looks,
  animation or vibration.
- **Seeing app output:** `monkeydo` writes app output (`System.println`, crash stacks) to a
  terminal, not to a redirected file. To capture it, run under `script`:
  `sleep 3600 | script -q out.log "$SDK/bin/monkeydo" bin/HelloFenix.prg fenix7pro`.

- **Moods at any time of day:** mood depends on the clock and your wake/bed times. Change
  Wake/Bed time in the menu, or use the demo tour.
- **Activity bonus:** Simulation → Activity Monitoring, raise moderate/vigorous minutes.
- **Exertion:** play back a workout FIT file so there's high heart-rate history.
- **Background reminder:** Simulation → Background Events → trigger the temporal event.
- **Simulated GPS (`Places.FAKE_GPS = true`, currently ON):** the app pretends you're
  always at Platform Calgary. Saving a place stores those coordinates instantly ("Gym
  saved · Simulated GPS") and "where am I?" uses them. **Set it to `false` before
  installing on a real watch.**
- **Places / arrival demo:** Platform Calgary (51.0441750, -114.0553551) is pre-saved as
  **Work** on first run (`Places.PRESET_*`). Trigger the background temporal event and
  you should get "At work: Start with a glass of water."
- **Re-testing arrivals / start over:** hold UP → Reset today. This also clears the
  last-seen place, so the next background check counts as arriving again.
- **First-launch questions again:** delete the app's storage (or `Prefs.KEY_ONBOARDED`).
  They're skipped while the demo runs.

## How the rules work

### Water log (`WaterLog.mc`)

Today's total in ml plus a list of today's entries (for **Undo last**). Every change, and
every background check, writes `history[YYYYMMDD] = [ml, goalMl]`, keeping 35 days. The
goal is saved alongside because it changes with activity. **Add to yesterday** edits
yesterday's record. The **streak** counts consecutive met days back from yesterday, plus
today once it's met. The day resets at local midnight.

### Adaptive goal (`Hydration.mc`)

| Input | Source | Effect |
| ----- | ------ | ------ |
| Body weight | `UserProfile` | Base goal = 33 ml/kg, clamped 1.5–3.5 L |
| Gender (asked, or Garmin profile) | `Prefs.gender()` | No weight: 2.5 L male, 2.0 L female, 2.2 L otherwise |
| Age (asked, or Garmin birth year) | `Prefs.age()` | Under 14: goal capped at 1.7 L. 65+: reminder interval 45 min |
| Intensity minutes today | `ActivityMonitor.activeMinutesDay` | +10 ml per moderate min, +15 ml per vigorous min, capped at +1.5 L |
| Heart rate, last 30 min | `SensorHistory` + HR zones | ≥50% of samples in zone 3+ = "exerting": remind every 25 min, suggest 500 ml |

### The hamster's mood (`Pet.mc`, `Hydration.petScore`)

The design's pace model: **expected so far** = goal × share of the waking window (wake to
bed) that has passed, and **deficit** = expected − drunk. Hydration's score is
100 − 2 × deficit%. Pet maps the **lowest** habit score to a mood:

| Mood | Score | Deficit |
|---|---|---|
| Hydrated | all goals met | – |
| On track | ≥ 80 | < 10% |
| Thirsty | 50–79 | 10–25% |
| Last warning | 1–49 | 25–50% |
| Collapsed | 0 | ≥ 50% |
| Sleeping | outside wake/bed hours | – |

To add a habit to the pet, give it a `petScore()` and add it to the scores passed to
`Pet.moodFor()` (in `Pet.currentMood()` and the view).

### Reminders (`WaterServiceDelegate.mc`, `Reminders.mc`, `WaterLog.mc`)

The background check runs every 15 min. It posts at most one notification, in priority
order:

1. **Arrival** at a saved place (needs a fix under 15 min old; skipped if you drank in the
   last 15 min or the goal is met).
2. **Mood drop**: the mood got worse since the last check and is now thirsty or below.
3. **Interval**: the shortest of 60 min, exertion 25, Gym 20 and Work 45 since the last
   drink.

Nothing fires outside wake/bed hours or while snoozed (1 h). 2 and 3 share a cap: no more
often than every 30 min (or the interval, if shorter). Notifications carry **+250** and
**Snooze** actions; these are delivered to `HelloFenixApp.onNotification` the next time the
app runs, so a snooze tapped on a notification only takes effect then.

In the foreground, when a drink becomes due the view plays the chime (`DrinkAlert.mc`) and
pushes `ReminderView`. `Toybox.Attention` isn't available to background services, so
closed-app notifications use the watch's own alert.

### Places (`Places.mc`, rules in `Hydration.mc`)

Within 150 m of a saved place: Gym = every 20 min + suggest 500 ml, Work = every 45 min,
Home/Other = default. The app takes a fresh GPS fix when it opens (only if a place is
saved). Background services can't turn on GPS, so the background check uses the last
known fix only if it's under 15 min old.

### Screens and animation

- **Home** (`HelloFenixView.drawHome`): the room is themed by mood (green / red / grey /
  night). Line 1 is the name or mood title. Line 2 is the urgent message, else a rotation
  every 4 s of streak / next drink / place / exertion / activity bonus / goal met. Then come
  the bottle level, the water ring (`Scenes.waterRing`) and the amount text.
- **Reactions** (`Actions.logWater` picks one): sip (cheeks puff, hop, "+250"), tilt (undo),
  revive (first drink after collapsing: "<name> is back!"), and goal (party room, party hat,
  stars, streak).
- **Angry reminder** (`REACT_ANGRY`): when a drink becomes due in the foreground, the view
  pushes `ReminderView`. There the hamster stomp-jumps every `ANGRY_JUMP_MS` (500 ms) with
  furrowed brows, red cheeks, "!!" and ear steam, for 9 s. `DrinkAlert.angry()` plays the
  chime and a 120 ms buzz on every landing (6 buzzes), timed off the same constant.
- **First launch** (`Onboarding`): the name → age → gender screens replace each other
  (`switchToView`), BACK skips, and the last step sets `Prefs.onboarded()` and pops to the
  hamster. Age and gender default to the Garmin profile.
- **Menus** (`Menus.mc`): submenus `switchToView` over the main menu, so the stack is at most
  one menu deep. "Back to hamster" (every menu) and BACK in the main menu pop to the
  hamster, and BACK in a submenu rebuilds the main menu. Quick-add, the closet and saving a
  place replace the menu, so finishing them lands on the hamster.
- **Closet input:** UP/DOWN or swipe left/right browse, a tap on the left/right thirds
  browses, a tap in the middle or START wears. On the Closet page, START / tap / swipe
  left-right open it.
- **Weekly** (`Scenes.weekly`): 7 bars from history.
- **Closet** page (`drawClosetPage`) and browser (`Closet.mc`); **Badges** page
  (`Scenes.badgesPage`). Pages cycle Home → Weekly → Closet → Badges.

### Rewards (`Rewards.mc`)

`Rewards.checkDay(day)` is called after every drink (including notification "+250" and
add-to-yesterday). The first time a day reaches its goal it is counted once (tracked in
`countedDays`), `goalDays` goes up, badges are re-evaluated (streak 3/7/30/100, total
10/50/100, first day, and a perfect Mon–Sun week checked on Sundays), and every 3rd goal
day unlocks the next accessory. A new accessory is auto-worn if its slot is empty, and it
is returned so the goal party shows "New: …". `goalDays` and the badge bits are stored
separately from the 35-day history, so they never expire. Nothing counts while the demo
runs.

### Glance (`HamsterGlance.mc`)

Glances run in their own memory-limited process, where only `(:glance)` code is loaded.
`WaterLog.saveGlance()` (called from `recordToday`) stores
`[day, "1.2 / 2.0 L", "0.0 / 2.0 L", fill%, name, mood]`, and the glance only reads that.
Because `AppBase.onStart` also runs in the glance and background processes, foreground
setup (background registration, place preset) lives in `getInitialView()`.
- `HamsterArt.draw()` computes the pose from `System.getTimer()`, so motion is frame-rate
  independent. `framePeriod()` picks the redraw rate: 1 fps collapsed, 2 asleep, 4 idle,
  8 in the wheel, 12 during hops and reactions. The view caches its numbers and
  recalculates them every 30 s or on `Screen.changed()`. After changing data anywhere, call
  `Screen.changed()` / `Screen.react(...)` (or an `Actions` function) instead of
  `WatchUi.requestUpdate()`.
- Screens (name prompt, reminder) are pushed from the view's timer callback, not from
  `onUpdate`.

## Design decisions

Where the design and our existing app overlapped, we chose:

1. The design's 5 moods (deficit-based), **plus Sleeping** overnight.
2. START adds 250 ml instantly. Other amounts, undo and add-to-yesterday are on the
   quick-add screen (menu → Add water). Litres everywhere.
3. UP/DOWN switch pages. Undo/reset/places live in the menu and quick-add screen.
4. ~~The design's water bar~~ → **our segmented ring** around the edge (one segment per
   250 ml / 8 oz, 7 o'clock to 5 o'clock, green at the goal), plus the design's bottle.
   Changed at the user's request after seeing the demo.
5. Line 2 rotates (urgent first).
6. Reminders are ours (interval, exertion, place, arrival) plus the design's mood-drop
   reminders, snooze and name-based wording, with a combined cap.
7. Our automatic goal (weight + activity), not manual entry. Phone settings only work for
   store-installed apps anyway.
8. Wake/bed times (default 7:00 / 22:00), adjustable in the menu. The day still resets at
   midnight.
9. Our working demo tour, restyled.
10. Kept habit-agnostic (the design scoped water only).

**After the demo (user requests):** the segmented ring replaced the water bar; menus split
into submenus with "Back to hamster"; three first-launch questions (name, age, gender);
the angry jumping reminder with buzzes; the design's blue water-drop tuft was removed; the
closet previews locked items and supports swipe/tap.

**Second pass (built):** closet with 12 accessories (8 new drawings in the design's style
alongside the design's party hat, glasses, crown and bow), badges, glance, ml/oz units.

## Things worth knowing

- `manifest.xml` targets only `fenix7pro`. Add `<iq:product id="..."/>` entries for more
  devices (in VS Code: *Monkey C: Edit Products*). Layout is fixed for 260×260.
- `minApiLevel="5.1.0"` is required by `Toybox.Notifications`. Permissions: `Background`,
  `Notifications`, `SensorHistory`, `UserProfile`, `Positioning`.
- Anything the background service touches must be marked for it: `(:background)` on code,
  `scope="background"` on strings.
- All art uses the fēnix 7 Pro's 64 colours (channels 00/55/AA/FF).
- `id` in the manifest is a unique app UUID. Generate a new one if you clone this project.
