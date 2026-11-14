import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;
import Toybox.WatchUi;

// Places pieces used by the Places submenu (see Menus.mc): place names, the
// "forget places" confirmation, and the GPS save screen.

function placeName(place as Number) as String {
    var ids = [Rez.Strings.PlaceHome, Rez.Strings.PlaceGym,
               Rez.Strings.PlaceWork, Rez.Strings.PlaceOther];
    return WatchUi.loadResource(ids[place]) as String;
}

class ForgetPlacesConfirmDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            Places.forgetAll();
        }
        return true;
    }
}

// Gets one GPS fix and saves it as the chosen place. Shows progress, then the
// result for a moment, then returns to the main screen.
class SavePlaceView extends WatchUi.View {

    const TIMEOUT_MS = 60000;
    const RESULT_MS = 2000;

    private var _place as Number;
    private var _text as String;
    private var _sub as String;
    private var _done as Boolean = false;
    private var _timer as Timer.Timer?;

    function initialize(place as Number) {
        View.initialize();
        _place = place;
        _text = WatchUi.loadResource(Rez.Strings.GettingGps) as String;
        _sub = WatchUi.loadResource(Rez.Strings.GpsTip) as String;
    }

    function onShow() as Void {
        if (_done) {
            return;
        }
        if (Places.FAKE_GPS) {
            Places.save(_place, Places.PRESET_LAT, Places.PRESET_LON, Position.QUALITY_GOOD);
            finish(Lang.format(WatchUi.loadResource(Rez.Strings.PlaceSaved) as String, [placeName(_place)]),
                   WatchUi.loadResource(Rez.Strings.SimulatedGps) as String);
            return;
        }
        Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
        _timer = new Timer.Timer();
        _timer.start(method(:onTimeout), TIMEOUT_MS, false);
    }

    function onHide() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onPosition(info as Position.Info) as Void {
        if (_done) {
            return;
        }
        var pos = info.position;
        if (pos == null || info.accuracy < Position.QUALITY_POOR) {
            finish(WatchUi.loadResource(Rez.Strings.NoFix) as String,
                   WatchUi.loadResource(Rez.Strings.GpsTip) as String);
            return;
        }
        var deg = pos.toDegrees();
        Places.save(_place, deg[0], deg[1], info.accuracy);
        var quality = info.accuracy >= Position.QUALITY_GOOD ? Rez.Strings.QualityGood
                    : info.accuracy >= Position.QUALITY_USABLE ? Rez.Strings.QualityUsable
                    : Rez.Strings.QualityPoor;
        finish(Lang.format(WatchUi.loadResource(Rez.Strings.PlaceSaved) as String, [placeName(_place)]),
               Lang.format(WatchUi.loadResource(Rez.Strings.GpsQuality) as String,
                           [WatchUi.loadResource(quality) as String]));
    }

    function onTimeout() as Void {
        if (!_done) {
            finish(WatchUi.loadResource(Rez.Strings.NoFix) as String,
                   WatchUi.loadResource(Rez.Strings.GpsTip) as String);
        }
    }

    private function finish(text as String, sub as String) as Void {
        _done = true;
        _text = text;
        _sub = sub;
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        if (_timer != null) {
            _timer.stop();
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onResultShown), RESULT_MS, false);
        WatchUi.requestUpdate();
    }

    function onResultShown() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(_done ? Graphics.COLOR_GREEN : Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 30, Graphics.FONT_MEDIUM, _text, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 15, Graphics.FONT_XTINY, _sub, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

// BACK cancels a save in progress.
class SavePlaceDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
