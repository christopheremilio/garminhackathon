import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Daily step tracker. Reads today's step count from ActivityMonitor
// (Sensor.SensorData only exposes raw accel/gyro/HR/mag samples, not steps)
// and draws progress toward a fixed 10,000-step goal.
class HelloFenixView extends WatchUi.View {

    const STEP_GOAL = 10000;
    const REFRESH_MS = 5000;

    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    // Start polling while the view is visible.
    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), REFRESH_MS, true);
    }

    // Stop polling when hidden to save battery.
    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    // Steps since local midnight, or 0 if the device has no value yet.
    private function getSteps() as Number {
        var steps = ActivityMonitor.getInfo().steps;
        return steps != null ? steps : 0;
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var cx = width / 2;
        var cy = height / 2;

        var steps = getSteps();
        var fraction = steps.toFloat() / STEP_GOAL;
        var reached = steps >= STEP_GOAL;
        var accent = reached ? Graphics.COLOR_GREEN : Graphics.COLOR_YELLOW;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Progress ring: dark track, then the filled arc clockwise from 12 o'clock.
        var radius = (width < height ? width : height) / 2 - 10;
        var penWidth = 12;
        dc.setPenWidth(penWidth);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, radius);

        if (fraction > 0) {
            dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
            if (fraction >= 1.0) {
                dc.drawCircle(cx, cy, radius);
            } else {
                var sweep = (fraction * 360).toNumber();
                if (sweep < 1) {
                    sweep = 1;
                }
                dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, 90, 90 - sweep);
            }
        }
        dc.setPenWidth(1);

        // Label
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 78, Graphics.FONT_SMALL,
                    Rez.Strings.StepsLabel,
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Step count
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 30, Graphics.FONT_NUMBER_HOT,
                    steps.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Goal / percent / remaining
        var percent = (fraction * 100).toNumber();
        var detail;
        if (reached) {
            detail = WatchUi.loadResource(Rez.Strings.GoalReached) as String;
        } else {
            detail = (STEP_GOAL - steps).format("%d") + " "
                   + (WatchUi.loadResource(Rez.Strings.ToGo) as String);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 50, Graphics.FONT_TINY,
                    percent.format("%d") + "% of 10,000",
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 80, Graphics.FONT_XTINY,
                    detail,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }
}
