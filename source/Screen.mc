import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Shared foreground UI state. The main screen caches its numbers between
// animation frames, so after changing data call Screen.changed() (or
// Screen.react() to also play a hamster reaction) instead of
// WatchUi.requestUpdate().
module Screen {

    const PAGE_HOME = 0;
    const PAGE_WEEK = 1;
    const PAGE_CLOSET = 2;
    const PAGE_BADGES = 3;
    const PAGES = 4;

    var dirty as Boolean = true;
    var reaction as Number = HamsterArt.REACT_NONE;
    var reactAmount as Number = 0;     // ml shown as "+250" during a sip
    var page as Number = PAGE_HOME;
    var newItem as Number? = null;     // accessory unlocked by the last drink
    var bannerText as String? = null;  // short in-app message on the info line
    var bannerUntil as Number = 0;

    // Show a short message on the home screen's info line for `ms`
    // (in place of a system notification, which covers half the screen).
    function banner(text as String, ms as Number) as Void {
        bannerText = text;
        bannerUntil = System.getTimer() + ms;
        changed();
    }

    function changed() as Void {
        dirty = true;
        WatchUi.requestUpdate();
    }

    function react(r as Number) as Void {
        reaction = r;
        changed();
    }

    function nextPage(delta as Number) as Void {
        page = (page + delta + PAGES) % PAGES;
        changed();
    }
}
