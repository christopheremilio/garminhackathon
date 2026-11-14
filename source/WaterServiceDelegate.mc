import Toybox.Application;
import Toybox.Activity;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Notifications;
import Toybox.System;

// Runs every WaterLog.CHECK_MIN minutes, even when the app is closed.
// In priority order it may post one notification:
//   1. arrival at a saved place (needs a recent GPS fix)
//   2. the hamster's mood dropped (to thirsty, crying or collapsed)
//   3. the regular interval since your last drink is up
// Nothing fires overnight, while snoozed, while the app is open (it has its
// own reminder screen), or more often than the cap.
//
// Toybox.Attention (tones/vibration) isn't available in the background, so
// the notification's sound/vibe comes from the watch's own alert settings.
(:background)
class WaterServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        // Keep today's history record current (goal grows with activity, and
        // a day with no drinks still shows up as missed).
        WaterLog.recordToday();

        var exerting = Hydration.isExerting();
        var place = Places.currentPlace();   // null unless a recent GPS fix exists
        var interval = Hydration.intervalMin(exerting, place);
        var mood = Pet.currentMood();
        var habit = Pet.worstHabit(Pet.scores());
        var dropped = Reminders.moodDropped(mood);   // always updates stored mood

        // App is open: its own reminder screen handles this, so don't post a
        // system notification over it.
        if (WaterLog.foregroundActive()) {
            Background.exit(null);
            return;
        }
        var quiet = WaterLog.isQuietHours() || WaterLog.isSnoozed();

        // 1. Arrival at a saved place.
        var arrived = Places.checkArrival();
        if (arrived != null && !WaterLog.isSnoozed() && Hydration.arrivalReminderAllowed()) {
            var msg = Hydration.arrivalMessage(arrived);
            notify(msg[0], msg[1]);
        } else if (!quiet && dropped && WaterLog.reminderCapPassed(interval)) {
            // 2. Mood got worse.
            notify(Reminders.moodTitle(mood, habit), Reminders.moodBody(mood, habit));
        } else if (WaterLog.shouldNotify(interval)) {
            // 3. Regular reminder.
            var body;
            if (!exerting && place == Places.GYM) {
                body = Lang.format(
                    Application.loadResource(Rez.Strings.NotifyBodyGym) as String,
                    [Units.amount(Hydration.GYM_DRINK_ML)]);
            } else if (exerting) {
                body = Lang.format(
                    Application.loadResource(Rez.Strings.NotifyBodyExertion) as String,
                    [Units.amount(Hydration.EXERTION_DRINK_ML)]);
            } else {
                body = Lang.format(
                    Application.loadResource(Rez.Strings.NotifyBody) as String,
                    [Units.pair(WaterLog.getMl(), Hydration.goalMl())]);
            }
            notify(Reminders.moodTitle(mood, Pet.HABIT_WATER), body);
        }
        Background.exit(null);
    }

    // A recorded workout just ended: nudge for 2 glasses right away (unless
    // the app is open or it's night), and suggest them in-app for an hour.
    function onActivityCompleted(activity as { :sport as Activity.Sport, :subSport as Activity.SubSport }) as Void {
        Hydration.markWorkoutEnded();
        if (!WaterLog.foregroundActive() && !WaterLog.isQuietHours()) {
            notify(Application.loadResource(Rez.Strings.WorkoutTitle) as String,
                   Lang.format(Application.loadResource(Rez.Strings.WorkoutBody) as String,
                               [Units.amount(Hydration.WORKOUT_DRINK_ML)]));
        }
        Background.exit(null);
    }

    // Post a "Drink water" notification with "+250" and "Snooze" actions.
    private function notify(subtitle as String, body as String) as Void {
        var options = {
            :body => body,
            // When the notification was posted; used as the drink time
            // for "+250" and the start of a snooze.
            :data => WaterLog.nowSec(),
            :dismissPrevious => true,
            :actions => [
                { :label => "+" + Units.amount(Units.defaultAddMl()),
                  :data => WaterLog.ACTION_DRANK },
                { :label => Application.loadResource(Rez.Strings.Snooze) as String,
                  :data => WaterLog.ACTION_SNOOZE }
            ] as Array<Notifications.Action>
        };
        Notifications.showNotification(Rez.Strings.NotifyTitle, subtitle, options);
        WaterLog.markReminded();
    }
}
