import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Notifications;
import Toybox.System;

// Runs every WaterLog.CHECK_MIN minutes, even when the app is closed, and
// posts a watch notification when it's time to drink.
(:background)
class WaterServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        if (WaterLog.shouldNotify()) {
            var count = WaterLog.getCount();
            var body = Lang.format(
                Application.loadResource(Rez.Strings.NotifyBody) as String,
                [count, WaterLog.GOAL_GLASSES]);

            var options = {
                :body => body,
                // When the notification was posted; used as the drink time
                // if the user taps "+1 glass".
                :data => WaterLog.nowSec(),
                :dismissPrevious => true,
                :actions => [
                    { :label => Application.loadResource(Rez.Strings.NotifyAction) as String,
                      :data => WaterLog.ACTION_DRANK }
                ] as Array<Notifications.Action>
            };
            Notifications.showNotification(Rez.Strings.NotifyTitle, Rez.Strings.NotifySubtitle, options);
            WaterLog.markReminded();
        }
        Background.exit(null);
    }
}
