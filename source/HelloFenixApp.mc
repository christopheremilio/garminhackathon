import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Notifications;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

// Entry point. Runs both as the foreground app and as the host for the
// background service that posts drink reminders.
(:background)
class HelloFenixApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Called in both foreground and background processes. Register the
    // repeating reminder check once; it survives the app being closed.
    function onStart(state as Dictionary?) as Void {
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(WaterLog.CHECK_MIN * 60));
        }
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new WaterServiceDelegate()];
    }

    (:typecheck(disableBackgroundCheck))
    function getInitialView() as [Views] or [Views, InputDelegates] {
        // Any "+1 glass" taps made while the app was closed are delivered
        // here as soon as we register.
        Notifications.registerForNotificationMessages(method(:onNotification));
        return [new HelloFenixView(), new HelloFenixDelegate()];
    }

    (:typecheck(disableBackgroundCheck))
    function onNotification(message as Notifications.NotificationMessage) as Void {
        var action = message.action;
        if (message.type == Notifications.NOTIFICATION_MESSAGE_TYPE_SELECTED
                && action instanceof Number && action == WaterLog.ACTION_DRANK) {
            var postedAt = message.data;
            WaterLog.addGlass(postedAt instanceof Number ? postedAt : null);
            WatchUi.requestUpdate();
        }
    }
}

function getApp() as HelloFenixApp {
    return Application.getApp() as HelloFenixApp;
}
