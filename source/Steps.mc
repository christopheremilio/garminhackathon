import Toybox.ActivityMonitor;
import Toybox.Lang;

// Habit #2: steps. Coco gets its energy from your steps. Like water, the
// score compares today's steps with what you'd expect by this time of the
// waking day; unlike water it's gentle: falling behind on steps can make
// Coco restless ("wants a walk") but never cry or faint - those stay
// water-only.
(:background)
module Steps {

    const DEFAULT_GOAL = 10000;
    const MIN_SCORE = 50;        // steps alone bottom out at the "restless" mood

    function count() as Number {
        if (Demo.active) {
            // the demo shows water; steps stay on target unless it sets them
            return Demo.steps != null ? Demo.steps as Number : goal();
        }
        var s = ActivityMonitor.getInfo().steps;
        return s != null ? s : 0;
    }

    // Your Garmin daily step goal, or 10,000.
    function goal() as Number {
        var g = ActivityMonitor.getInfo().stepGoal;
        return (g != null && g > 0) ? g : DEFAULT_GOAL;
    }

    function goalMet() as Boolean {
        return count() >= goal();
    }

    // 100 = on pace or goal met; 1 point off per 1% behind pace, floored at
    // MIN_SCORE.
    function petScore() as Number {
        var c = count();
        var g = goal();
        if (c >= g) {
            return 100;
        }
        var expected = g * Prefs.dayFraction();
        var deficit = expected - c;
        if (deficit <= 0) {
            return 100;
        }
        var score = 100 - (deficit * 100 / g).toNumber();
        return score < MIN_SCORE ? MIN_SCORE : score;
    }

    // "6,214"
    function withCommas(n as Number) as String {
        var s = n.format("%d");
        if (n < 1000) {
            return s;
        }
        return (n / 1000).format("%d") + "," + (n % 1000).format("%03d");
    }
}
