import Toybox.Lang;
import Toybox.WatchUi;

// Hold-UP menu, organised into submenus:
//
//   Menu
//     Add water          -> quick-add screen (1/2, 1, 2 glasses, undo)
//     Hamster    >       Rename, Dress up
//     Places     >       Save as Home / Gym / Work / Other, Forget places
//     Settings   >       Wake time, Bed time, Age, Gender, Weight
//     Reset today
//     Back to hamster
//
// Getting back: every menu ends with "Back to hamster", which returns to the
// main screen in one press. Submenus replace the main menu rather than
// stacking on it, so the menu is never more than one level above the
// hamster; BACK in a submenu returns to a freshly built main menu, BACK in
// the main menu returns to the hamster. Actions that finish somewhere (add
// water, dress up, save a place) also end on the hamster.

module Menus {

    function str(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }

    function item(label as ResourceId or String, sub as ResourceId or String or Null, id as Object) as WatchUi.MenuItem {
        return new WatchUi.MenuItem(label, sub, id, {});
    }

    function backItem() as WatchUi.MenuItem {
        return item(Rez.Strings.BackToHamster, null, :home);
    }

    function placesSummary() as String {
        var n = 0;
        for (var i = 0; i < Places.COUNT; i++) {
            if (Places.isSaved(i)) { n++; }
        }
        return Lang.format(str(Rez.Strings.PlacesSavedCount), [n, Places.COUNT]);
    }

    function settingsSummary() as String {
        return Prefs.hourLabel(Prefs.wakeHour()) + "-" + Prefs.hourLabel(Prefs.bedHour());
    }

    function mainMenu() as WatchUi.Menu2 {
        var m = new WatchUi.Menu2({ :title => Rez.Strings.MenuTitle });
        m.addItem(item(Rez.Strings.AddWaterTitle, Rez.Strings.AddWaterSub, :add));
        m.addItem(item(Rez.Strings.MenuHamster, Prefs.name(), :hamster));
        m.addItem(item(Rez.Strings.MenuPlaces, placesSummary(), :places));
        m.addItem(item(Rez.Strings.MenuSettings, settingsSummary(), :settings));
        m.addItem(item(Rez.Strings.ResetToday, null, :reset));
        m.addItem(backItem());
        return m;
    }

    function hamsterMenu() as WatchUi.Menu2 {
        var m = new WatchUi.Menu2({ :title => Rez.Strings.MenuHamster });
        m.addItem(item(Rez.Strings.RenameHamster, Prefs.name(), :rename));
        m.addItem(item(Rez.Strings.DressUp,
                       Lang.format(str(Rez.Strings.UnlockedOf), [Rewards.unlockedCount(), Rewards.ITEM_COUNT]),
                       :closet));
        m.addItem(backItem());
        return m;
    }

    function placesMenu() as WatchUi.Menu2 {
        var m = new WatchUi.Menu2({ :title => Rez.Strings.MenuPlaces });
        var saveFmt = str(Rez.Strings.SaveAs);
        for (var i = 0; i < Places.COUNT; i++) {
            m.addItem(item(Lang.format(saveFmt, [placeName(i)]),
                           Places.isSaved(i) ? Rez.Strings.Saved : Rez.Strings.NotSet, i));
        }
        m.addItem(item(Rez.Strings.ForgetPlaces, null, :forget));
        m.addItem(backItem());
        return m;
    }

    function settingsMenu() as WatchUi.Menu2 {
        var m = new WatchUi.Menu2({ :title => Rez.Strings.MenuSettings });
        m.addItem(item(Rez.Strings.WakeTime, Prefs.hourLabel(Prefs.wakeHour()), :wake));
        m.addItem(item(Rez.Strings.BedTime, Prefs.hourLabel(Prefs.bedHour()), :bed));
        m.addItem(item(Rez.Strings.AgeItem, Onboarding.ageLabel(), :age));
        m.addItem(item(Rez.Strings.GenderItem, Onboarding.genderLabel(Prefs.gender()), :gender));
        m.addItem(item(Rez.Strings.WeightItem, Onboarding.weightLabel(), :weight));
        m.addItem(backItem());
        return m;
    }

    // From the main screen.
    function show() as Void {
        WatchUi.pushView(mainMenu(), new MainMenuDelegate(), WatchUi.SLIDE_UP);
    }

    // Replace whatever menu is showing with the main menu.
    function backToMain() as Void {
        WatchUi.switchToView(mainMenu(), new MainMenuDelegate(), WatchUi.SLIDE_RIGHT);
    }

    // Close the menu and return to the hamster.
    function home() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        Screen.changed();
    }

    function confirm(message as ResourceId, delegate as WatchUi.ConfirmationDelegate) as Void {
        WatchUi.pushView(new WatchUi.Confirmation(str(message)), delegate, WatchUi.SLIDE_IMMEDIATE);
    }
}

// Kept for existing callers.
function showMainMenu() as Void {
    Menus.show();
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :add) {
            var qa = new QuickAddView();
            WatchUi.switchToView(qa, new QuickAddDelegate(qa), WatchUi.SLIDE_LEFT);
        } else if (id == :hamster) {
            WatchUi.switchToView(Menus.hamsterMenu(), new HamsterMenuDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :places) {
            WatchUi.switchToView(Menus.placesMenu(), new PlacesMenuDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :settings) {
            WatchUi.switchToView(Menus.settingsMenu(), new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :reset) {
            Menus.confirm(Rez.Strings.ResetConfirm, new ResetConfirmDelegate());
        } else if (id == :home) {
            Menus.home();
        }
    }

    function onBack() as Void {
        Menus.home();
    }
}

class HamsterMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :rename) {
            showRenameMenu();
        } else if (id == :closet) {
            // Replace the menu so closing the closet returns to the hamster.
            var view = new ClosetView();
            WatchUi.switchToView(view, new ClosetDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (id == :home) {
            Menus.home();
        }
    }

    function onBack() as Void {
        Menus.backToMain();
    }
}

class PlacesMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof Number) {
            // Replace the menu so finishing the save returns to the hamster.
            WatchUi.switchToView(new SavePlaceView(id), new SavePlaceDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :forget) {
            Menus.confirm(Rez.Strings.ForgetConfirm, new ForgetPlacesConfirmDelegate());
        } else if (id == :home) {
            Menus.home();
        }
    }

    function onBack() as Void {
        Menus.backToMain();
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :wake) {
            item.setSubLabel(Prefs.hourLabel(Prefs.cycleWake()));
        } else if (id == :bed) {
            item.setSubLabel(Prefs.hourLabel(Prefs.cycleBed()));
        } else if (id == :age) {
            var view = new AgeView(false, item);
            WatchUi.pushView(view, new AgeDelegate(view), WatchUi.SLIDE_LEFT);
            return;
        } else if (id == :gender) {
            Onboarding.genderMenu(false, item);
            return;
        } else if (id == :weight) {
            var wv = new WeightView(false, item);
            WatchUi.pushView(wv, new WeightDelegate(wv), WatchUi.SLIDE_LEFT);
            return;
        } else if (id == :home) {
            Menus.home();
            return;
        }
        Screen.dirty = true;
        WatchUi.requestUpdate();
    }

    function onBack() as Void {
        Menus.backToMain();
    }
}
