import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// First-launch question 1 of 3: "Name your hamster" (from the design).
// START opens the watch keyboard; BACK skips (the name stays "Mizu").
// Either way it moves on to question 2 (age, see Onboarding.mc).
// Renaming from the menu uses the keyboard directly (showNameKeyboard).
class NamePromptView extends WatchUi.View {

    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        // Back from the keyboard with a name saved: go to the next question.
        // (From a timer, not from inside onShow itself.)
        if (Prefs.nameAsked() && _entered) {
            _timer = new Timer.Timer();
            _timer.start(method(:close), 50, false);
        }
    }

    var _entered as Boolean = false;

    function close() as Void {
        Onboarding.toAge();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Scenes.BLACK, Scenes.BLACK);
        dc.clear();
        Scenes.txt(dc, 130, 22, Graphics.FONT_XTINY, Onboarding.stepLabel(1), Scenes.GREY);
        HamsterArt.draw(dc, 130, 66, 0.7, Pet.MOOD_ON_TRACK, HamsterArt.ACC_NONE, HamsterArt.ACC_NONE, 0.5, false,
                        System.getTimer(), HamsterArt.REACT_NONE, 0);
        Scenes.txt(dc, 130, 140, Graphics.FONT_XTINY,
                   WatchUi.loadResource(Rez.Strings.NameYourHamster) as String, Scenes.WHITE);
        dc.setColor(Scenes.WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(60, 158, 140, 38, 8);
        dc.setPenWidth(1);
        Scenes.txt(dc, 130, 176, Graphics.FONT_XTINY,
                   WatchUi.loadResource(Rez.Strings.NamePressStart) as String, Scenes.GREY);
        Scenes.txt(dc, 130, 218, Graphics.FONT_XTINY,
                   Lang.format(WatchUi.loadResource(Rez.Strings.NameSkip) as String, [Prefs.DEFAULT_NAME]),
                   Scenes.GREY);
    }
}

class NamePromptDelegate extends WatchUi.BehaviorDelegate {

    function initialize(view as NamePromptView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    private var _view as NamePromptView;

    function onSelect() as Boolean {
        _view._entered = true;
        showNameKeyboard("");
        return true;
    }

    function onBack() as Boolean {
        Prefs.skipName();
        Onboarding.toAge();
        return true;
    }
}

class NameKeyboardDelegate extends WatchUi.TextPickerDelegate {

    function initialize() {
        TextPickerDelegate.initialize();
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        Prefs.setName(text);
        Screen.changed();
        return true;
    }
}

function showNamePrompt() as Void {
    var view = new NamePromptView();
    WatchUi.pushView(view, new NamePromptDelegate(view), WatchUi.SLIDE_UP);
}

function showNameKeyboard(initial as String) as Void {
    WatchUi.pushView(new WatchUi.TextPicker(initial), new NameKeyboardDelegate(), WatchUi.SLIDE_LEFT);
}
