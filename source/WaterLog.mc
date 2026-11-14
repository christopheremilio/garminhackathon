import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Water log in millilitres: today's entries (for undo), day-by-day history
// (for streaks and the weekly tracker), and reminder timing. Annotated
// (:background) so the background reminder service can use it too.
// Everything is persisted in Application.Storage.
(:background)
module WaterLog {

    // Drink amounts (and their units) live in Units.
    const INTERVAL_MIN = 60;       // remind when this long since the last drink
    const REPEAT_MIN = 30;         // don't re-remind more often than this
    const CHECK_MIN = 15;          // background check period (system min is 5)
    const HISTORY_DAYS = 35;       // days of totals kept for streaks/weekly
    const SNOOZE_MIN = 60;

    // Notification action ids.
    const ACTION_DRANK = 1;        // "+250" (Units.defaultAddMl)
    const ACTION_SNOOZE = 2;       // "Snooze"

    const KEY_DAY = "day";
    const KEY_ML = "ml";
    const KEY_ENTRIES = "entries";     // today's amounts, newest last (undo)
    const KEY_HISTORY = "history";     // { dayKey => [ml, goalMl] }
    const KEY_LAST_DRINK = "lastDrink";
    const KEY_LAST_REMIND = "lastRemind";
    const KEY_SNOOZE_UNTIL = "snoozeUntil";
    const KEY_CLOCK_START = "clockStart";   // reminder countdown start (setup / reset)

    function nowSec() as Number {
        return Time.now().value();
    }

    // YYYYMMDD in local time; the log resets at midnight.
    function dayKey(sec as Number) as Number {
        var i = Gregorian.info(new Time.Moment(sec), Time.FORMAT_SHORT);
        return (i.year as Number) * 10000 + (i.month as Number) * 100 + (i.day as Number);
    }

    function today() as Number {
        return dayKey(nowSec());
    }

    // Day key `n` days before today.
    function daysAgo(n as Number) as Number {
        return dayKey(nowSec() - n * 86400);
    }

    function getNumber(key as String) as Number? {
        var v = Storage.getValue(key);
        return v instanceof Number ? v : null;
    }

    // ---------------------------------------------------------------------
    // Today

    function isToday() as Boolean {
        return getNumber(KEY_DAY) == today();
    }

    // Millilitres logged today.
    function getMl() as Number {
        if (!isToday()) {
            return 0;
        }
        var ml = getNumber(KEY_ML);
        return ml != null ? ml : 0;
    }

    function entries() as Array<Number> {
        var v = Storage.getValue(KEY_ENTRIES);
        return (isToday() && v instanceof Array) ? v as Array<Number> : [] as Array<Number>;
    }

    function setToday(ml as Number, list as Array<Number>) as Void {
        Storage.setValue(KEY_DAY, today());
        Storage.setValue(KEY_ML, ml < 0 ? 0 : ml);
        Storage.setValue(KEY_ENTRIES, list as Array<Storage.ValueType>);
        recordToday();
    }

    // Log a drink of `ml`, drunk at `atSec` (defaults to now).
    function add(ml as Number, atSec as Number?) as Void {
        var list = entries();
        list.add(ml);
        setToday(getMl() + ml, list);
        var t = atSec != null ? atSec : nowSec();
        var last = getNumber(KEY_LAST_DRINK);
        if (last == null || t > last) {
            Storage.setValue(KEY_LAST_DRINK, t);
        }
    }

    // Remove today's most recent drink. Returns the amount removed (0 if none).
    function undoLast() as Number {
        var list = entries();
        if (list.size() == 0) {
            return 0;
        }
        var ml = list[list.size() - 1];
        list = list.slice(0, list.size() - 1);
        setToday(getMl() - ml, list);
        return ml;
    }

    function goalReached() as Boolean {
        return getMl() >= Hydration.goalMl();
    }

    // ---------------------------------------------------------------------
    // History, streaks

    function history() as Dictionary<Storage.KeyType, Storage.ValueType> {
        var v = Storage.getValue(KEY_HISTORY);
        return v instanceof Dictionary
            ? v as Dictionary<Storage.KeyType, Storage.ValueType>
            : {} as Dictionary<Storage.KeyType, Storage.ValueType>;
    }

    // [ml, goalMl] for a day, or null if nothing was recorded.
    function dayRecord(day as Number) as Array<Number>? {
        var r = history()[day];
        return r instanceof Array ? r as Array<Number> : null;
    }

    function dayMet(day as Number) as Boolean {
        var r = dayRecord(day);
        return r != null && r.size() >= 2 && r[1] > 0 && r[0] >= r[1];
    }

    // Save today's total and goal into history (called on every change and
    // periodically, so the goal reflects the whole day's activity).
    function recordToday() as Void {
        var h = history();
        h[today()] = [getMl(), Hydration.goalMl()] as Array<Storage.ValueType>;
        if (h.size() > HISTORY_DAYS) {
            var cutoff = daysAgo(HISTORY_DAYS);
            var keys = h.keys();
            for (var i = 0; i < keys.size(); i++) {
                var k = keys[i];
                if (k instanceof Number && k < cutoff) {
                    h.remove(k);
                }
            }
        }
        Storage.setValue(KEY_HISTORY, h);
        saveGlance();
    }

    // Small summary for the glance (which runs separately and only reads
    // this): [day, "1.2 / 2.0 L", "0.0 / 2.0 L", fill %, name, mood].
    const KEY_GLANCE = "glance";

    function saveGlance() as Void {
        var ml = getMl();
        var goal = Hydration.goalMl();
        var fill = goal > 0 ? ml * 100 / goal : 0;
        Storage.setValue(KEY_GLANCE, [today(), Units.pair(ml, goal), Units.pair(0, goal),
                                      fill > 100 ? 100 : fill, Prefs.name(), Pet.currentMood()]
                                     as Array<Storage.ValueType>);
    }

    // Add a drink to yesterday's total (forgot to log it).
    function addToYesterday(ml as Number) as Void {
        var day = daysAgo(1);
        var h = history();
        var r = dayRecord(day);
        h[day] = ((r != null && r.size() >= 2) ? [r[0] + ml, r[1]] : [ml, Hydration.goalMl()])
            as Array<Storage.ValueType>;
        Storage.setValue(KEY_HISTORY, h);
    }

    // Days in a row the goal was met. Today counts once it's met; until then
    // the streak is the run ending yesterday.
    function streak() as Number {
        var n = 0;
        if (dayMet(today())) {
            n = 1;
        }
        var i = 1;
        while (i <= HISTORY_DAYS && dayMet(daysAgo(i))) {
            n++;
            i++;
        }
        return n;
    }

    // ---------------------------------------------------------------------
    // Reminder timing

    function secondsSinceLastDrink() as Number? {
        var last = getNumber(KEY_LAST_DRINK);
        return last != null ? nowSec() - last : null;
    }

    // Start the reminder countdown now without logging a drink, so finishing
    // setup or resetting the day doesn't trigger a reminder straight away.
    function startClock() as Void {
        Storage.setValue(KEY_CLOCK_START, nowSec());
    }

    // Seconds until the next drink is due (0 = due now), counted from the
    // later of the last drink and the countdown start.
    function secondsUntilDue(intervalMin as Number) as Number {
        var last = getNumber(KEY_LAST_DRINK);
        var start = getNumber(KEY_CLOCK_START);
        if (start != null && (last == null || start > last)) {
            last = start;
        }
        if (last == null) {
            return 0;
        }
        var remaining = last + intervalMin * 60 - nowSec();
        return remaining > 0 ? remaining : 0;
    }

    // Quiet hours = outside the waking window (see Prefs).
    function isQuietHours() as Boolean {
        return Prefs.isNight();
    }

    function isDue(intervalMin as Number) as Boolean {
        return !goalReached() && !isQuietHours() && secondsUntilDue(intervalMin) == 0;
    }

    function snooze(fromSec as Number) as Void {
        Storage.setValue(KEY_SNOOZE_UNTIL, fromSec + SNOOZE_MIN * 60);
    }

    function isSnoozed() as Boolean {
        var until = getNumber(KEY_SNOOZE_UNTIL);
        return until != null && nowSec() < until;
    }

    // Has the combined reminder cap passed since the last reminder?
    function reminderCapPassed(intervalMin as Number) as Boolean {
        var repeatMin = intervalMin < REPEAT_MIN ? intervalMin : REPEAT_MIN;
        var lastRemind = getNumber(KEY_LAST_REMIND);
        return lastRemind == null || nowSec() - lastRemind >= repeatMin * 60;
    }

    // Regular interval reminder due?
    function shouldNotify(intervalMin as Number) as Boolean {
        return isDue(intervalMin) && !isSnoozed() && reminderCapPassed(intervalMin);
    }

    function markReminded() as Void {
        Storage.setValue(KEY_LAST_REMIND, nowSec());
    }

    // ---------------------------------------------------------------------
    // Demo helpers and reset

    function setMl(ml as Number) as Void {
        setToday(ml, [ml] as Array<Number>);
    }

    function backdateLastDrink(secondsAgo as Number) as Void {
        Storage.setValue(KEY_LAST_DRINK, nowSec() - secondsAgo);
    }

    // Reset today's data. Earlier days' history, places and the hamster's
    // name are kept.
    function resetAll() as Void {
        Storage.deleteValue(KEY_DAY);
        Storage.deleteValue(KEY_ML);
        Storage.deleteValue(KEY_ENTRIES);
        Storage.deleteValue(KEY_LAST_DRINK);
        Storage.deleteValue(KEY_LAST_REMIND);
        Storage.deleteValue(KEY_SNOOZE_UNTIL);
        var h = history();
        h.remove(today());
        Storage.setValue(KEY_HISTORY, h);
    }

}
