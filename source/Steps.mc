import Toybox.ActivityMonitor;
import Toybox.Lang;

// Today's steps. The app doesn't push you to walk more; steps just raise
// how much water you need (walking all day = more water), and the home
// screen shows how many you've done.
(:background)
module Steps {

    const FREE_STEPS = 5000;        // no extra water for the first 5,000
    const STEPS_PER_GLASS = 5000;   // then +1 glass per 5,000 steps
    const MAX_GLASSES = 3;          // up to +3 glasses (20,000+ steps)

    function count() as Number {
        if (Demo.active) {
            return Demo.steps != null ? Demo.steps as Number : 0;
        }
        var s = ActivityMonitor.getInfo().steps;
        return s != null ? s : 0;
    }

    // Extra water for today's steps, in ml.
    function bonusMl() as Number {
        var extra = count() - FREE_STEPS;
        if (extra <= 0) {
            return 0;
        }
        var glasses = extra / STEPS_PER_GLASS;
        if (glasses > MAX_GLASSES) { glasses = MAX_GLASSES; }
        return glasses * Units.GLASS_ML;
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
