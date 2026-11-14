import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// "Add water" screen from the design: three preset amounts, Undo last, and
// a toggle to add to yesterday instead of today. UP/DOWN move the
// highlight, START picks, BACK closes.
class QuickAddView extends WatchUi.View {

    // 0-2 = amounts, 3 = undo, 4 = today/yesterday toggle
    var selected as Number = 1;
    var yesterday as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Scenes.BLACK, Scenes.BLACK);
        dc.clear();
        var title = yesterday ? Rez.Strings.AddYesterdayTitle : Rez.Strings.AddWaterTitle;
        Scenes.txt(dc, 130, 44, Graphics.FONT_TINY, WatchUi.loadResource(title) as String, Scenes.WHITE);

        var amounts = Units.quickAmountsMl();
        for (var i = 0; i < amounts.size(); i++) {
            var cx = 62 + i * 68;
            if (i == selected) {
                dc.setColor(Scenes.WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, 112, 34);
            }
            dc.setColor(Scenes.BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, 112, 31);
            dc.setColor(Scenes.DBLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, 112, 27);
            Scenes.txt(dc, cx, 112, Graphics.FONT_XTINY, Units.amountNumber(amounts[i]), Scenes.WHITE);
        }
        Scenes.txt(dc, 130, 158, Graphics.FONT_XTINY, Units.label(), Scenes.GREY);
        Scenes.txt(dc, 130, 192, Graphics.FONT_XTINY,
                   WatchUi.loadResource(Rez.Strings.UndoLast) as String,
                   selected == 3 ? Scenes.BLUE : Scenes.WHITE);
        Scenes.txt(dc, 130, 222, Graphics.FONT_XTINY,
                   WatchUi.loadResource(yesterday ? Rez.Strings.AddToToday : Rez.Strings.AddToYesterday) as String,
                   selected == 4 ? Scenes.BLUE : Scenes.WHITE);
    }
}

class QuickAddDelegate extends WatchUi.BehaviorDelegate {

    private var _view as QuickAddView;

    function initialize(view as QuickAddView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.selected = (_view.selected + 1) % 5;
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.selected = (_view.selected + 4) % 5;
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var sel = _view.selected;
        if (sel <= 2) {
            var ml = Units.quickAmountsMl()[sel];
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            if (_view.yesterday) {
                Actions.logYesterday(ml);
            } else {
                Actions.logWater(ml);
            }
        } else if (sel == 3) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            Actions.undo();
        } else {
            _view.yesterday = !_view.yesterday;
            WatchUi.requestUpdate();
        }
        return true;
    }
}

function showQuickAdd() as Void {
    var view = new QuickAddView();
    WatchUi.pushView(view, new QuickAddDelegate(view), WatchUi.SLIDE_UP);
}
