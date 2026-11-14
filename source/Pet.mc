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
        MOOD_COLLAPSED      // lying down, grey room
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

    // Current mood from the water habit (the only habit so far).
    function currentMood() as Number {
        var ml = WaterLog.getMl();
        var goal = Hydration.goalMl();
        return moodFor([Hydration.petScore(ml, goal)], ml >= goal, Prefs.isNight());
    }

    // Worse = higher number among the awake moods.
    function isWorse(a as Number, b as Number) as Boolean {
        return a > b && a != MOOD_SLEEPING && b != MOOD_SLEEPING;
    }
}
