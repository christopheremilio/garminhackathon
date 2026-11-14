import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Closet from the design: browse all 12 accessories with "<" ">", preview
// each on the hamster (locked ones too, so you can see what's coming), and
// wear one hat plus one other item.
//   Browse:  UP/DOWN, swipe left/right, or tap the < > arrows
//   Wear:    START or tap the middle (puts it on / takes it off)
//   Close:   BACK
// Locked items are marked "Locked" with the goal days that unlock them.
class ClosetView extends WatchUi.View {

    var item as Number = 1;

    function initialize() {
        View.initialize();
        // Start on something worn, else the first item.
        var w = Rewards.worn();
        item = w[0] != HamsterArt.ACC_NONE ? w[0] : (w[1] != HamsterArt.ACC_NONE ? w[1] : 1);
    }

    function onUpdate(dc as Dc) as Void {
        var unlocked = Rewards.isUnlocked(item);
        Scenes.room(dc, Scenes.CLOSET_WALL, Scenes.CLOSET_FLOOR, -1.0, false, false);
        Scenes.txt(dc, 130, 28, Graphics.FONT_TINY, WatchUi.loadResource(Rez.Strings.ClosetTitle) as String,
                   Scenes.BLACK);

        // Preview: this item in its slot (even if still locked), the other
        // slot as currently worn.
        var hat = Rewards.worn()[0];
        var other = Rewards.worn()[1];
        if (Rewards.isHat(item)) { hat = item; } else { other = item; }
        if (other == HamsterArt.ACC_PLANT) {
            HamsterArt.plant(dc, 200, 196);
            other = HamsterArt.ACC_NONE;
        }
        HamsterArt.draw(dc, 130, 124, 1.1, unlocked ? Pet.MOOD_HYDRATED : Pet.MOOD_ON_TRACK,
                        hat, other, 0.6, false, System.getTimer(), HamsterArt.REACT_NONE, 0);
        if (!unlocked) {
            // padlock badge
            dc.setColor(Scenes.DGREY, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(30, 64, 68, 22, 6);
            Scenes.txt(dc, 64, 75, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.Locked) as String,
                       Scenes.WHITE);
        }
        Scenes.txt(dc, 34, 124, Graphics.FONT_MEDIUM, "<", Scenes.BLACK);
        Scenes.txt(dc, 226, 124, Graphics.FONT_MEDIUM, ">", Scenes.BLACK);

        var name = Rewards.itemName(item);
        var sub;
        if (!unlocked) {
            var left = Rewards.daysFor(item) - Rewards.goalDays();
            sub = Lang.format(WatchUi.loadResource(Rez.Strings.GoalDaysToGo) as String, [left]);
        } else if (Rewards.isWorn(item)) {
            sub = WatchUi.loadResource(Rez.Strings.Wearing) as String;
        } else {
            sub = WatchUi.loadResource(Rez.Strings.TapToWear) as String;
        }
        Scenes.txt(dc, 130, 214, Graphics.FONT_XTINY,
                   name + "  " + item.format("%d") + "/" + Rewards.ITEM_COUNT.format("%d"), Scenes.WHITE);
        Scenes.txt(dc, 130, 234, Graphics.FONT_XTINY, sub, unlocked ? Scenes.WHITE : 0x005555);
    }
}

class ClosetDelegate extends WatchUi.BehaviorDelegate {

    private var _view as ClosetView;

    function initialize(view as ClosetView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.item = _view.item % Rewards.ITEM_COUNT + 1;
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.item = (_view.item + Rewards.ITEM_COUNT - 2) % Rewards.ITEM_COUNT + 1;
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        Rewards.toggleWear(_view.item);
        Screen.dirty = true;
        WatchUi.requestUpdate();
        return true;
    }

    // Touch: swipe left = next, right = previous; tap "<" / ">" to browse,
    // the middle to wear. (swipe()/tapAt() are separate so the autopilot can
    // drive them.)
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        return swipe(evt.getDirection());
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return tapAt(evt.getCoordinates()[0]);
    }

    function swipe(dir as WatchUi.SwipeDirection) as Boolean {
        if (dir == WatchUi.SWIPE_LEFT) {
            return onNextPage();
        }
        if (dir == WatchUi.SWIPE_RIGHT) {
            return onPreviousPage();
        }
        return false;
    }

    function tapAt(x as Number) as Boolean {
        if (x < 75) {
            return onPreviousPage();
        }
        if (x > 185) {
            return onNextPage();
        }
        return onSelect();
    }
}

function showCloset() as Void {
    var view = new ClosetView();
    WatchUi.pushView(view, new ClosetDelegate(view), WatchUi.SLIDE_LEFT);
}
