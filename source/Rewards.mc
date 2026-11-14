import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Rewards for consistency: a running count of goal days (kept separately
// from the 35-day history so unlocks never expire), 12 accessories (one new
// item every 3 goal days), 9 badges, and what the hamster is wearing
// (one hat + one other item).
module Rewards {

    const DAYS_PER_ITEM = 3;
    const ITEM_COUNT = 12;      // accessory ids 1..12 (HamsterArt.ACC_*)
    const BADGE_COUNT = 9;

    // Badge bits, in display order.
    enum {
        BADGE_FIRST,      // first goal day
        BADGE_STREAK3,
        BADGE_STREAK7,
        BADGE_STREAK30,
        BADGE_STREAK100,
        BADGE_WEEK,       // a perfect Monday-Sunday week
        BADGE_TOTAL10,    // 10 goal days in total
        BADGE_TOTAL50,
        BADGE_TOTAL100
    }
    const BADGE_LABELS = ["1", "3", "7", "30", "100", "Wk", "x10", "x50", "x100"];

    const KEY_GOAL_DAYS = "goalDays";
    const KEY_COUNTED = "countedDays";
    const KEY_BADGES = "badges";
    const KEY_WORN = "worn";          // [hat, other]

    function num(key as String) as Number {
        var v = Storage.getValue(key);
        return v instanceof Number ? v : 0;
    }

    function goalDays() as Number {
        return num(KEY_GOAL_DAYS);
    }

    // ---------------------------------------------------------------------
    // Accessories

    function isHat(item as Number) as Boolean {
        return item == HamsterArt.ACC_PARTY_HAT || item == HamsterArt.ACC_CROWN
            || item == HamsterArt.ACC_FLOWER || item == HamsterArt.ACC_SWEATBAND
            || item == HamsterArt.ACC_CAP;
    }

    function unlockedCount() as Number {
        var n = goalDays() / DAYS_PER_ITEM;
        return n > ITEM_COUNT ? ITEM_COUNT : n;
    }

    function isUnlocked(item as Number) as Boolean {
        return item >= 1 && item <= unlockedCount();
    }

    // Goal days needed to unlock an item.
    function daysFor(item as Number) as Number {
        return item * DAYS_PER_ITEM;
    }

    function worn() as Array<Number> {
        var v = Storage.getValue(KEY_WORN);
        if (v instanceof Array && v.size() == 2) {
            return v as Array<Number>;
        }
        return [HamsterArt.ACC_NONE, HamsterArt.ACC_NONE] as Array<Number>;
    }

    function wornHat() as Number {
        return Demo.active && Demo.hat != null ? Demo.hat as Number : worn()[0];
    }

    function wornOther() as Number {
        return Demo.active && Demo.other != null ? Demo.other as Number : worn()[1];
    }

    function isWorn(item as Number) as Boolean {
        var w = worn();
        return w[0] == item || w[1] == item;
    }

    // Put an item on (or take it off if it's already on). One per slot.
    function toggleWear(item as Number) as Void {
        if (!isUnlocked(item)) {
            return;
        }
        var w = worn();
        var slot = isHat(item) ? 0 : 1;
        w[slot] = w[slot] == item ? HamsterArt.ACC_NONE : item;
        Storage.setValue(KEY_WORN, w as Array<Storage.ValueType>);
    }

    function itemName(item as Number) as String {
        var ids = [Rez.Strings.AccNone, Rez.Strings.AccPartyHat, Rez.Strings.AccBow,
                   Rez.Strings.AccGlasses, Rez.Strings.AccScarf, Rez.Strings.AccCrown,
                   Rez.Strings.AccFlower, Rez.Strings.AccSunglasses, Rez.Strings.AccSweatband,
                   Rez.Strings.AccBowTie, Rez.Strings.AccCap, Rez.Strings.AccPlant,
                   Rez.Strings.AccMedal];
        return WatchUi.loadResource(ids[item]) as String;
    }

    // ---------------------------------------------------------------------
    // Badges

    function badges() as Number {
        return Demo.active ? Demo.badges : num(KEY_BADGES);
    }

    function hasBadge(b as Number) as Boolean {
        return (badges() & (1 << b)) != 0;
    }

    function badgeCount() as Number {
        var n = 0;
        for (var i = 0; i < BADGE_COUNT; i++) {
            if (hasBadge(i)) { n++; }
        }
        return n;
    }

    // ---------------------------------------------------------------------
    // Call after logging water for `day`. If that day just reached its goal
    // (and wasn't counted before), counts it, updates badges, and unlocks
    // (and puts on) the next accessory every 3 goal days.
    // Returns the newly unlocked item, or null.
    function checkDay(day as Number) as Number? {
        if (Demo.active || !WaterLog.dayMet(day)) {
            return null;
        }
        var v = Storage.getValue(KEY_COUNTED);
        var counted = v instanceof Array ? v as Array<Number> : [] as Array<Number>;
        if (counted.indexOf(day) >= 0) {
            return null;
        }
        counted.add(day);
        if (counted.size() > 5) {
            counted = counted.slice(counted.size() - 5, null);
        }
        Storage.setValue(KEY_COUNTED, counted as Array<Storage.ValueType>);

        var total = goalDays() + 1;
        Storage.setValue(KEY_GOAL_DAYS, total);

        // Badges
        var b = num(KEY_BADGES);
        var streak = WaterLog.streak();
        b |= 1 << BADGE_FIRST;
        if (streak >= 3) { b |= 1 << BADGE_STREAK3; }
        if (streak >= 7) { b |= 1 << BADGE_STREAK7; }
        if (streak >= 30) { b |= 1 << BADGE_STREAK30; }
        if (streak >= 100) { b |= 1 << BADGE_STREAK100; }
        if (total >= 10) { b |= 1 << BADGE_TOTAL10; }
        if (total >= 50) { b |= 1 << BADGE_TOTAL50; }
        if (total >= 100) { b |= 1 << BADGE_TOTAL100; }
        if (day == WaterLog.today() && perfectWeek()) { b |= 1 << BADGE_WEEK; }
        Storage.setValue(KEY_BADGES, b);

        // Accessory every DAYS_PER_ITEM goal days; wear it if that slot is free.
        if (total % DAYS_PER_ITEM == 0 && total / DAYS_PER_ITEM <= ITEM_COUNT) {
            var item = total / DAYS_PER_ITEM;
            var w = worn();
            var slot = isHat(item) ? 0 : 1;
            if (w[slot] == HamsterArt.ACC_NONE) {
                toggleWear(item);
            }
            return item;
        }
        return null;
    }

    // Today is Sunday and Monday..Sunday were all met.
    function perfectWeek() as Boolean {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        if (info.day_of_week != 1) {
            return false;
        }
        for (var i = 0; i < 7; i++) {
            if (!WaterLog.dayMet(WaterLog.daysAgo(i))) {
                return false;
            }
        }
        return true;
    }
}
