import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// "Add water" screen from the design: three preset amounts (1/2, 1 and 2
// glasses) and Undo last. UP/DOWN move the highlight, START picks, BACK
// closes.
const QUICK_ADD_CHOICES = 4;        // 0-2 = amounts, 3 = undo

class QuickAddView extends WatchUi.View {

    var selected as Number = 1;

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Scenes.BLACK, Scenes.BLACK);
        dc.clear();
        Scenes.txt(dc, 130, 52, Graphics.FONT_TINY,
                   WatchUi.loadResource(Rez.Strings.AddWaterTitle) as String, Scenes.WHITE);

        var amounts = Units.quickAmountsMl();
        for (var i = 0; i < amounts.size(); i++) {
            var cx = 62 + i * 68;
            if (i == selected) {
                dc.setColor(Scenes.WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, 120, 34);
            }
            dc.setColor(Scenes.BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, 120, 31);
            dc.setColor(Scenes.DBLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, 120, 27);
            Scenes.txt(dc, cx, 120, Graphics.FONT_XTINY, Units.amountNumber(amounts[i]), Scenes.WHITE);
        }
        Scenes.txt(dc, 130, 166, Graphics.FONT_XTINY, Units.label(), Scenes.GREY);
        Scenes.txt(dc, 130, 204, Graphics.FONT_XTINY,
                   WatchUi.loadResource(Rez.Strings.UndoLast) as String,
                   selected == 3 ? Scenes.BLUE : Scenes.WHITE);
    }
}

class QuickAddDelegate extends WatchUi.BehaviorDelegate {

    private var _view as QuickAddView;

    function initialize(view as QuickAddView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.selected = (_view.selected + 1) % QUICK_ADD_CHOICES;
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.selected = (_view.selected + QUICK_ADD_CHOICES - 1) % QUICK_ADD_CHOICES;
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var sel = _view.selected;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (sel <= 2) {
            Actions.logWater(Units.quickAmountsMl()[sel]);
        } else {
            Actions.undo();
        }
        return true;
    }
}

function showQuickAdd() as Void {
    var view = new QuickAddView();
    WatchUi.pushView(view, new QuickAddDelegate(view), WatchUi.SLIDE_UP);
}
