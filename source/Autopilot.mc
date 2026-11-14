import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Scripted input replay for testing UI flows in the simulator. On a timer
// it presses buttons, touches and picks menu items by calling the *real*
// input handlers of whatever screen is on top (exactly what the system calls
// on a real press), then checks what happened and prints PASS/FAIL to the
// monkeydo log, ending with a summary line.
//
// It skips only the watch's own step of turning a physical press / swipe into
// that call, and it can't judge looks, animation or vibration.
//
// Turn on with Autopilot.ENABLED (runs once when the app opens, instead of
// the demo). It starts from empty storage, so it wipes the app's data.
module Autopilot {

    const ENABLED = false;
    const STEP_MS = 1300;

    const STEPS = [
        "first launch shows the name list",
        "Type my own... opens the keyboard",
        "typing Coco moves on to the age question",
        "UP twice + START saves age, shows gender",
        "choosing Male finishes on the hamster",
        "START adds 250 ml",
        "hold UP opens the menu",
        "Add water opens quick add",
        "DOWN + START adds 500 ml, back on hamster",
        "hold UP opens the menu",
        "Add water opens quick add",
        "Undo last removes 500 ml, back on hamster",
        "hold UP opens the menu",
        "Settings opens the settings submenu",
        "Wake time steps forward an hour",
        "Back to hamster from a submenu",
        "hold UP opens the menu",
        "Places opens the places submenu",
        "BACK in a submenu returns to the main menu",
        "BACK in the main menu returns to the hamster",
        "hold UP opens the menu",
        "Hamster opens the hamster submenu",
        "Dress up opens the closet",
        "swipe left shows the next item",
        "tap the right arrow shows the next item",
        "tap the middle can't wear a locked item",
        "swipe right shows the previous item",
        "BACK closes the closet to the hamster",
        "tap on the Closet page opens the closet",
        "START wears the unlocked party hat",
        "BACK closes the closet",
        "DOWN goes to the Badges page",
        "DOWN wraps round to Home",
        "a due drink shows the angry reminder",
        "DOWN on the reminder snoozes, back on hamster",
        "hold UP opens the menu",
        "Reset today asks for confirmation",
        "Yes resets today, keeps name and hat",
        "Back to hamster from the main menu",
        "hold UP opens the menu",
        "Hamster opens the hamster submenu",
        "Rename shows the name list",
        "picking Peanut renames, back to the hamster menu",
        "Back to hamster from the hamster menu"
    ];

    var active as Boolean = false;
    var player as AutopilotPlayer? = null;

    function start() as Void {
        active = true;
        player = new AutopilotPlayer();
        (player as AutopilotPlayer).begin();
    }
}

class AutopilotPlayer {

    private var _timer as Timer.Timer = new Timer.Timer();
    private var _step as Number = 0;
    private var _passed as Number = 0;
    private var _failed as Number = 0;
    private var _note as String = "";
    private var _n as Number = 0;          // a remembered number between act and check

    function initialize() {
    }

    function begin() as Void {
        System.println("AUTO start: " + Autopilot.STEPS.size().format("%d") + " steps");
        act(0);
        _timer.start(method(:tick), Autopilot.STEP_MS, true);
    }

    // Check the step just done, then do the next one.
    function tick() as Void {
        var ok = false;
        try {
            ok = check(_step);
        } catch (e) {
            _note = "exception: " + e.getErrorMessage();
        }
        var line = (ok ? "AUTO PASS " : "AUTO FAIL ") + (_step + 1).format("%2d") + " "
                   + (Autopilot.STEPS[_step] as String);
        if (!ok) {
            line += "  [" + _note + "; top=" + topName() + "]";
        }
        System.println(line);
        if (ok) { _passed++; } else { _failed++; }
        _note = "";

        // Stop at the first failure: the next inputs would go to the wrong
        // screen (and could crash the app).
        if (!ok) {
            _timer.stop();
            Autopilot.active = false;
            System.println("AUTO STOPPED after step " + (_step + 1).format("%d") + ": passed="
                           + _passed.format("%d") + " failed=" + _failed.format("%d"));
            return;
        }

        _step++;
        if (_step >= Autopilot.STEPS.size()) {
            _timer.stop();
            Autopilot.active = false;
            System.println("AUTO DONE passed=" + _passed.format("%d") + " failed=" + _failed.format("%d"));
            return;
        }
        try {
            act(_step);
        } catch (e) {
            _note = "act exception: " + e.getErrorMessage();
        }
    }

    // --- helpers ---------------------------------------------------------

    function top() as WatchUi.View? {
        return WatchUi.getCurrentView()[0];
    }

    function del() as WatchUi.InputDelegates? {
        return WatchUi.getCurrentView()[1];
    }

    function topName() as String {
        var v = top();
        if (v instanceof HelloFenixView) { return "hamster"; }
        if (v instanceof QuickAddView) { return "quick add"; }
        if (v instanceof ClosetView) { return "closet"; }
        if (v instanceof ReminderView) { return "reminder"; }
        if (v instanceof NamePromptView) { return "name"; }
        if (v instanceof AgeView) { return "age"; }
        var d = del();
        if (d instanceof MainMenuDelegate) { return "main menu"; }
        if (d instanceof HamsterMenuDelegate) { return "hamster menu"; }
        if (d instanceof PlacesMenuDelegate) { return "places menu"; }
        if (d instanceof SettingsMenuDelegate) { return "settings menu"; }
        if (d instanceof GenderDelegate) { return "gender"; }
        if (d instanceof NameKeyboardDelegate) { return "keyboard"; }
        if (d instanceof NameMenuDelegate) { return "name list"; }
        if (d instanceof ResetConfirmDelegate) { return "reset confirm"; }
        return "other";
    }

    function onHamster() as Boolean {
        return top() instanceof HelloFenixView;
    }

    function want(cond as Boolean, note as String) as Boolean {
        if (!cond && _note.length() == 0) {
            _note = note;
        }
        return cond;
    }

    function item(id as Object) as WatchUi.MenuItem {
        return new WatchUi.MenuItem("autopilot", null, id, {});
    }

    // Main screen buttons / touches.
    function main() as HelloFenixDelegate {
        return del() as HelloFenixDelegate;
    }

    // Pick a menu item on whichever menu is showing.
    function pick(id as Object) as Void {
        (del() as WatchUi.Menu2InputDelegate).onSelect(item(id));
    }

    // BACK as the system would do it: if the handler doesn't take it, the
    // system pops the screen.
    function back() as Void {
        var d = del();
        if (d instanceof WatchUi.Menu2InputDelegate) {
            d.onBack();
        } else if (d instanceof WatchUi.BehaviorDelegate) {
            if (!d.onBack()) {
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            }
        }
    }

    // --- the script --------------------------------------------------------

    function act(i as Number) as Void {
        switch (i) {
            case 0:
                Storage.clearValues();
                Storage.setValue(Prefs.KEY_WAKE, 4);     // awake all day, so
                Storage.setValue(Prefs.KEY_BED, 24);     // reminders can fire
                Screen.page = Screen.PAGE_HOME;
                Onboarding.start();
                break;
            case 1: pick(:type); break;
            case 2:
                (del() as NameKeyboardDelegate).onTextEntered("Coco", true);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);    // the keyboard closes itself
                break;
            case 3: {
                var v = top() as AgeView;
                _n = v.age;
                var d = del() as AgeDelegate;
                d.onPreviousPage();
                d.onPreviousPage();
                d.onSelect();
                break;
            }
            case 4: pick(Prefs.GENDER_MALE); break;
            case 5: main().onSelect(); break;
            case 6: case 9: case 12: case 16: case 20: case 35:
                main().onMenu();
                break;
            case 7: case 10: pick(:add); break;
            case 8: {
                var d = del() as QuickAddDelegate;
                d.onNextPage();          // 250 -> 500
                d.onSelect();
                break;
            }
            case 11: {
                var d = del() as QuickAddDelegate;
                d.onNextPage();          // 250 -> 500
                d.onNextPage();          // -> Undo last
                d.onSelect();
                break;
            }
            case 13: pick(:settings); break;
            case 14:
                _n = Prefs.wakeHour();
                pick(:wake);
                break;
            case 15: pick(:home); break;
            case 17: pick(:places); break;
            case 18: back(); break;
            case 19: back(); break;
            case 21: pick(:hamster); break;
            case 22: pick(:closet); break;
            case 23:
                _n = (top() as ClosetView).item;
                (del() as ClosetDelegate).swipe(WatchUi.SWIPE_LEFT);
                break;
            case 24:
                _n = (top() as ClosetView).item;
                (del() as ClosetDelegate).tapAt(220);
                break;
            case 25:
                _n = (top() as ClosetView).item;
                (del() as ClosetDelegate).tapAt(130);
                break;
            case 26:
                _n = (top() as ClosetView).item;
                (del() as ClosetDelegate).swipe(WatchUi.SWIPE_RIGHT);
                break;
            case 27: back(); break;
            case 28:
                Storage.setValue(Rewards.KEY_GOAL_DAYS, 6);   // 2 items unlocked
                Screen.page = Screen.PAGE_CLOSET;
                main().tap();
                break;
            case 29: (del() as ClosetDelegate).onSelect(); break;
            case 30: back(); break;
            case 31: main().onNextPage(); break;
            case 32: main().onNextPage(); break;
            case 33:
                WaterLog.backdateLastDrink(2 * 3600);
                Storage.deleteValue(WaterLog.KEY_CLOCK_START);
                Screen.changed();
                break;
            case 34: (del() as ReminderDelegate).onNextPage(); break;
            case 36: pick(:reset); break;
            case 37:
                (del() as ResetConfirmDelegate).onResponse(WatchUi.CONFIRM_YES);
                WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);    // the dialog closes itself
                break;
            case 38: pick(:home); break;
            case 39: main().onMenu(); break;
            case 40: pick(:hamster); break;
            case 41: pick(:rename); break;
            case 42: pick(2); break;                     // "Peanut"
            case 43: pick(:home); break;
        }
    }

    function check(i as Number) as Boolean {
        var d = del();
        switch (i) {
            case 0: return want(d instanceof NameMenuDelegate, "name list not shown");
            case 1: return want(d instanceof NameKeyboardDelegate, "keyboard not shown");
            case 2: return want(Prefs.name().equals("Coco"), "name is " + Prefs.name())
                         && want(top() instanceof AgeView, "age screen not shown");
            case 3: {
                var a = Prefs.age();
                return want(a != null && a == _n + 2, "age " + (a == null ? "null" : a.format("%d"))
                                                     + ", expected " + (_n + 2).format("%d"))
                    && want(d instanceof GenderDelegate, "gender menu not shown");
            }
            case 4: return want(Prefs.gender() == Prefs.GENDER_MALE, "gender not saved")
                         && want(Prefs.onboarded(), "not marked onboarded")
                         && want(onHamster(), "not back on hamster");
            case 5: return want(WaterLog.getMl() == 250, "ml=" + WaterLog.getMl().format("%d"));
            case 6: case 9: case 12: case 16: case 20: case 35:
                return want(d instanceof MainMenuDelegate, "main menu not shown");
            case 7: case 10: return want(top() instanceof QuickAddView, "quick add not shown");
            case 8: return want(WaterLog.getMl() == 750, "ml=" + WaterLog.getMl().format("%d"))
                         && want(onHamster(), "not back on hamster");
            case 11: return want(WaterLog.getMl() == 250, "ml=" + WaterLog.getMl().format("%d"))
                          && want(onHamster(), "not back on hamster");
            case 13: return want(d instanceof SettingsMenuDelegate, "settings menu not shown");
            case 14: return want(Prefs.wakeHour() == (_n >= Prefs.WAKE_MAX_HOUR ? Prefs.WAKE_MIN_HOUR : _n + 1),
                                 "wake hour " + Prefs.wakeHour().format("%d"))
                          && want(d instanceof SettingsMenuDelegate, "left settings menu");
            case 15: return want(onHamster(), "not back on hamster");
            case 17: return want(d instanceof PlacesMenuDelegate, "places menu not shown");
            case 18: return want(d instanceof MainMenuDelegate, "not on main menu");
            case 19: return want(onHamster(), "not back on hamster");
            case 21: return want(d instanceof HamsterMenuDelegate, "hamster menu not shown");
            case 22: return want(top() instanceof ClosetView, "closet not shown");
            case 23: case 24:
                return want((top() as ClosetView).item == _n % Rewards.ITEM_COUNT + 1, "item didn't advance");
            case 25:
                return want(!Rewards.isWorn(_n), "wore a locked item")
                    && want(!Rewards.isUnlocked(_n), "item " + _n.format("%d") + " wasn't locked");
            case 26:
                return want((top() as ClosetView).item == (_n + Rewards.ITEM_COUNT - 2) % Rewards.ITEM_COUNT + 1,
                            "item didn't go back");
            case 27: return want(onHamster(), "not back on hamster");
            case 28: return want(top() instanceof ClosetView, "closet not shown");
            case 29: return want(Rewards.wornHat() == HamsterArt.ACC_PARTY_HAT, "party hat not worn");
            case 30: return want(onHamster(), "not back on hamster");
            case 31: return want(Screen.page == Screen.PAGE_BADGES, "page " + Screen.page.format("%d"));
            case 32: return want(Screen.page == Screen.PAGE_HOME, "page " + Screen.page.format("%d"));
            case 33: return want(top() instanceof ReminderView, "reminder not shown");
            case 34: return want(WaterLog.isSnoozed(), "not snoozed")
                          && want(onHamster(), "not back on hamster");
            case 36: return want(d instanceof ResetConfirmDelegate, "no confirmation");
            case 37: return want(WaterLog.getMl() == 0, "ml=" + WaterLog.getMl().format("%d"))
                          && want(Prefs.name().equals("Coco"), "name lost")
                          && want(Rewards.wornHat() == HamsterArt.ACC_PARTY_HAT, "hat lost")
                          && want(d instanceof MainMenuDelegate, "not back on the menu");
            case 38: return want(onHamster(), "not back on hamster");
            case 39: return want(d instanceof MainMenuDelegate, "main menu not shown");
            case 40: return want(d instanceof HamsterMenuDelegate, "hamster menu not shown");
            case 41: return want(d instanceof NameMenuDelegate, "name list not shown");
            case 42: return want(Prefs.name().equals("Peanut"), "name is " + Prefs.name())
                          && want(d instanceof HamsterMenuDelegate, "not back on the hamster menu");
            case 43: return want(onHamster(), "not back on hamster");
        }
        return false;
    }
}
