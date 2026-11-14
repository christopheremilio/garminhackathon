import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// First-launch questions, one screen each, in the design's black style:
//   1 of 3  Name your hamster   pick from a list or type (NamePrompt.mc)
//   2 of 3  How old are you?    UP/DOWN change, START next
//   3 of 3  You are...          Female / Male / Other / Prefer not to say
// BACK skips a question (keeps the default / Garmin profile value) and moves
// on. The age and gender screens are also opened from Settings, where they
// just return to the menu.
module Onboarding {

    function start() as Void {
        showNameMenu();
    }

    // Step 2.
    function toAge() as Void {
        var view = new AgeView(true, null);
        WatchUi.switchToView(view, new AgeDelegate(view), WatchUi.SLIDE_LEFT);
    }

    // Step 3 (replaces the current screen) or from Settings (pushed).
    function genderMenu(onboarding as Boolean, menuItem as WatchUi.MenuItem?) as Void {
        var title = onboarding ? Rez.Strings.GenderQuestionStep : Rez.Strings.GenderItem;
        var m = new WatchUi.Menu2({ :title => title });
        var ids = [Rez.Strings.GenderFemale, Rez.Strings.GenderMale, Rez.Strings.GenderOther, Rez.Strings.GenderUnsaid];
        for (var i = 0; i < ids.size(); i++) {
            m.addItem(new WatchUi.MenuItem(ids[i], null, i, {}));
        }
        m.setFocus(Prefs.gender());
        var d = new GenderDelegate(onboarding, menuItem);
        if (onboarding) {
            WatchUi.switchToView(m, d, WatchUi.SLIDE_LEFT);
        } else {
            WatchUi.pushView(m, d, WatchUi.SLIDE_LEFT);
        }
    }

    // All three answered (or skipped): back to the hamster.
    function finish() as Void {
        Prefs.setOnboarded();
        Pet.markFirstDay();
        WaterLog.startClock();      // no instant "drink now!" for a brand-new user
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        Screen.changed();
    }

    function genderLabel(g as Number) as String {
        var ids = [Rez.Strings.GenderFemale, Rez.Strings.GenderMale, Rez.Strings.GenderOther, Rez.Strings.GenderUnsaid];
        return WatchUi.loadResource(ids[g]) as String;
    }

    function ageLabel() as String {
        var a = Prefs.age();
        return a != null ? a.format("%d") : WatchUi.loadResource(Rez.Strings.NotSet) as String;
    }

    function stepLabel(n as Number) as String {
        return Lang.format(WatchUi.loadResource(Rez.Strings.StepOf) as String, [n, 3]);
    }
}

class AgeView extends WatchUi.View {

    var age as Number;
    var onboarding as Boolean;
    var menuItem as WatchUi.MenuItem?;

    function initialize(isOnboarding as Boolean, item as WatchUi.MenuItem?) {
        View.initialize();
        onboarding = isOnboarding;
        menuItem = item;
        var a = Prefs.age();
        age = a != null ? a : Prefs.DEFAULT_AGE;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Scenes.BLACK, Scenes.BLACK);
        dc.clear();
        if (onboarding) {
            Scenes.txt(dc, 130, 30, Graphics.FONT_XTINY, Onboarding.stepLabel(2), Scenes.GREY);
        }
        HamsterArt.draw(dc, 130, 66, 0.5, Pet.MOOD_ON_TRACK, HamsterArt.ACC_NONE, HamsterArt.ACC_NONE,
                        0.5, false, System.getTimer(), HamsterArt.REACT_NONE, 0);
        Scenes.txt(dc, 130, 118, Graphics.FONT_XTINY,
                   WatchUi.loadResource(Rez.Strings.AgeQuestion) as String, Scenes.WHITE);
        dc.setColor(Scenes.WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(80, 136, 100, 48, 8);
        dc.setPenWidth(1);
        Scenes.txt(dc, 130, 160, Graphics.FONT_MEDIUM, age.format("%d"), Scenes.WHITE);
        Scenes.txt(dc, 56, 160, Graphics.FONT_SMALL, "-", Scenes.GREY);
        Scenes.txt(dc, 204, 160, Graphics.FONT_SMALL, "+", Scenes.GREY);
        Scenes.txt(dc, 130, 204, Graphics.FONT_XTINY,
                   WatchUi.loadResource(Rez.Strings.AgeHint) as String, Scenes.GREY);
        Scenes.txt(dc, 130, 226, Graphics.FONT_XTINY,
                   WatchUi.loadResource(onboarding ? Rez.Strings.BackSkip : Rez.Strings.BackCancel) as String,
                   Scenes.GREY);
    }
}

class AgeDelegate extends WatchUi.BehaviorDelegate {

    private var _view as AgeView;

    function initialize(view as AgeView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Boolean {   // UP: older
        if (_view.age < Prefs.MAX_AGE) { _view.age++; }
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {       // DOWN: younger
        if (_view.age > Prefs.MIN_AGE) { _view.age--; }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        Prefs.setAge(_view.age);
        Screen.dirty = true;
        next();
        return true;
    }

    function onBack() as Boolean {
        next();
        return true;
    }

    private function next() as Void {
        if (_view.onboarding) {
            Onboarding.genderMenu(true, null);
        } else {
            var item = _view.menuItem;
            if (item != null) {
                item.setSubLabel(Onboarding.ageLabel());
            }
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}

class GenderDelegate extends WatchUi.Menu2InputDelegate {

    private var _onboarding as Boolean;
    private var _menuItem as WatchUi.MenuItem?;

    function initialize(onboarding as Boolean, menuItem as WatchUi.MenuItem?) {
        Menu2InputDelegate.initialize();
        _onboarding = onboarding;
        _menuItem = menuItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof Number) {
            Prefs.setGender(id);
            Screen.dirty = true;
        }
        done();
    }

    function onBack() as Void {
        done();
    }

    private function done() as Void {
        if (_onboarding) {
            Onboarding.finish();
        } else {
            var item = _menuItem;
            if (item != null) {
                item.setSubLabel(Onboarding.genderLabel(Prefs.gender()));
            }
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}
