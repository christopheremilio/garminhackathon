import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Shows glasses drunk today as a segmented ring plus the time until the next
// drink. Buzzes once if a drink becomes due while the app is open.
class HelloFenixView extends WatchUi.View {

    const REFRESH_MS = 30000;

    private var _timer as Timer.Timer?;
    private var _buzzed as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), REFRESH_MS, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;

        var count = WaterLog.getCount();
        var goal = WaterLog.GOAL_GLASSES;
        var reached = count >= goal;
        var due = WaterLog.isDue();
        var accent = reached ? Graphics.COLOR_GREEN : Graphics.COLOR_BLUE;

        // Buzz once each time a drink becomes due while we're on screen.
        if (due && !_buzzed) {
            _buzzed = true;
            if (Attention has :vibrate) {
                Attention.vibrate([new Attention.VibeProfile(75, 400)]);
            }
        } else if (!due) {
            _buzzed = false;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Ring of `goal` segments, filled clockwise from 12 o'clock.
        var radius = (width < height ? width : height) / 2 - 10;
        var seg = 360 / goal;
        var gap = 4;
        dc.setPenWidth(12);
        for (var i = 0; i < goal; i++) {
            var start = 90 - i * seg - gap / 2;
            var end = 90 - (i + 1) * seg + gap / 2;
            dc.setColor(i < count ? accent : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, start, end);
        }
        dc.setPenWidth(1);

        // Label
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 82, Graphics.FONT_SMALL,
                    Rez.Strings.WaterLabel, Graphics.TEXT_JUSTIFY_CENTER);

        // Glasses count
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 34, Graphics.FONT_NUMBER_HOT,
                    count.format("%d") + "/" + goal.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Volume
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 42, Graphics.FONT_TINY,
                    (count * WaterLog.GLASS_ML).format("%d") + " / "
                        + (goal * WaterLog.GLASS_ML).format("%d") + " ml",
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Status line
        var status;
        var statusColor = Graphics.COLOR_LT_GRAY;
        if (reached) {
            status = WatchUi.loadResource(Rez.Strings.GoalReached) as String;
            statusColor = Graphics.COLOR_GREEN;
        } else if (WaterLog.isQuietHours()) {
            status = WatchUi.loadResource(Rez.Strings.QuietHours) as String;
        } else if (due) {
            status = WatchUi.loadResource(Rez.Strings.DrinkNow) as String;
            statusColor = Graphics.COLOR_BLUE;
        } else {
            var mins = (WaterLog.secondsUntilDue() + 59) / 60;
            status = Lang.format(WatchUi.loadResource(Rez.Strings.NextIn) as String, [mins]);
        }
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 72, Graphics.FONT_XTINY, status, Graphics.TEXT_JUSTIFY_CENTER);

        // Button hint
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 96, Graphics.FONT_XTINY,
                    Rez.Strings.Hint, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
