import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Shared water-tracking state and reminder rules. Annotated (:background) so
// the background service can use it as well as the foreground app.
// Everything is persisted in Application.Storage (readable/writable from the
// background on Connect IQ 3.2+).
(:background)
module WaterLog {

    const GOAL_GLASSES = 8;        // daily goal
    const GLASS_ML = 250;          // 8 x 250 ml = 2 L
    const INTERVAL_MIN = 60;       // remind when this long since the last glass
    const REPEAT_MIN = 30;         // don't re-remind more often than this
    const CHECK_MIN = 15;          // background check period (system min is 5)
    const QUIET_START_HOUR = 21;   // no reminders from 21:00 ...
    const QUIET_END_HOUR = 8;      // ... until 08:00

    // Notification action id for "+1 glass".
    const ACTION_DRANK = 1;

    const KEY_DAY = "day";
    const KEY_COUNT = "count";
    const KEY_LAST_DRINK = "lastDrink";
    const KEY_LAST_REMIND = "lastRemind";

    function nowSec() as Number {
        return Time.now().value();
    }

    // YYYYMMDD in local time, used to reset the count at midnight.
    function dayKey(sec as Number) as Number {
        var i = Gregorian.info(new Time.Moment(sec), Time.FORMAT_SHORT);
        return (i.year as Number) * 10000 + (i.month as Number) * 100 + (i.day as Number);
    }

    function getNumber(key as String) as Number? {
        var v = Storage.getValue(key);
        return v instanceof Number ? v : null;
    }

    // Glasses logged today (0 if the stored count is from a previous day).
    function getCount() as Number {
        if (getNumber(KEY_DAY) != dayKey(nowSec())) {
            return 0;
        }
        var c = getNumber(KEY_COUNT);
        return c != null ? c : 0;
    }

    // Log one glass, drunk at `atSec` (defaults to now).
    function addGlass(atSec as Number?) as Void {
        var t = atSec != null ? atSec : nowSec();
        var count = getCount();
        Storage.setValue(KEY_DAY, dayKey(nowSec()));
        Storage.setValue(KEY_COUNT, count + 1);
        var last = getNumber(KEY_LAST_DRINK);
        if (last == null || t > last) {
            Storage.setValue(KEY_LAST_DRINK, t);
        }
    }

    function removeGlass() as Void {
        var count = getCount();
        if (count > 0) {
            Storage.setValue(KEY_DAY, dayKey(nowSec()));
            Storage.setValue(KEY_COUNT, count - 1);
        }
    }

    // Seconds until the next drink is due (0 = due now).
    function secondsUntilDue() as Number {
        var last = getNumber(KEY_LAST_DRINK);
        if (last == null) {
            return 0;
        }
        var remaining = last + INTERVAL_MIN * 60 - nowSec();
        return remaining > 0 ? remaining : 0;
    }

    function isQuietHours() as Boolean {
        var h = System.getClockTime().hour;
        return h >= QUIET_START_HOUR || h < QUIET_END_HOUR;
    }

    function goalReached() as Boolean {
        return getCount() >= GOAL_GLASSES;
    }

    // Is a drink due right now (ignoring whether we already nagged)?
    function isDue() as Boolean {
        return !goalReached() && !isQuietHours() && secondsUntilDue() == 0;
    }

    // Should the background post a notification now?
    function shouldNotify() as Boolean {
        if (!isDue()) {
            return false;
        }
        var lastRemind = getNumber(KEY_LAST_REMIND);
        return lastRemind == null || nowSec() - lastRemind >= REPEAT_MIN * 60;
    }

    function markReminded() as Void {
        Storage.setValue(KEY_LAST_REMIND, nowSec());
    }
}
