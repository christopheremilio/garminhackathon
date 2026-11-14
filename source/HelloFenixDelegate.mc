import Toybox.Lang;
import Toybox.WatchUi;

// Main screen buttons:
//   START    add 250 ml (the hamster sips / revives / celebrates);
//            on the Closet page, open the closet to dress up
//   UP/DOWN  switch page: Home, Weekly, Closet, Badges
//   Hold UP  menu: add water (other amounts, undo), rename,
//            wake/bed times, places, reset
//   BACK     exit (reminders keep running)
// Any button stops the demo tour first.
class HelloFenixDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        if (DemoTour.stopIfRunning()) {
            return true;
        }
        if (Screen.page == Screen.PAGE_CLOSET) {
            showCloset();
            return true;
        }
        Screen.page = Screen.PAGE_HOME;
        Actions.logWater(Units.defaultAddMl());
        return true;
    }

    function onNextPage() as Boolean {
        if (DemoTour.stopIfRunning()) {
            return true;
        }
        Screen.nextPage(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        if (DemoTour.stopIfRunning()) {
            return true;
        }
        Screen.nextPage(-1);
        return true;
    }

    function onMenu() as Boolean {
        if (DemoTour.stopIfRunning()) {
            return true;
        }
        showMainMenu();
        return true;
    }

    function onBack() as Boolean {
        DemoTour.stopIfRunning();
        return false;
    }

    // Touch on the Closet page: swipe left/right or tap opens the closet.
    // (swipe()/tap() are separate so the autopilot can drive them.)
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        return swipe(evt.getDirection());
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return tap();
    }

    function swipe(dir as WatchUi.SwipeDirection) as Boolean {
        if (Screen.page == Screen.PAGE_CLOSET && (dir == WatchUi.SWIPE_LEFT || dir == WatchUi.SWIPE_RIGHT)) {
            if (!DemoTour.stopIfRunning()) {
                showCloset();
            }
            return true;
        }
        return false;
    }

    function tap() as Boolean {
        if (Screen.page == Screen.PAGE_CLOSET) {
            if (!DemoTour.stopIfRunning()) {
                showCloset();
            }
            return true;
        }
        return false;
    }
}

// Handles the Yes/No answer from the reset confirmation dialog.
class ResetConfirmDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            Actions.resetToday();
        }
        return true;
    }
}
