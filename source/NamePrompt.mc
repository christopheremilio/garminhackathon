import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Naming the hamster, made quick: pick one of the suggested names with a
// single press, or "Type my own..." for the watch keyboard.
//
//   First launch (question 1 of 3): the list replaces itself with the age
//   question once a name is picked; BACK skips (keeps "Coco").
//   Rename (Hamster > Rename): same list with the current name on top;
//   picking returns to the Hamster menu.
module Names {

    const SUGGESTED = ["Coco", "Mizu", "Peanut", "Mochi", "Biscuit",
                       "Nibbles", "Pip", "Hazel", "Waffles", "Bubbles"];

    var entered as Boolean = false;     // set when the keyboard saves a name

    function menu(onboarding as Boolean) as WatchUi.Menu2 {
        var m = new WatchUi.Menu2({ :title => onboarding ? Rez.Strings.NameStepTitle : Rez.Strings.RenameHamster });
        var current = Prefs.name();
        var focus = 0;
        var offset = 0;
        if (!onboarding && SUGGESTED.indexOf(current) < 0) {
            m.addItem(new WatchUi.MenuItem(current, Rez.Strings.CurrentName, :current, {}));
            offset = 1;
        }
        for (var i = 0; i < SUGGESTED.size(); i++) {
            var n = SUGGESTED[i] as String;
            var sub = (!onboarding && n.equals(current)) ? Rez.Strings.CurrentName : null;
            m.addItem(new WatchUi.MenuItem(n, sub, i, {}));
            if (n.equals(current)) { focus = i + offset; }
        }
        m.addItem(new WatchUi.MenuItem(Rez.Strings.TypeMyOwn, null, :type, {}));
        m.setFocus(focus);
        return m;
    }
}

// First launch.
function showNameMenu() as Void {
    WatchUi.pushView(Names.menu(true), new NameMenuDelegate(true), WatchUi.SLIDE_UP);
}

// From the Hamster menu.
function showRenameMenu() as Void {
    WatchUi.pushView(Names.menu(false), new NameMenuDelegate(false), WatchUi.SLIDE_LEFT);
}

class NameMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _onboarding as Boolean;

    function initialize(onboarding as Boolean) {
        Menu2InputDelegate.initialize();
        _onboarding = onboarding;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof Number) {
            Prefs.setName(Names.SUGGESTED[id] as String);
            done();
        } else if (id == :current) {
            done();
        } else if (id == :type) {
            if (_onboarding) {
                // Keyboard host screen: opens the keyboard straight away, then
                // moves on to the age question once a name is saved.
                var v = new NamePromptView(true);
                WatchUi.switchToView(v, new NamePromptDelegate(v), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
                showNameKeyboard(Prefs.name());
            }
        }
    }

    function onBack() as Void {
        if (_onboarding) {
            Prefs.skipName();
            Onboarding.toAge();
        } else {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }

    private function done() as Void {
        Screen.changed();
        if (_onboarding) {
            Onboarding.toAge();
        } else {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}

// Hosts the keyboard during first launch ("Type my own..."). Opens it right
// away; once a name is saved, moves on to the age question. If the keyboard
// is cancelled it shows the design's "Name your hamster" screen: START to try
// again, BACK to skip.
class NamePromptView extends WatchUi.View {

    private var _timer as Timer.Timer?;
    private var _autoKeyboard as Boolean;
    var _entered as Boolean = false;     // keyboard has been opened

    function initialize(autoKeyboard as Boolean) {
        View.initialize();
        _autoKeyboard = autoKeyboard;
    }

    function onShow() as Void {
        // (Screens are opened from a timer, not from inside onShow itself.)
        if (_autoKeyboard && !_entered) {
            _entered = true;
            Names.entered = false;
            _timer = new Timer.Timer();
            _timer.start(method(:openKeyboard), 50, false);
        } else if (_entered && Names.entered) {
            _timer = new Timer.Timer();
            _timer.start(method(:close), 50, false);
        }
    }

    function openKeyboard() as Void {
        showNameKeyboard("");
    }

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

    private var _view as NamePromptView;

    function initialize(view as NamePromptView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view._entered = true;
        Names.entered = false;
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
        Names.entered = true;
        Screen.changed();
        return true;
    }
}

function showNameKeyboard(initial as String) as Void {
    WatchUi.pushView(new WatchUi.TextPicker(initial), new NameKeyboardDelegate(), WatchUi.SLIDE_LEFT);
}
