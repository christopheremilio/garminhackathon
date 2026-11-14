import Toybox.Application;
import Toybox.Lang;

// Reminder wording, using the hamster's name and mood ("Coco is crying").
// Shared by background notifications and the in-app reminder screen.
(:background)
module Reminders {

    const KEY_REMIND_MOOD = "remindMood";   // mood at the last check

    function fmt(id as ResourceId, args as Array) as String {
        return Lang.format(Application.loadResource(id) as String, args);
    }

    // "<name> is thirsty" etc.
    function moodTitle(mood as Number) as String {
        var n = Prefs.name();
        if (mood == Pet.MOOD_THIRSTY) { return fmt(Rez.Strings.TitleThirsty, [n]); }
        if (mood == Pet.MOOD_LAST_WARNING) { return fmt(Rez.Strings.TitleCrying, [n]); }
        if (mood == Pet.MOOD_COLLAPSED) { return fmt(Rez.Strings.TitleCollapsed, [n]); }
        if (mood == Pet.MOOD_AWAY) { return fmt(Rez.Strings.TitleLeft, [n]); }
        return fmt(Rez.Strings.TitleWantsDrink, [n]);
    }

    function moodBody(mood as Number) as String {
        if (mood == Pet.MOOD_COLLAPSED) {
            return Application.loadResource(Rez.Strings.DrinkToRevive) as String;
        }
        if (mood == Pet.MOOD_AWAY) {
            return fmt(Rez.Strings.BringBack, [Prefs.name()]);
        }
        return Application.loadResource(Rez.Strings.DrinkNowShort) as String;
    }

    // Mood-drop reminder: fire when the hamster gets worse (to thirsty or
    // below) since the last check. Always records the current mood so that
    // recovering and dropping again reminds again.
    function moodDropped(mood as Number) as Boolean {
        var v = Storage.getValue(KEY_REMIND_MOOD);
        var last = v instanceof Number ? v : null;
        Storage.setValue(KEY_REMIND_MOOD, mood);
        var bad = mood == Pet.MOOD_THIRSTY || mood == Pet.MOOD_LAST_WARNING || mood == Pet.MOOD_COLLAPSED
                  || mood == Pet.MOOD_AWAY;
        return bad && (last == null || Pet.isWorse(mood, last));
    }
}
