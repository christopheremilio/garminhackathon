import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// In-app reminder from the design (red ring, hamster, "+250" / "Snooze"),
// shown when a drink becomes due while the app is open. The hamster jumps
// up and down in anger while the watch buzzes on every landing; after
// ANGRY_FOR_MS it stops jumping but stays cross until you respond.
// START = +250, DOWN = snooze 1 hour, BACK = dismiss.
class ReminderView extends WatchUi.View {

    const ANGRY_FOR_MS = 9000;

    private var _timer as Timer.Timer?;
    private var _start as Number = 0;
    private var _alerted as Boolean = false;
    private var _buzzedAt as Number = 0;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        _start = System.getTimer();
        if (!_alerted) {
            _alerted = true;
            DrinkAlert.angry();
            _buzzedAt = _start;
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), 80, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        var now = System.getTimer();
        // Keep buzzing on every landing while it jumps (vibrate() covers 4).
        if (_alerted && now - _start < ANGRY_FOR_MS - DrinkAlert.ANGRY_BUZZ_SPAN_MS / 2
                && now - _buzzedAt >= DrinkAlert.ANGRY_BUZZ_SPAN_MS) {
            _buzzedAt += DrinkAlert.ANGRY_BUZZ_SPAN_MS;
            DrinkAlert.angryBuzzes();
        }
        if (now - _start > ANGRY_FOR_MS + 500 && _timer != null) {
            _timer.stop();      // done jumping: one last redraw, then idle
            _timer = null;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var mood = Pet.currentMood();
        dc.setColor(Scenes.BLACK, Scenes.BLACK);
        dc.clear();
        dc.setColor(Scenes.RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(8);
        dc.drawCircle(130, 130, 127);
        dc.setPenWidth(1);
        var now = System.getTimer();
        var rt = now - _start;
        var jumping = rt < ANGRY_FOR_MS;
        HamsterArt.draw(dc, 130, 70, 0.7, jumping ? mood : Pet.MOOD_THIRSTY,
                        HamsterArt.ACC_NONE, HamsterArt.ACC_NONE,
                        WaterLog.getMl().toFloat() / Hydration.goalMl(), false,
                        now, jumping ? HamsterArt.REACT_ANGRY : HamsterArt.REACT_NONE, rt);
        Scenes.fitTxt(dc, 130, 140, [Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<Graphics.FontType>,
                      Reminders.moodTitle(mood, Pet.HABIT_WATER), Scenes.WHITE, 200);
        Scenes.txt(dc, 130, 166, Graphics.FONT_XTINY,
                   WatchUi.loadResource(Rez.Strings.DrinkNowShort) as String, Scenes.RED);
        dc.setColor(Scenes.DBLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(44, 186, 82, 34, 8);
        dc.setColor(Scenes.DGREY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(134, 186, 82, 34, 8);
        Scenes.txt(dc, 85, 202, Graphics.FONT_XTINY, "+" + Units.amount(Units.defaultAddMl()), Scenes.WHITE);
        Scenes.txt(dc, 175, 202, Graphics.FONT_XTINY,
                   WatchUi.loadResource(Rez.Strings.Snooze) as String, Scenes.WHITE);
        Scenes.txt(dc, 85, 232, Graphics.FONT_XTINY, "START", Scenes.GREY);
        Scenes.txt(dc, 175, 232, Graphics.FONT_XTINY, "DOWN", Scenes.GREY);
    }
}

class ReminderDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        Actions.logWater(Units.defaultAddMl());
        return true;
    }

    function onNextPage() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        Actions.snooze();
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

function showReminder() as Void {
    WatchUi.pushView(new ReminderView(), new ReminderDelegate(), WatchUi.SLIDE_UP);
}
