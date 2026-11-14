import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

// Unit tests for the app's rules. Compiled only with `make test`
// (monkeyc -t) and run in the simulator (monkeydo -t); results print to the
// terminal. Each test starts from empty storage, so running them wipes the
// simulator app's data.

function tReset() as Void {
    Storage.clearValues();
    Demo.active = false;
    Demo.resetInputs();
}

// Log a check; returns the condition so tests can AND them together.
function tCheck(logger as Logger, name as String, ok as Boolean) as Boolean {
    logger.debug((ok ? "ok   " : "FAIL ") + name);
    return ok;
}

// ---------------------------------------------------------------------------

(:test)
function testUnits(logger as Logger) as Boolean {
    tReset();
    var ok = tCheck(logger, "ml default", !Units.isOz());
    ok = tCheck(logger, "total 1200 ml = 1.2 L", Units.total(1200).equals("1.2 L")) && ok;
    ok = tCheck(logger, "pair", Units.pair(1200, 2000).equals("1.2 / 2.0 L")) && ok;
    ok = tCheck(logger, "default add 250 ml", Units.defaultAddMl() == 250) && ok;
    Units.toggle();
    ok = tCheck(logger, "toggle to oz", Units.isOz()) && ok;
    ok = tCheck(logger, "8 oz = 237 ml", Units.ozToMl(8) == 237) && ok;
    ok = tCheck(logger, "237 ml = 8 oz", Units.mlToOz(237) == 8) && ok;
    ok = tCheck(logger, "default add 8 oz", Units.defaultAddMl() == 237) && ok;
    ok = tCheck(logger, "amount text oz", Units.amount(237).equals("8 oz")) && ok;
    ok = tCheck(logger, "quick amounts oz", Units.quickAmountsMl()[2] == 473) && ok;
    return ok;
}

(:test)
function testMoodThresholds(logger as Logger) as Boolean {
    tReset();
    var ok = tCheck(logger, "goal met -> hydrated", Pet.moodFor([100], true, false) == Pet.MOOD_HYDRATED);
    ok = tCheck(logger, "85 -> on track", Pet.moodFor([85], false, false) == Pet.MOOD_ON_TRACK) && ok;
    ok = tCheck(logger, "60 -> thirsty", Pet.moodFor([60], false, false) == Pet.MOOD_THIRSTY) && ok;
    ok = tCheck(logger, "20 -> last warning", Pet.moodFor([20], false, false) == Pet.MOOD_LAST_WARNING) && ok;
    ok = tCheck(logger, "0 -> collapsed", Pet.moodFor([0], false, false) == Pet.MOOD_COLLAPSED) && ok;
    ok = tCheck(logger, "night -> sleeping", Pet.moodFor([0], false, true) == Pet.MOOD_SLEEPING) && ok;
    ok = tCheck(logger, "worst habit wins", Pet.moodFor([90, 40], false, false) == Pet.MOOD_LAST_WARNING) && ok;
    ok = tCheck(logger, "isWorse", Pet.isWorse(Pet.MOOD_COLLAPSED, Pet.MOOD_THIRSTY)) && ok;
    ok = tCheck(logger, "sleeping never worse", !Pet.isWorse(Pet.MOOD_COLLAPSED, Pet.MOOD_SLEEPING)) && ok;
    return ok;
}

(:test)
function testPetScoreDeficit(logger as Logger) as Boolean {
    tReset();
    Demo.active = true;          // lets us fix the time of day
    Demo.dayFrac = 0.5;          // halfway through the waking day
    var ok = tCheck(logger, "on pace -> 100", Hydration.petScore(1000, 2000) == 100);
    ok = tCheck(logger, "10% behind -> 80", Hydration.petScore(800, 2000) == 80) && ok;
    ok = tCheck(logger, "25% behind -> 50", Hydration.petScore(500, 2000) == 50) && ok;
    ok = tCheck(logger, "50% behind -> 0", Hydration.petScore(0, 2000) == 0) && ok;
    ok = tCheck(logger, "goal met -> 100", Hydration.petScore(2000, 2000) == 100) && ok;
    Demo.dayFrac = 0.0;
    ok = tCheck(logger, "start of day -> 100", Hydration.petScore(0, 2000) == 100) && ok;
    tReset();
    return ok;
}

(:test)
function testLogAddUndo(logger as Logger) as Boolean {
    tReset();
    WaterLog.add(250, null);
    WaterLog.add(500, null);
    var ok = tCheck(logger, "total 750", WaterLog.getMl() == 750);
    ok = tCheck(logger, "2 entries", WaterLog.entries().size() == 2) && ok;
    ok = tCheck(logger, "undo returns 500", WaterLog.undoLast() == 500) && ok;
    ok = tCheck(logger, "total 250", WaterLog.getMl() == 250) && ok;
    WaterLog.undoLast();
    ok = tCheck(logger, "undo on empty is 0", WaterLog.undoLast() == 0) && ok;
    ok = tCheck(logger, "never negative", WaterLog.getMl() == 0) && ok;
    var r = WaterLog.dayRecord(WaterLog.today());
    ok = tCheck(logger, "history records today", r != null && r[0] == 0) && ok;
    WaterLog.add(250, null);
    WaterLog.resetAll();
    ok = tCheck(logger, "reset clears today", WaterLog.getMl() == 0 && WaterLog.dayRecord(WaterLog.today()) == null) && ok;
    return ok;
}

function tSetDay(n as Number, ml as Number, goal as Number) as Void {
    var h = WaterLog.history();
    h[WaterLog.daysAgo(n)] = [ml, goal] as Array<Storage.ValueType>;
    Storage.setValue(WaterLog.KEY_HISTORY, h);
}

(:test)
function testStreak(logger as Logger) as Boolean {
    tReset();
    tSetDay(1, 2000, 2000);
    tSetDay(2, 2100, 2000);
    tSetDay(3, 2000, 2000);
    tSetDay(4, 500, 2000);        // missed: stops the streak
    tSetDay(5, 2000, 2000);
    var ok = tCheck(logger, "3-day streak (today not met yet)", WaterLog.streak() == 3);
    WaterLog.add(Hydration.goalMl(), null);
    ok = tCheck(logger, "today met -> 4", WaterLog.streak() == 4) && ok;
    tReset();
    ok = tCheck(logger, "no history -> 0", WaterLog.streak() == 0) && ok;
    return ok;
}

(:test)
function testAddToYesterday(logger as Logger) as Boolean {
    tReset();
    tSetDay(1, 1800, 2000);
    WaterLog.addToYesterday(250);
    var r = WaterLog.dayRecord(WaterLog.daysAgo(1));
    var ok = tCheck(logger, "yesterday 2050", r != null && r[0] == 2050 && r[1] == 2000);
    ok = tCheck(logger, "yesterday now met", WaterLog.dayMet(WaterLog.daysAgo(1))) && ok;
    ok = tCheck(logger, "today untouched", WaterLog.getMl() == 0) && ok;
    tReset();
    WaterLog.addToYesterday(300);
    r = WaterLog.dayRecord(WaterLog.daysAgo(1));
    ok = tCheck(logger, "no record yet -> created", r != null && r[0] == 300) && ok;
    return ok;
}

(:test)
function testRewards(logger as Logger) as Boolean {
    tReset();
    Storage.setValue(Rewards.KEY_GOAL_DAYS, 2);
    WaterLog.add(Hydration.goalMl(), null);              // today met: 3rd goal day
    var item = Rewards.checkDay(WaterLog.today());
    var ok = tCheck(logger, "3rd goal day unlocks party hat", item == HamsterArt.ACC_PARTY_HAT);
    ok = tCheck(logger, "goal days = 3", Rewards.goalDays() == 3) && ok;
    ok = tCheck(logger, "counted only once", Rewards.checkDay(WaterLog.today()) == null && Rewards.goalDays() == 3) && ok;
    ok = tCheck(logger, "new item auto-worn", Rewards.wornHat() == HamsterArt.ACC_PARTY_HAT) && ok;
    ok = tCheck(logger, "first-goal badge", Rewards.hasBadge(Rewards.BADGE_FIRST)) && ok;
    ok = tCheck(logger, "1 of 12 unlocked", Rewards.unlockedCount() == 1) && ok;
    ok = tCheck(logger, "crown still locked", !Rewards.isUnlocked(HamsterArt.ACC_CROWN)) && ok;
    Rewards.toggleWear(HamsterArt.ACC_CROWN);
    ok = tCheck(logger, "can't wear locked item", Rewards.wornHat() == HamsterArt.ACC_PARTY_HAT) && ok;
    Rewards.toggleWear(HamsterArt.ACC_PARTY_HAT);
    ok = tCheck(logger, "toggle takes it off", Rewards.wornHat() == HamsterArt.ACC_NONE) && ok;
    tReset();
    WaterLog.add(100, null);
    ok = tCheck(logger, "unmet day not counted", Rewards.checkDay(WaterLog.today()) == null && Rewards.goalDays() == 0) && ok;
    Demo.active = true;
    WaterLog.add(Hydration.goalMl(), null);
    ok = tCheck(logger, "demo never counts", Rewards.checkDay(WaterLog.today()) == null && Rewards.goalDays() == 0) && ok;
    tReset();
    return ok;
}

(:test)
function testStreakBadges(logger as Logger) as Boolean {
    tReset();
    for (var i = 1; i <= 6; i++) {
        tSetDay(i, 2000, 2000);
    }
    WaterLog.add(Hydration.goalMl(), null);              // 7-day streak today
    Rewards.checkDay(WaterLog.today());
    var ok = tCheck(logger, "streak 3 badge", Rewards.hasBadge(Rewards.BADGE_STREAK3));
    ok = tCheck(logger, "streak 7 badge", Rewards.hasBadge(Rewards.BADGE_STREAK7)) && ok;
    ok = tCheck(logger, "no streak 30 badge", !Rewards.hasBadge(Rewards.BADGE_STREAK30)) && ok;
    return ok;
}

(:test)
function testReminderCapAndSnooze(logger as Logger) as Boolean {
    tReset();
    var ok = tCheck(logger, "cap passed with no reminder yet", WaterLog.reminderCapPassed(60));
    WaterLog.markReminded();
    ok = tCheck(logger, "cap blocks right after a reminder", !WaterLog.reminderCapPassed(60)) && ok;
    ok = tCheck(logger, "not snoozed", !WaterLog.isSnoozed()) && ok;
    WaterLog.snooze(WaterLog.nowSec());
    ok = tCheck(logger, "snoozed", WaterLog.isSnoozed()) && ok;
    WaterLog.snooze(WaterLog.nowSec() - 2 * 3600);
    ok = tCheck(logger, "old snooze expired", !WaterLog.isSnoozed()) && ok;
    WaterLog.backdateLastDrink(30 * 60);
    ok = tCheck(logger, "30 min since drink: 30 min left of 60", WaterLog.secondsUntilDue(60) > 29 * 60
                                                                     && WaterLog.secondsUntilDue(60) <= 30 * 60) && ok;
    return ok;
}

(:test)
function testClockStart(logger as Logger) as Boolean {
    tReset();
    var ok = tCheck(logger, "nothing logged -> due now", WaterLog.secondsUntilDue(60) == 0);
    WaterLog.startClock();
    ok = tCheck(logger, "after setup -> not due for an hour", WaterLog.secondsUntilDue(60) > 59 * 60) && ok;
    WaterLog.backdateLastDrink(2 * 3600);
    ok = tCheck(logger, "older drink doesn't override the clock", WaterLog.secondsUntilDue(60) > 59 * 60) && ok;
    return ok;
}

(:test)
function testMoodDropReminder(logger as Logger) as Boolean {
    tReset();
    var ok = tCheck(logger, "first thirsty -> remind", Reminders.moodDropped(Pet.MOOD_THIRSTY));
    ok = tCheck(logger, "still thirsty -> no", !Reminders.moodDropped(Pet.MOOD_THIRSTY)) && ok;
    ok = tCheck(logger, "worse -> remind", Reminders.moodDropped(Pet.MOOD_LAST_WARNING)) && ok;
    ok = tCheck(logger, "better -> no", !Reminders.moodDropped(Pet.MOOD_ON_TRACK)) && ok;
    ok = tCheck(logger, "drops again -> remind", Reminders.moodDropped(Pet.MOOD_THIRSTY)) && ok;
    return ok;
}

(:test)
function testAgeGenderGoal(logger as Logger) as Boolean {
    tReset();
    var ok = true;
    if (Hydration.weightKg() == null) {
        Prefs.setGender(Prefs.GENDER_MALE);
        ok = tCheck(logger, "male, no weight -> 2500", Hydration.baseMl() == 2500) && ok;
        Prefs.setGender(Prefs.GENDER_FEMALE);
        ok = tCheck(logger, "female, no weight -> 2000", Hydration.baseMl() == 2000) && ok;
        Prefs.setGender(Prefs.GENDER_UNSAID);
        ok = tCheck(logger, "unsaid, no weight -> 2200", Hydration.baseMl() == 2200) && ok;
    } else {
        logger.debug("skip gender goals: the simulator profile has a weight set");
    }
    Prefs.setAge(10);
    ok = tCheck(logger, "child capped at 1700", Hydration.baseMl() <= 1700) && ok;
    Prefs.setAge(70);
    ok = tCheck(logger, "65+ reminders every 45 min", Hydration.intervalMin(false, null) == 45) && ok;
    Prefs.setAge(30);
    ok = tCheck(logger, "adult reminders every 60 min", Hydration.intervalMin(false, null) == 60) && ok;
    ok = tCheck(logger, "exertion -> 25", Hydration.intervalMin(true, null) == 25) && ok;
    ok = tCheck(logger, "gym -> 20", Hydration.intervalMin(false, Places.GYM) == 20) && ok;
    Prefs.setAge(150);
    ok = tCheck(logger, "age clamped to 100", Prefs.age() == 100) && ok;
    return ok;
}

(:test)
function testNameAndPrefs(logger as Logger) as Boolean {
    tReset();
    var ok = tCheck(logger, "default name Mizu", Prefs.name().equals("Mizu"));
    Prefs.setName("  Coco  ");
    ok = tCheck(logger, "name trimmed", Prefs.name().equals("Coco")) && ok;
    Prefs.setName("Bartholomew the Great");
    ok = tCheck(logger, "name capped at 10", Prefs.name().length() == 10) && ok;
    Prefs.setName("   ");
    ok = tCheck(logger, "blank -> Mizu", Prefs.name().equals("Mizu")) && ok;
    ok = tCheck(logger, "wake default 7", Prefs.wakeHour() == 7) && ok;
    Storage.setValue(Prefs.KEY_WAKE, 11);
    ok = tCheck(logger, "wake wraps 11 -> 4", Prefs.cycleWake() == 4) && ok;
    ok = tCheck(logger, "not onboarded", !Prefs.onboarded()) && ok;
    Prefs.setOnboarded();
    ok = tCheck(logger, "onboarded", Prefs.onboarded()) && ok;
    return ok;
}

(:test)
function testPlaces(logger as Logger) as Boolean {
    tReset();
    var d = Places.distanceM(51.0441750, -114.0553551, 51.0450750, -114.0553551);   // 0.0009 deg north
    var ok = tCheck(logger, "~100 m north", d > 95 && d < 105);
    Places.save(Places.GYM, 51.0441750d, -114.0553551d, 4);
    ok = tCheck(logger, "at the gym", Places.placeAt(51.0442, -114.0554) == Places.GYM) && ok;
    ok = tCheck(logger, "1 km away -> none", Places.placeAt(51.0532, -114.0553) == null) && ok;
    ok = tCheck(logger, "saving isn't an arrival", Places.checkArrival() == null) && ok;
    Places.clearLastPlace();
    ok = tCheck(logger, "after clearing: arrival", Places.checkArrival() == Places.GYM) && ok;
    ok = tCheck(logger, "arrival only once", Places.checkArrival() == null) && ok;
    return ok;
}
