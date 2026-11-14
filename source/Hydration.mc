import Toybox.Application;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;

// Adjusts the daily water goal and reminder interval from body weight,
// today's intensity minutes, and recent heart rate. Shared by the foreground
// app and the background reminder service.
//
// These are rough, conservative heuristics, not medical advice.
(:background)
module Hydration {

    // --- Base goal from body weight -------------------------------------
    const ML_PER_KG = 33;           // ~30-35 ml per kg is a common guideline
    const DEFAULT_BASE_ML = 2200;   // no weight set, gender not given
    const FEMALE_BASE_ML = 2000;    // no weight set
    const MALE_BASE_ML = 2500;      // no weight set
    const CHILD_MAX_AGE = 13;       // under 14: goal capped
    const CHILD_MAX_ML = 1700;
    const OLDER_MIN_AGE = 65;       // 65+: thirst fades, remind more often
    const OLDER_INTERVAL_MIN = 45;
    const MIN_BASE_ML = 1500;
    const MAX_BASE_ML = 3500;

    // --- Activity bonus from Garmin intensity minutes --------------------
    const ML_PER_MODERATE_MIN = 10;
    const ML_PER_VIGOROUS_MIN = 15;
    const MAX_ACTIVITY_BONUS_ML = 1500;

    // --- Exertion: sustained heart rate at/above zone 3 ------------------
    const EXERTION_WINDOW_MIN = 30;   // look back this far
    const EXERTION_PERCENT = 50;      // % of samples that must be >= zone 3
    const MIN_HR_SAMPLES = 5;         // ignore windows with too little data
    const FALLBACK_ZONE3_BPM = 130;   // if the watch has no HR zones
    const EXERTION_INTERVAL_MIN = 25; // remind this often while exerting
    const EXERTION_DRINK_ML = 500;    // suggested drink after exertion

    // --- Place rules (places themselves live in Places.mc) ---------------
    const GYM_INTERVAL_MIN = 20;
    const WORK_INTERVAL_MIN = 45;
    const GYM_DRINK_ML = 500;
    // Skip an arrival reminder if you drank within this many minutes.
    const ARRIVAL_SKIP_IF_DRANK_MIN = 15;

    // Body weight in kg from the user profile, or null.
    function weightKg() as Number? {
        var w = UserProfile.getProfile().weight;
        if (w == null || w <= 0) {
            return null;
        }
        // Garmin stores weight in grams; tolerate kg just in case.
        return w > 1000 ? w / 1000 : w;
    }

    // Base goal: from weight if set, else from gender; capped for children.
    function baseMl() as Number {
        var kg = weightKg();
        var ml;
        if (kg != null) {
            ml = kg * ML_PER_KG;
            if (ml < MIN_BASE_ML) { ml = MIN_BASE_ML; }
            if (ml > MAX_BASE_ML) { ml = MAX_BASE_ML; }
        } else {
            var g = Prefs.gender();
            ml = g == Prefs.GENDER_MALE ? MALE_BASE_ML
               : g == Prefs.GENDER_FEMALE ? FEMALE_BASE_ML : DEFAULT_BASE_ML;
        }
        var age = Prefs.age();
        if (age != null && age <= CHILD_MAX_AGE && ml > CHILD_MAX_ML) {
            ml = CHILD_MAX_ML;
        }
        return ml;
    }

    function activityBonusMl() as Number {
        if (Demo.active) {
            return Demo.bonusMl;
        }
        var am = ActivityMonitor.getInfo().activeMinutesDay;
        if (am == null) {
            return 0;
        }
        var ml = am.moderate * ML_PER_MODERATE_MIN + am.vigorous * ML_PER_VIGOROUS_MIN;
        return ml > MAX_ACTIVITY_BONUS_ML ? MAX_ACTIVITY_BONUS_ML : ml;
    }

    function goalMl() as Number {
        return baseMl() + activityBonusMl();
    }

    // How much of today's goal comes from activity.
    function bonusMl() as Number {
        return activityBonusMl();
    }

    // Lower bound of HR zone 3 in bpm (= "max zone 2" in Garmin's array).
    function zone3Bpm() as Number {
        var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        if (zones.size() >= 3 && zones[2] > 0) {
            return zones[2];
        }
        return FALLBACK_ZONE3_BPM;
    }

    // True if heart rate has mostly been in zone 3+ over the recent window.
    function isExerting() as Boolean {
        if (Demo.active) {
            return Demo.exerting;
        }
        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getHeartRateHistory)) {
            return false;
        }
        var it = SensorHistory.getHeartRateHistory({
            :period => new Time.Duration(EXERTION_WINDOW_MIN * 60),
            :order => SensorHistory.ORDER_NEWEST_FIRST
        });
        var threshold = zone3Bpm();
        var total = 0;
        var high = 0;
        var sample = it.next();
        while (sample != null) {
            var bpm = sample.data;
            if (bpm != null) {
                total++;
                if (bpm >= threshold) {
                    high++;
                }
            }
            sample = it.next();
        }
        return total >= MIN_HR_SAMPLES && high * 100 >= total * EXERTION_PERCENT;
    }

    // Minutes between drinks: the shortest of the default, the exertion
    // interval (if exerting) and the current place's interval (if any).
    function intervalMin(exerting as Boolean, place as Number?) as Number {
        var m = Demo.active ? Demo.INTERVAL_MIN : WaterLog.INTERVAL_MIN;
        var age = Prefs.age();
        if (!Demo.active && age != null && age >= OLDER_MIN_AGE && OLDER_INTERVAL_MIN < m) {
            m = OLDER_INTERVAL_MIN;
        }
        if (exerting && EXERTION_INTERVAL_MIN < m) {
            m = EXERTION_INTERVAL_MIN;
        }
        var p = placeIntervalMin(place);
        if (p != null && p < m) {
            m = p;
        }
        return m;
    }

    // Place-specific reminder interval, or null for the default.
    function placeIntervalMin(place as Number?) as Number? {
        if (place == Places.GYM) {
            return GYM_INTERVAL_MIN;
        }
        if (place == Places.WORK) {
            return WORK_INTERVAL_MIN;
        }
        return null;
    }

    // A specific amount to suggest (ml), or null for the default.
    function suggestedDrinkMl(exerting as Boolean, place as Number?) as Number? {
        if (exerting) {
            return EXERTION_DRINK_ML;
        }
        if (place == Places.GYM) {
            return GYM_DRINK_ML;
        }
        return null;
    }

    // Should arriving at a place trigger a reminder right now?
    function arrivalReminderAllowed() as Boolean {
        if (WaterLog.goalReached() || WaterLog.isQuietHours()) {
            return false;
        }
        var since = WaterLog.secondsSinceLastDrink();
        return since == null || since >= ARRIVAL_SKIP_IF_DRANK_MIN * 60;
    }

    // [subtitle, body] for the notification when arriving at `place`.
    function arrivalMessage(place as Number) as [String, String] {
        var title;
        var body;
        if (place == Places.GYM) {
            title = Rez.Strings.ArriveGymTitle;
            body = Lang.format(Application.loadResource(Rez.Strings.ArriveGymBody) as String, [Units.amount(GYM_DRINK_ML)]);
        } else if (place == Places.HOME) {
            title = Rez.Strings.ArriveHomeTitle;
            body = Application.loadResource(Rez.Strings.ArriveHomeBody) as String;
        } else if (place == Places.WORK) {
            title = Rez.Strings.ArriveWorkTitle;
            body = Application.loadResource(Rez.Strings.ArriveWorkBody) as String;
        } else {
            title = Rez.Strings.ArriveOtherTitle;
            body = Application.loadResource(Rez.Strings.ArriveOtherBody) as String;
        }
        return [Application.loadResource(title) as String, body];
    }

    // --- Pet wellbeing (0-100) -------------------------------------------
    // From the deficit: how far behind "expected so far" you are, where
    // expected = goal x share of the waking window that has passed.
    //   deficit <10% of goal -> 80..100 (on track)
    //   10-25%               -> 50..80  (thirsty)
    //   25-50%               -> 0..50   (last warning)
    //   >50%                 -> 0       (collapsed)
    function deficitPercent(ml as Number, goal as Number) as Number {
        if (goal <= 0) {
            return 0;
        }
        var expected = goal * Prefs.dayFraction();
        var deficit = expected - ml;
        return deficit <= 0 ? 0 : (deficit * 100 / goal).toNumber();
    }

    function petScore(ml as Number, goal as Number) as Number {
        if (ml >= goal) {
            return 100;
        }
        var score = 100 - 2 * deficitPercent(ml, goal);
        return score < 0 ? 0 : score;
    }
}
