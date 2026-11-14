# Hydro Habit

A little hamster lives on your watch, and it needs you to drink water. Keep up with your
daily goal and it stays happy and bouncy. Fall behind and it gets thirsty, starts crying,
and eventually faints. One drink always brings it back.

Your goal is based on your body weight and grows when you're active. Reminders come more
often when you're working hard or at the gym. Meeting your goal day after day builds a
streak, earns badges, and unlocks accessories to dress your hamster in.

The app is called **Hydro Habit**. Coco is the hamster (you can rename it).

> This app gives general guidance only. It isn't medical advice. If you have a health
> condition that affects how much you should drink, follow your doctor's advice.

---

## Install

The app isn't in the Connect IQ Store yet. To put it on your watch:

1. Get the `HelloFenix.prg` file from whoever built it for you (developers: see
   [DEVELOPMENT.md](DEVELOPMENT.md)).
2. Connect your fēnix 7 Pro to your computer with its USB cable.
3. Open the **GARMIN** drive that appears and copy `HelloFenix.prg` into the
   **GARMIN/APPS** folder.
4. Eject the watch and unplug it.
5. On the watch, press **START** from the watch face, scroll to **Hydro Habit**, and
   press **START** to open it.

The first time you open it, the watch may ask you to allow access to notifications,
background updates, heart rate history, your user profile and GPS. Allow them all; the
app needs each one for the features below.

## First launch: four quick questions

1. **Name your hamster.** Scroll the list of names (Coco, Mizu, Peanut, Mochi, Biscuit,
   Nibbles, Pip, Hazel, Waffles, Bubbles) and press **START** on one. Or choose **Type my
   own...** to enter any name up to 10 letters on the watch keyboard. **BACK** keeps
   **Coco**.
2. **How old are you?** **UP/DOWN** changes the number and **START** confirms.
3. **You are:** Female, Male, Other, or Prefer not to say.
4. **Your weight?** **UP/DOWN** changes it in kg and **START** confirms. Your daily goal is
   based on it (about 33 ml per kg, rounded up to whole glasses).

Age, gender and weight start from your Garmin profile if it has them, so usually you just confirm.
**BACK** skips any question. You can change them all later: rename from the **Hamster**
menu (same list, or type your own), and age, gender and weight from **Settings**.

**What they're used for:**
- Your **weight** sets your goal (your answer, or the Garmin Connect profile).
- Without a weight, **gender** sets the starting goal: 10 glasses male, 8 female, 9
  otherwise.
- **Under 14**, the goal is capped at about 7 glasses.
- **65 and over**, reminders come every 45 minutes instead of 60, because thirst fades
  with age.

## Set up (2 minutes, optional but recommended)

- **Set your wake and bed times:** hold UP → **Settings** → **Wake time** / **Bed time**
  (press to step through the hours). They default to 7:00 and 22:00. Your hamster sleeps, and reminders
  pause, outside these hours.
- **Check your weight** (asked at setup, or under **Settings** → **Weight**). Your daily goal
  is based on it.
- **Check your heart rate zones** in Garmin Connect. The app uses them to tell when you're
  working hard.
- **Turn on watch tones** in the watch's system sound settings if you want to hear the bell
  when it's time to drink.
- **Save your places** (Home, Gym, Work) so reminders fit where you are. See
  [Places](#places).

---

## Your hamster

How it looks depends on how far behind you are, for the time of day. By mid-afternoon,
for example, you should be past halfway to your goal.

| Hamster | Room | Top line | When |
|---|---|---|---|
| Happy closed eyes, big puffy cheeks, sparkles | Green | *its name* | You've reached today's goal |
| Dot eyes, small smile, hops now and then | Green | *its name* | On track (less than 10% behind) |
| Wide eyes, tongue out, sweat drop | Green | **Coco is thirsty** | 10–25% behind |
| Crying, pointing a toy water pistol at you | **Red** | **Coco is crying!** | 25–50% behind |
| Lying on the floor, crossed eyes, tipped-over cup | **Grey** | **Coco collapsed** | More than 50% behind |
| Eyes closed, "z"s floating up | Night | **Coco is asleep** | Outside your wake/bed hours |

*(The hamster's own name is used; "Coco" is just an example.)*

- **Its cheeks grow** as you drink more during the day.
- **It's alive:** it breathes and blinks. Press START and it puffs its cheeks and hops
  ("+250" floats up). Undo a drink and it wobbles its head, confused. When you're working
  hard, it runs in its **hamster wheel**.
- **It never dies.** If it collapses, your next drink plays a revive: **"Coco is back!"**.
- **Reaching your goal** throws a party: purple room, party hat, stars, and your streak.

## The screens

**Home** (the hamster's room):

```
        Coco                  <- name, or "Coco is thirsty" etc.
    12 day streak             <- rotating info line (see below)
 [window]  (hamster)  [bottle]
    3 / 9 glasses             <- glasses so far / today's goal
```

- The **ring** around the edge tracks today's water. It has one segment per glass of your goal and fills clockwise from 7 o'clock. The segment you're on fills partway, and
  the whole ring turns **green** when you reach your goal.
- The **bottle** in the room fills up too, and the dots in the gap at the bottom show which
  page you're on.
- The **second line** shows what matters most right now: **Drink now** or **Drink to
  revive** when it's urgent. Otherwise it rotates every few seconds between your
  **streak**, **Next drink in 42 min**, **At Gym**, **Working hard!**, **+2 glasses for
  activity** and **Goal met!**, whichever apply.

Press **UP/DOWN** to move between the four pages: **Home → Weekly → Closet → Badges**.

**Weekly:** the last 7 days as bars, with today on the right.

- **Blue** means you met the goal that day, **red** means you missed it, dark blue is today
  so far, and a grey stub means no data.
- At the top is **"5 of 7 days"**, and at the bottom your average.

**Closet:** your hamster in what it's wearing. Press **START** to dress it up (see
[Closet](#closet-and-accessories)).

**Badges:** your trophy shelf. Earned badges are gold and locked ones are grey (see
[Badges](#badges)).

## Buttons

| Button | What it does |
|---|---|
| **START** | Add **1 glass** of water. On the Closet page: open the closet (or tap / swipe left-right) |
| **UP / DOWN** | Switch page: Home, Weekly, Closet, Badges |
| **Hold UP** | Menu (see below) |
| **BACK** | Close the app. Reminders keep working |

### The menu (hold UP)

```
Menu
  Add water           1/2, 1 or 2 glasses, Undo last
  Hamster        >    Rename hamster, Dress up
  Places         >    Save as Home / Gym / Work / Other, Forget places
  Settings       >    Wake time, Bed time, Age, Gender, Weight
  Reset today
  Back to hamster
```

**Getting back:** every menu and submenu ends with **Back to hamster**, which takes you
straight back to your hamster.

- **BACK** in a submenu returns to the main menu, and **BACK** in the main menu returns to
  your hamster.
- Adding water, dressing up and saving a place also finish on the hamster.

**On the Add water screen:** UP/DOWN moves the highlight, START picks, and BACK closes.

---

## Reminders

**While the app is open:** when a drink is due, your hamster **jumps up and down in anger**
(furrowed brows, steam from its ears, "!!"). A bell rings and the watch **buzzes on every jump**.
Press **+250** (START) or **Snooze** (DOWN); BACK just closes it.

**While the app is closed:** about every 15 minutes the watch checks, and you may get a
notification with **+250** and **Snooze** buttons:

| Why | Example |
|---|---|
| You **arrived** at a saved place | *At the gym*: Drink 2 glasses before you start. |
| Your hamster got **worse** | *Coco is crying*: Drink now |
| It's been **about an hour** since your last drink | *Coco wants a drink*: 3 / 9 glasses so far today |

- **Rules:** no reminders outside your wake/bed hours, after you've hit your goal, or while
  snoozed. Arrival reminders aside, you won't get them more often than every 30 minutes.
- **Interval:** about an hour normally, every 25 minutes when you're working hard, 20 at
  the gym, and 45 at work.
- **Snooze** silences reminders for 1 hour.
- **Notification buttons:** **+250** and **Snooze** pressed on a notification take effect
  the next time you open the app. +250 is logged at the time the reminder arrived.
- **Sounds:** a single bell ring, only while the app is open. Notifications use your watch's
  normal notification alert.

---

## How your goal is set

| What | How it affects your goal |
|---|---|
| **Your weight** | About 33 ml per kg, rounded up to whole glasses (70 kg means about 10 glasses). Between 6 and 14 glasses. |
| **Steps** | +1 glass for every 5,000 steps beyond your first 5,000 (10,000 steps = +1, 15,000 = +2, 20,000+ = +3). |
| **Heart rate** (intensity minutes) | Garmin measures intensity minutes from your heart rate: about 1 extra glass per 25 moderate or 17 vigorous minutes. Steps and heart rate together add at most 6 glasses a day. |
| **Hot weather** | When it feels 25 °C or hotter (using the weather your phone sends to the watch): +1 glass. At 30 °C or hotter: +2 glasses. No weather data, no change. |

Your goal can grow during the day as you move. It never goes down during the day.

## Steps

The home screen shows **how many steps you've done today** ("6,214 steps today"). The app
doesn't push you to walk more. Steps just raise your water goal, because walking all day
means you need more water (see [How your goal is set](#how-your-goal-is-set)).

## After a workout

When you finish a workout you recorded on the watch, Coco sends a notification straight
away: **"Great workout! Drink 2 glasses to recover."** For the next hour the home screen
shows **Post-workout: drink 2 glasses**.

## When you're working hard

If your heart rate has mostly been in **zone 3 or higher** for the last 30 minutes:

- reminders come every **25 minutes** and suggest **2 glasses**,
- your hamster runs in its **wheel**, and the info line says **Working hard!**.

## Streaks

Your **streak** is the number of days in a row you've met your goal. Today counts as soon as
you reach it. Miss a day and the streak starts again from zero. The weekly page shows how
the last 7 days went.

## If you stop drinking for days: Coco walks out

Miss your water goal **more than 3 days in a row** and Coco gets fed up. The next time you
open the app, Coco **walks off the screen**, leaving paw prints and an empty room: **"Coco
left. Drink to bring Coco back."** If the app is closed you'll get a notification instead.

Your **next drink** brings Coco **walking back in**, and a new streak starts. Coco never
leaves for good, and it doesn't count days before you started using the app.

## Closet and accessories

Every **3 days you meet your goal** (they don't have to be in a row), your hamster gets a
new accessory, up to 12. The goal party announces it ("New: Crown") and the hamster puts it
on if it isn't already wearing something in that spot.

| Unlocks at | Item | Worn as |
|---|---|---|
| 3 goal days | Party hat | Hat |
| 6 | Bow | Other |
| 9 | Round glasses | Other |
| 12 | Scarf | Other |
| 15 | Crown | Hat |
| 18 | Flower | Hat |
| 21 | Sunglasses | Other |
| 24 | Sweatband | Hat |
| 27 | Bow tie | Other |
| 30 | Cap | Hat |
| 33 | Plant (sits in its room) | Other |
| 36 | Medal | Other |

Your hamster wears **one hat and one other item** at a time. To open the closet, go to the
**Closet** page and press **START**, tap the screen, or swipe left/right. You can also get
there from the menu: **Hamster** → **Dress up**.

- **Browse all 12 items:** UP/DOWN, swipe left/right, or tap the **<** **>** arrows.
- **Put it on or take it off:** START, or tap the middle.
- **Close:** BACK.

Every item is previewed on your hamster, **including the ones you haven't unlocked yet**.
Those are tagged **Locked** with how many goal days to go ("6 goal days to go"), so you can
see what's coming.

## Badges

| Badge | How to earn it |
|---|---|
| **1** | Your first goal day |
| **3 / 7 / 30 / 100** | A 3-, 7-, 30- or 100-day streak |
| **Wk** | A perfect week: every day Monday to Sunday |
| **x10 / x50 / x100** | 10, 50 or 100 goal days in total |

Badges and accessories stay with you even if you break a streak.

## Glance

Add the app to your watch's **glances** (the list you scroll through from the watch face)
to see your hamster's face, its name, today's water and a progress bar without opening the
app. It updates whenever you log water and about every 15 minutes.

## Glasses, not units

Everything is counted in **glasses of water**, so there's nothing to convert. One glass is
a normal cup (about 250 ml / 8 oz). START adds a glass, and the Add water screen also offers
half a glass and two glasses.

## Places

Save the places you spend time at and the reminders adjust when you're there.

### Save a place

1. Stand at the place, outdoors if you can, since GPS works best under open sky. For a
   gym, the parking lot is fine.
2. Hold **UP** and choose **Save as Home**, **Save as Gym**, **Save as Work** or
   **Save as Other**.
3. Wait while the watch says **Getting GPS…**. You'll see **Gym saved · GPS good**.

Saving the same place again replaces it. Press **BACK** while it's getting GPS to cancel.
If it can't get a fix within a minute it shows **No GPS fix**; try again outdoors.

### What each place does

| Place | Reminders | Arriving there |
|---|---|---|
| **Gym** | Every **20 minutes**, suggesting **2 glasses** | *At the gym*: Drink 2 glasses before you start. |
| **Work** | Every **45 minutes** | *At work*: Start with a glass of water. |
| **Home** | Normal | *Welcome home*: Time for a glass of water. |
| **Other** | Normal | *You've arrived*: Grab a glass of water. |

You count as "at" a place within about 150 m (500 ft) of where you saved it. The info line
then shows **At Gym** (etc.). There's no arrival reminder if you drank in the last 15
minutes. Saving a place while you're standing there doesn't count as arriving.

### How the watch knows where you are

- **When you open the app,** it takes a quick GPS reading.
- **When the app is closed,** the watch can't turn on GPS for it. It uses your last known
  location only if it's from the last 15 minutes, for example while you're recording a GPS
  activity, so arrival reminders may be missed or late.

Even when the watch can't tell you're at the gym, a hard workout still raises your heart
rate, so the [working hard](#when-youre-working-hard) reminders still kick in.

---

## Watch sensors and data used

| Sensor / data | What the app uses it for |
|---|---|
| **Heart rate** (recent history) | Spotting when you're working hard (mostly zone 3 or higher for 30 min): more frequent reminders and the hamster wheel |
| **Activity tracking:** steps | Your step count, and extra water for busy days |
| **Activity tracking:** intensity minutes (from heart rate) | Extra water on active days |
| **Recorded workouts** | The post-workout nudge when a workout ends |
| **GPS** | Saving places, and knowing when you're at the gym, home or work |
| **Weather** (from your phone) | Extra water on hot days ("feels like" temperature) |
| **User profile:** weight, birth year, gender, heart rate zones | Your daily goal, first-launch answers, and the heart rate threshold |
| **Clock** | Pace through the day, wake/bed hours, streaks |
| **Vibration motor and speaker** | Buzzes and the bell ring for reminders |
| **Touchscreen and buttons** | Everything you tap and press |

**Permissions the app asks for:** Notifications, Background (reminders while it's
closed), Heart rate history (`SensorHistory`), User profile, and GPS (`Positioning`).
Everything stays on your watch. Nothing is uploaded.

**Not used:** pulse ox, barometer, compass, body battery, stress and sleep data.

## Resetting

- **Every night at midnight** today's water starts again at 0. Your streak and history are
  kept.
- **To start today over,** hold UP → **Reset today** → **Yes**. This clears today's water
  and reminder timer. Your name, places, earlier days, badges and accessories are kept.

---

## Troubleshooting

| Problem | Try this |
|---|---|
| Coco walked out | You missed your water goal more than 3 days in a row. Drink a glass and Coco walks back in. |
| I'm not getting reminders | Check it's within your wake/bed hours, you haven't reached your goal, and you haven't snoozed. Make sure notifications are allowed for the app and your watch isn't in Do Not Disturb or Sleep mode. |
| My hamster is always asleep | Check **Wake time** and **Bed time** under **Settings** in the menu. |
| It collapsed even though I drank | The mood is based on how much you've had *for the time of day*. Drink a bit more and it recovers. |
| I don't hear the bell | The bell only rings while the app is open. Make sure tones are on in the watch's system sound settings. |
| I tapped **+250** or **Snooze** on a notification and nothing changed | Notification buttons take effect the next time you open the app. |
| My goal seems too high or too low | Check your weight in Garmin Connect and sync. |
| It never says "At Gym" | Re-save the place outdoors, and open the app when you arrive. |
| **No GPS fix** when saving | Go outside or near a window and try again. |
| I logged too much | Hold UP → **Add water** → **Undo last**. |
