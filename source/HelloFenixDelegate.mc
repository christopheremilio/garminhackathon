import Toybox.Lang;
import Toybox.WatchUi;

// BehaviorDelegate receives button presses. Returning true means the
// event was handled and should not bubble up to the system.
class HelloFenixDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // START button: refresh the step count immediately.
    function onSelect() as Boolean {
        WatchUi.requestUpdate();
        return true;
    }
}
