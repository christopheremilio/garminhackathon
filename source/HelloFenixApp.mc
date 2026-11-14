import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Entry point of the app. AppBase owns the lifecycle and hands the
// initial View + Delegate pair back to the system when the app starts.
class HelloFenixApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called when the application starts up.
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when the application is exiting.
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of the application here.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new HelloFenixView(), new HelloFenixDelegate()];
    }
}

// Convenience accessor used by the view and delegate.
function getApp() as HelloFenixApp {
    return Application.getApp() as HelloFenixApp;
}
