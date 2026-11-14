import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Time;

// Saved places (Home / Gym / Work / Other) and "where am I?" matching.
// Habit-agnostic: each habit decides what a place means for it (see
// Hydration.placeIntervalMin()). Shared by foreground and background.
//
// Background services can't turn on GPS; Position.getInfo() there returns the
// last known fix. currentPlace() only trusts a fix that is recent, so in the
// background it works when GPS has been used lately (the app was opened, an
// activity was recorded) and otherwise falls back to "unknown".
(:background)
module Places {

    enum {
        HOME = 0,
        GYM = 1,
        WORK = 2,
        OTHER = 3
    }
    const COUNT = 4;

    const RADIUS_M = 150;          // "at a place" = within this distance
    const MAX_FIX_AGE_SEC = 900;   // trust fixes up to 15 min old

    // Last place we saw you at (-1 = away from all saved places). Used to
    // detect arrivals.
    const KEY_LAST_PLACE = "lastPlace";
    const AWAY = -1;

    // Demo preset: Platform Calgary (407 9 Ave SE), saved as Work the first
    // time the app runs. Coordinates from OpenStreetMap. Re-saving Work or
    // "Forget places" replaces/removes it. Set PRESET_ENABLED = false to skip.
    const PRESET_ENABLED = true;
    const PRESET_PLACE = WORK;
    const PRESET_LAT = 51.0441750d;
    const PRESET_LON = -114.0553551d;
    const KEY_PRESET_DONE = "presetDone";

    // Simulated GPS for the simulator / demos: pretend we're always standing
    // at PRESET_LAT/LON (Platform Calgary). Saving a place stores that point
    // instantly and "where am I?" uses it. Set false on a real watch.
    const FAKE_GPS = true;

    function key(place as Number) as String {
        return "place" + place.toString();
    }

    // [latDeg, lonDeg, quality] or null if not saved.
    function get(place as Number) as Array<Numeric>? {
        var v = Storage.getValue(key(place));
        return v instanceof Array ? v as Array<Numeric> : null;
    }

    function isSaved(place as Number) as Boolean {
        return get(place) != null;
    }

    function anySaved() as Boolean {
        for (var i = 0; i < COUNT; i++) {
            if (isSaved(i)) {
                return true;
            }
        }
        return false;
    }

    function save(place as Number, latDeg as Double, lonDeg as Double, quality as Number) as Void {
        Storage.setValue(key(place), [latDeg, lonDeg, quality]);
        // You're standing here now, so this isn't an "arrival".
        Storage.setValue(KEY_LAST_PLACE, place);
    }

    // Forget where we last saw you, so the next check can count as an arrival.
    function clearLastPlace() as Void {
        Storage.deleteValue(KEY_LAST_PLACE);
    }

    // Save the demo preset once (only if that place isn't already saved).
    // Doesn't touch the last-place state, so arriving there still counts.
    function seedPreset() as Void {
        if (!PRESET_ENABLED || Storage.getValue(KEY_PRESET_DONE) != null) {
            return;
        }
        if (!isSaved(PRESET_PLACE)) {
            Storage.setValue(key(PRESET_PLACE), [PRESET_LAT, PRESET_LON, Position.QUALITY_GOOD]);
        }
        Storage.setValue(KEY_PRESET_DONE, true);
    }

    function forgetAll() as Void {
        for (var i = 0; i < COUNT; i++) {
            Storage.deleteValue(key(i));
        }
        Storage.deleteValue(KEY_LAST_PLACE);
    }

    // Distance in metres (equirectangular approximation: accurate to well
    // under a metre at the ~150 m scale we care about).
    function distanceM(lat1 as Numeric, lon1 as Numeric, lat2 as Numeric, lon2 as Numeric) as Float {
        var toRad = Math.PI / 180.0;
        var x = (lon2 - lon1) * toRad * Math.cos((lat1 + lat2) / 2.0 * toRad);
        var y = (lat2 - lat1) * toRad;
        return (Math.sqrt(x * x + y * y) * 6371000.0).toFloat();
    }

    // Nearest saved place within RADIUS_M of the given point, or null.
    function placeAt(latDeg as Numeric, lonDeg as Numeric) as Number? {
        var best = null;
        var bestDist = RADIUS_M.toFloat();
        for (var i = 0; i < COUNT; i++) {
            var p = get(i);
            if (p != null && p.size() >= 2) {
                var d = distanceM(latDeg, lonDeg, p[0], p[1]);
                if (d <= bestDist) {
                    best = i;
                    bestDist = d;
                }
            }
        }
        return best;
    }

    // A recent, usable fix as [latDeg, lonDeg], or null.
    function freshFix() as Array<Double>? {
        if (FAKE_GPS) {
            return [PRESET_LAT, PRESET_LON];
        }
        var info = Position.getInfo();
        var pos = info.position;
        var when = info.when;
        if (pos == null || when == null || info.accuracy < Position.QUALITY_POOR) {
            return null;
        }
        if (Time.now().value() - when.value() > MAX_FIX_AGE_SEC) {
            return null;
        }
        return pos.toDegrees();
    }

    // Where the user is now: a saved place id, or null if elsewhere/unknown.
    function currentPlace() as Number? {
        if (Demo.active) {
            return Demo.place;
        }
        if (!anySaved()) {
            return null;
        }
        var fix = freshFix();
        return fix != null ? placeAt(fix[0], fix[1]) : null;
    }

    // Call with each new look at your location. Returns the saved place you
    // just arrived at (were away from it last time, are at it now), else null.
    // With no fresh fix nothing changes, so a gap in GPS doesn't count as
    // leaving and coming back.
    function checkArrival() as Number? {
        if (!anySaved()) {
            return null;
        }
        var fix = freshFix();
        if (fix == null) {
            return null;
        }
        var place = placeAt(fix[0], fix[1]);
        var now = place != null ? place : AWAY;
        var stored = Storage.getValue(KEY_LAST_PLACE);
        var prev = stored instanceof Number ? stored : null;
        Storage.setValue(KEY_LAST_PLACE, now);
        return (place != null && prev != now) ? place : null;
    }
}
