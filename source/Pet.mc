import Toybox.Application;
import Toybox.Lang;

// The hamster's state. Habit-agnostic: every habit reports a wellbeing score
// (0 = neglected, 100 = fully on track) and the hamster feels its *worst*
// need, so falling behind on any one habit makes it unhappy.
// It's never permanent: collapsed always recovers with the next drink.
//
// To add a habit: give it a petScore() and add it to the scores passed in.
(:background)
module Pet {

    enum {
        MOOD_SLEEPING,      // outside the waking window
        MOOD_HYDRATED,      // every habit's goal met today
        MOOD_ON_TRACK,
        MOOD_THIRSTY,
        MOOD_LAST_WARNING,  // crying, toy water pistol, red room
        MOOD_COLLAPSED,     // lying down, grey room
        MOOD_AWAY           // walked off after too many missed days
    }

    // Coco walks off after MORE than this many missed days in a row.
    const AWAY_AFTER_MISSED_DAYS = 3;
    const KEY_FIRST_DAY = "firstDay";       // first day using the app
    const KEY_RETURNED_DAY = "returnedDay"; // day Coco last came back

    // Days in a row the water goal was missed, counting back from
    // yesterday. Stops at a met day, the day Coco last came back, or the
    // first day using the app.
    function missedRun() as Number {
        var first = firstDay();
        var v = Storage.getValue(KEY_RETURNED_DAY);
        var returned = v instanceof Number ? v : 0;
        var n = 0;
        for (var i = 1; i <= WaterLog.HISTORY_DAYS; i++) {
            var day = WaterLog.daysAgo(i);
            if (day < first || day <= returned || WaterLog.dayMet(day)) {
                break;
            }
            n++;
        }
        return n;
    }

    // Stored first day, else the oldest day in the history, else today.
    function firstDay() as Number {
        var v = Storage.getValue(KEY_FIRST_DAY);
        if (v instanceof Number) {
            return v;
        }
        var oldest = WaterLog.today();
        var keys = WaterLog.history().keys();
        for (var i = 0; i < keys.size(); i++) {
            var k = keys[i];
            if (k instanceof Number && k < oldest) {
                oldest = k;
            }
        }
        return oldest;
    }

    function markFirstDay() as Void {
        if (Storage.getValue(KEY_FIRST_DAY) == null) {
            Storage.setValue(KEY_FIRST_DAY, WaterLog.today());
        }
    }

    function isAway() as Boolean {
        if (Demo.active) {
            return Demo.away;
        }
        return missedRun() > AWAY_AFTER_MISSED_DAYS;
    }

    // Coco comes back (first drink while away): the missed run restarts.
    function comeBack() as Void {
        if (Demo.active) {
            Demo.away = false;          // never touch the real streak from the demo
            return;
        }
        Storage.setValue(KEY_RETURNED_DAY, WaterLog.today());
    }

    const ON_TRACK_MIN = 80;
    const THIRSTY_MIN = 50;
    const LAST_WARNING_MIN = 1;   // 0 = collapsed

    function moodFor(scores as Array<Number>, allGoalsMet as Boolean, sleeping as Boolean) as Number {
        if (sleeping) {
            return MOOD_SLEEPING;
        }
        if (allGoalsMet) {
            return MOOD_HYDRATED;
        }
        var worst = worstScore(scores);
        if (worst >= ON_TRACK_MIN) {
            return MOOD_ON_TRACK;
        }
        if (worst >= THIRSTY_MIN) {
            return MOOD_THIRSTY;
        }
        if (worst >= LAST_WARNING_MIN) {
            return MOOD_LAST_WARNING;
        }
        return MOOD_COLLAPSED;
    }

    function worstScore(scores as Array<Number>) as Number {
        var worst = 100;
        for (var i = 0; i < scores.size(); i++) {
            if (scores[i] < worst) {
                worst = scores[i];
            }
        }
        return worst;
    }

    // Habits feeding the pet (index into scores()).
    enum {
        HABIT_WATER,
        HABIT_STEPS
    }

    // Every habit's score, in HABIT_* order.
    function scores() as Array<Number> {
        return [Hydration.petScore(WaterLog.getMl(), Hydration.goalMl()), Steps.petScore()];
    }

    // The habit Coco needs most right now (water wins ties).
    function worstHabit(s as Array<Number>) as Number {
        return s[HABIT_STEPS] < s[HABIT_WATER] ? HABIT_STEPS : HABIT_WATER;
    }

    // Hydrated (the happiest look) once today's water goal is met and no
    // other habit is falling behind.
    function currentMood() as Number {
        if (isAway()) {
            return MOOD_AWAY;
        }
        var s = scores();
        var waterMet = WaterLog.getMl() >= Hydration.goalMl();
        return moodFor(s, waterMet && worstScore(s) >= ON_TRACK_MIN, Prefs.isNight());
    }

    // Worse = higher number among the awake moods.
    function isWorse(a as Number, b as Number) as Boolean {
        return a > b && a != MOOD_SLEEPING && b != MOOD_SLEEPING;
    }
}
