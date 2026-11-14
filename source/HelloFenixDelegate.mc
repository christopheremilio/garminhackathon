import Toybox.Lang;
import Toybox.WatchUi;

// BehaviorDelegate receives button presses. Returning true means the
// event was handled and should not bubble up to the system.
class HelloFenixDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // START: log a glass of water.
    function onSelect() as Boolean {
        WaterLog.addGlass(null);
        WatchUi.requestUpdate();
        return true;
    }

    // DOWN: undo the last glass.
    function onNextPage() as Boolean {
        WaterLog.removeGlass();
        WatchUi.requestUpdate();
        return true;
    }
}
