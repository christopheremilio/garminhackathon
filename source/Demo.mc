import Toybox.Lang;

// Demo-mode switch and the fake inputs the demo tour feeds the rules.
// When `active`, Hydration / Places / WaterLog read these instead of the real
// sensors, GPS and clock, so the tour works anywhere (simulator or watch).
//
// (:background) only because shared rule code references it; the background
// process never turns it on, so real reminders are unaffected.
(:background)
module Demo {

    // Auto-play the demo tour every time the app opens.
    // Set false for normal use.
    const ENABLED = true;

    // Normal reminder interval used during the demo, regardless of the
    // (possibly test-lowered) WaterLog.INTERVAL_MIN.
    const INTERVAL_MIN = 60;

    var active as Boolean = false;
    var bonusMl as Number = 0;
    var exerting as Boolean = false;
    var place as Number? = null;
    var dayFrac as Float? = null;   // share of the waking day passed
    var hat as Number? = null;      // accessories to show (closet step)
    var other as Number? = null;
    var badges as Number = 0;       // badge bits to show (badges step)

    function resetInputs() as Void {
        bonusMl = 0;
        exerting = false;
        place = null;
        dayFrac = null;
        hat = null;
        other = null;
        badges = 0;
    }
}
