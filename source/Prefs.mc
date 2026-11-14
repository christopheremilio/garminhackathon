import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;

// User preferences stored on the watch: the hamster's name, the user's age
// and gender (asked on first launch, pre-filled from the Garmin profile),
// and the waking window (wake time to bedtime). The waking window drives quiet hours, the
// hamster sleeping, and how much water you "should" have had by now.
(:background)
module Prefs {

    const DEFAULT_NAME = "Coco";
    const MAX_NAME_LEN = 10;
    const DEFAULT_WAKE_HOUR = 7;
    const DEFAULT_BED_HOUR = 22;
    const WAKE_MIN_HOUR = 4;
    const WAKE_MAX_HOUR = 11;
    const BED_MIN_HOUR = 19;
    const BED_MAX_HOUR = 24;      // 24 = midnight

    const KEY_NAME = "petName";
    const KEY_NAME_ASKED = "petNameAsked";
    const KEY_WAKE = "wakeHour";
    const KEY_BED = "bedHour";
    const KEY_AGE = "age";
    const KEY_GENDER = "gender";
    const KEY_ONBOARDED = "onboarded";
    const KEY_WEIGHT = "weightKg";

    const MIN_WEIGHT_KG = 20;
    const MAX_WEIGHT_KG = 250;
    const DEFAULT_WEIGHT_KG = 70;

    // Weight in kg the user entered, or null (then the Garmin profile is used).
    function savedWeightKg() as Number? {
        var v = Storage.getValue(KEY_WEIGHT);
        return v instanceof Number ? v : null;
    }

    function setWeightKg(kg as Number) as Void {
        Storage.setValue(KEY_WEIGHT, kg < MIN_WEIGHT_KG ? MIN_WEIGHT_KG : (kg > MAX_WEIGHT_KG ? MAX_WEIGHT_KG : kg));
    }

    const MIN_AGE = 5;
    const MAX_AGE = 100;
    const DEFAULT_AGE = 30;

    enum {
        GENDER_FEMALE,
        GENDER_MALE,
        GENDER_OTHER,
        GENDER_UNSAID
    }

    // ---------------------------------------------------------------------
    // First-launch questions (name, age, gender)

    function onboarded() as Boolean {
        return Storage.getValue(KEY_ONBOARDED) != null;
    }

    function setOnboarded() as Void {
        Storage.setValue(KEY_ONBOARDED, true);
    }

    // Age in years: the saved answer, else from the Garmin profile, else null.
    function age() as Number? {
        var v = Storage.getValue(KEY_AGE);
        if (v instanceof Number) {
            return v;
        }
        return profileAge();
    }

    function profileAge() as Number? {
        var y = UserProfile.getProfile().birthYear;
        if (y == null || y < 1900) {
            return null;
        }
        var a = (Gregorian.info(Time.now(), Time.FORMAT_SHORT).year as Number) - y;
        return (a >= MIN_AGE && a <= MAX_AGE) ? a : null;
    }

    function setAge(a as Number) as Void {
        Storage.setValue(KEY_AGE, a < MIN_AGE ? MIN_AGE : (a > MAX_AGE ? MAX_AGE : a));
    }

    // Gender: the saved answer, else from the Garmin profile, else unsaid.
    function gender() as Number {
        var v = Storage.getValue(KEY_GENDER);
        if (v instanceof Number) {
            return v;
        }
        var g = UserProfile.getProfile().gender;
        if (g == UserProfile.GENDER_FEMALE) { return GENDER_FEMALE; }
        if (g == UserProfile.GENDER_MALE) { return GENDER_MALE; }
        return GENDER_UNSAID;
    }

    function setGender(g as Number) as Void {
        Storage.setValue(KEY_GENDER, g);
    }

    function name() as String {
        if (Demo.active) {
            return Demo.NAME;
        }
        var v = Storage.getValue(KEY_NAME);
        return (v instanceof String && v.length() > 0) ? v : DEFAULT_NAME;
    }

    // Trim, cap at MAX_NAME_LEN, fall back to the default if empty.
    function setName(text as String) as Void {
        var s = trim(text);
        if (s.length() > MAX_NAME_LEN) {
            s = s.substring(0, MAX_NAME_LEN) as String;
        }
        Storage.setValue(KEY_NAME, s.length() > 0 ? s : DEFAULT_NAME);
        Storage.setValue(KEY_NAME_ASKED, true);
    }

    function skipName() as Void {
        Storage.setValue(KEY_NAME_ASKED, true);
    }

    function nameAsked() as Boolean {
        return Storage.getValue(KEY_NAME_ASKED) != null;
    }

    function trim(s as String) as String {
        var chars = s.toCharArray();
        var start = 0;
        var end = chars.size();
        while (start < end && chars[start] == ' ') { start++; }
        while (end > start && chars[end - 1] == ' ') { end--; }
        return s.substring(start, end) as String;
    }

    function hourPref(key as String, def as Number, lo as Number, hi as Number) as Number {
        var v = Storage.getValue(key);
        return (v instanceof Number && v >= lo && v <= hi) ? v : def;
    }

    function wakeHour() as Number {
        return hourPref(KEY_WAKE, DEFAULT_WAKE_HOUR, WAKE_MIN_HOUR, WAKE_MAX_HOUR);
    }

    function bedHour() as Number {
        return hourPref(KEY_BED, DEFAULT_BED_HOUR, BED_MIN_HOUR, BED_MAX_HOUR);
    }

    // Step to the next allowed hour, wrapping around. Returns the new value.
    function cycleWake() as Number {
        var h = wakeHour() + 1;
        if (h > WAKE_MAX_HOUR) { h = WAKE_MIN_HOUR; }
        Storage.setValue(KEY_WAKE, h);
        return h;
    }

    function cycleBed() as Number {
        var h = bedHour() + 1;
        if (h > BED_MAX_HOUR) { h = BED_MIN_HOUR; }
        Storage.setValue(KEY_BED, h);
        return h;
    }

    function hourLabel(h as Number) as String {
        return (h % 24).format("%d") + ":00";
    }

    // Fraction of today's waking window that has passed (0..1).
    function dayFraction() as Float {
        if (Demo.active && Demo.dayFrac != null) {
            return Demo.dayFrac as Float;
        }
        var clock = System.getClockTime();
        var mins = clock.hour * 60 + clock.min - wakeHour() * 60;
        var span = (bedHour() - wakeHour()) * 60;
        if (mins <= 0) { return 0.0; }
        if (mins >= span) { return 1.0; }
        return mins.toFloat() / span;
    }

    // Outside the waking window: no reminders, hamster asleep.
    function isNight() as Boolean {
        if (Demo.active) {
            return false;
        }
        var h = System.getClockTime().hour;
        return h < wakeHour() || h >= bedHour();
    }
}
