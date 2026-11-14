import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Glance (the watch's scrolling list of widgets): the hamster's face, its
// name, today's water and a bar. Glances run in a separate, memory-limited
// process, so this only reads the summary WaterLog.saveGlance() stores.
(:glance)
class HamsterGlanceView extends WatchUi.GlanceView {

    // Mirrors Pet's mood enum (Pet isn't loaded in the glance).
    const SLEEPING = 0;
    const HYDRATED = 1;
    const ON_TRACK = 2;
    const THIRSTY = 3;
    const LAST_WARNING = 4;
    const COLLAPSED = 5;

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var h = dc.getHeight();
        var w = dc.getWidth();
        var name = "Mizu";
        var label = "";
        var fill = 0;
        var mood = ON_TRACK;
        var v = Storage.getValue("glance");
        if (v instanceof Array && v.size() >= 6) {
            var a = v as Array;
            var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var today = (info.year as Number) * 10000 + (info.month as Number) * 100 + (info.day as Number);
            var fresh = a[0] == today;
            name = a[4] as String;
            label = (fresh ? a[1] : a[2]) as String;
            fill = fresh ? a[3] as Number : 0;
            mood = fresh ? a[5] as Number : ON_TRACK;
        }

        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        var r = h * 3 / 10;
        drawFace(dc, r + 4, h / 2, r, mood);

        var tx = 2 * r + 14;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(tx, h / 2 - 2, Graphics.FONT_GLANCE, name + "  " + label,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        var bw = w - tx - 8;
        if (bw > 20) {
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(tx, h / 2 + 12, bw, 6, 3);
            if (fill > 0) {
                dc.setColor(0x00AAFF, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(tx, h / 2 + 12, bw * fill / 100 < 6 ? 6 : bw * fill / 100, 6, 3);
            }
        }
    }

    // Simplified hamster face.
    function drawFace(dc as Dc, x as Number, y as Number, r as Number, mood as Number) as Void {
        var e = r / 3;
        dc.setColor(0x550000, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - r * 2 / 3, y - r * 2 / 3, r / 3 + 1);
        dc.fillCircle(x + r * 2 / 3, y - r * 2 / 3, r / 3 + 1);
        dc.fillEllipse(x, y, r + 1, r * 9 / 10 + 1);
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - r * 2 / 3, y - r * 2 / 3, r / 3);
        dc.fillCircle(x + r * 2 / 3, y - r * 2 / 3, r / 3);
        dc.setColor(0xFFFFAA, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(x, y, r, r * 9 / 10);
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(x, y - r * 6 / 10, r / 2, r / 5);
        dc.setColor(0xFFAAAA, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - r * 7 / 10, y + r / 4, r / 5);
        dc.fillCircle(x + r * 7 / 10, y + r / 4, r / 5);

        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var ex = [x - e, x + e];
        for (var i = 0; i < 2; i++) {
            var cx = ex[i];
            if (mood == HYDRATED) {
                dc.drawArc(cx, y, r / 7 + 1, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
            } else if (mood == SLEEPING) {
                dc.drawLine(cx - 3, y - 1, cx + 3, y - 1);
            } else if (mood == COLLAPSED) {
                dc.drawLine(cx - 3, y - 4, cx + 3, y + 2);
                dc.drawLine(cx - 3, y + 2, cx + 3, y - 4);
            } else {
                dc.fillCircle(cx, y - 1, mood == ON_TRACK ? 2 : 3);
            }
        }
        if (mood == THIRSTY || mood == LAST_WARNING) {
            dc.setColor(0x55AAFF, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x + r - 2, y - r / 3, 3);
        }
        dc.setPenWidth(1);
    }
}
