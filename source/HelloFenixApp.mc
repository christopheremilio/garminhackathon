import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Notifications;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

// Entry point. Runs as the foreground app, as the host for the background
// service that posts drink reminders, and as the glance. Only the glance
// and background code is loaded in those processes, so foreground-only
// setup lives in getInitialView(), not onStart().
(:background, :glance)
class HelloFenixApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Called in every process (app, background, glance): keep it empty.
    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    (:glance, :typecheck(disableBackgroundCheck))
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new HamsterGlanceView()];
    }

    (:typecheck(disableGlanceCheck))
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new WaterServiceDelegate()];
    }

    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        // Register the repeating reminder check once; it survives the app
        // being closed. Seed the demo place preset on first run.
        Places.seedPreset();
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(WaterLog.CHECK_MIN * 60));
        }
        // Post-workout nudge: wake the background when a recorded activity ends.
        if ((Background has :registerForActivityCompletedEvent)
                && !Background.getActivityCompletedEventRegistered()) {
            Background.registerForActivityCompletedEvent();
        }
        // Any "+250" / "Snooze" taps made while the app was closed are
        // delivered here as soon as we register.
        Notifications.registerForNotificationMessages(method(:onNotification));
        return [new HelloFenixView(), new HelloFenixDelegate()];
    }

    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    function onNotification(message as Notifications.NotificationMessage) as Void {
        if (message.type != Notifications.NOTIFICATION_MESSAGE_TYPE_SELECTED) {
            return;
        }
        var action = message.action;
        var data = message.data;
        var postedAt = data instanceof Number ? data : WaterLog.nowSec();
        if (action instanceof Number && action == WaterLog.ACTION_DRANK) {
            WaterLog.add(Units.defaultAddMl(), postedAt);
            Rewards.checkDay(WaterLog.today());
            Screen.changed();
        } else if (action instanceof Number && action == WaterLog.ACTION_SNOOZE) {
            WaterLog.snooze(postedAt);
        }
    }
}

function getApp() as HelloFenixApp {
    return Application.getApp() as HelloFenixApp;
}
