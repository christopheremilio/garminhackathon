import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// "A day with <name>": a scripted, looping story that walks through every
// feature as one day in the hamster's life. Each step shows a title card
// (time of day, headline, one-line pitch), then applies a change and lets
// the real app react. "%N" in card text becomes the hamster's name.
// Any button press stops it (see HelloFenixDelegate).
//
// Note: the tour uses the app's real storage, so it clears today's water
// when it starts and when it stops. Mood is driven by faking the time of
// day (Demo.dayFrac), so it works at any hour. Rewards are faked too.
module DemoTour {

    const CARD_MS = 2400;    // title card
    const SHOW_MS = 4200;    // the app after the step is applied

    // [time, headline, pitch] per step. Keep lines short for the round screen.
    const STEPS = [
        ["",      "Meet %N",       "A tiny pet that\nlives on water"],
        ["7:30",  "Rise and sip",  "One press of START\nand %N perks up"],
        ["9:00",  "Oops!",         "Logged too much?\nUndo in one step"],
        ["12:00", "Busy morning",  "Skip water and\n%N gets thirsty"],
        ["12:30", "Drink now!",    "%N stomps.\nYour watch buzzes."],
        ["14:30", "Red alert",     "Tears. A water\npistol. Drama."],
        ["16:00", "%N fainted",    "Not gone. Just\nvery dramatic."],
        ["16:05", "One sip later", "...%N is back!"],
        ["17:30", "At the gym",    "Your watch knows\nand reminds you"],
        ["17:45", "Working hard",  "Heart rate up:\n%N hits the wheel"],
        ["20:00", "Goal reached!", "Party time.\nNew hat unlocked."],
        ["",      "Dress %N up",   "A new outfit every\n3 goal days"],
        ["",      "Collect badges","Streaks and totals\nfill the shelf"],
        ["",      "Your week",     "Every day\nat a glance"],
        ["",      "Keep %N happy", "Keep yourself\nhydrated."]
    ];
    const STEP_INTRO = 0;
    const STEP_OUTRO = 14;

    var player as DemoPlayer? = null;

    function start() as Void {
        if (player == null) {
            player = new DemoPlayer();
        }
        (player as DemoPlayer).start();
    }

    // Stop the tour if it's running. Returns true if it was.
    function stopIfRunning() as Boolean {
        var p = player;
        if (p != null && Demo.active) {
            p.stop();
            return true;
        }
        return false;
    }

    // Is the title card currently showing? (The view draws it instead.)
    function showingCard() as Boolean {
        var p = player;
        return Demo.active && p != null && p.isCard();
    }

    // "%N" -> the hamster's name.
    function named(text as String) as String {
        var out = "";
        var rest = text;
        var i = rest.find("%N");
        while (i != null) {
            out += rest.substring(0, i) + Prefs.name();
            rest = rest.substring(i + 2, rest.length()) as String;
            i = rest.find("%N");
        }
        return out + rest;
    }

    function drawCard(dc as Dc) as Void {
        var p = player as DemoPlayer;
        var step = p.step();
        var text = STEPS[step] as Array<String>;
        var bookend = step == STEP_INTRO || step == STEP_OUTRO;

        dc.setColor(Scenes.BLACK, Scenes.BLACK);
        dc.clear();
        if (bookend) {
            // the star of the show
            HamsterArt.draw(dc, 130, 62, 0.55, Pet.MOOD_HYDRATED, HamsterArt.ACC_NONE, HamsterArt.ACC_NONE,
                            1.0, false, System.getTimer(), HamsterArt.REACT_NONE, 0);
        } else if (text[0].length() > 0) {
            // time-of-day pill
            dc.setColor(Scenes.DBLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(96, 58, 68, 26, 13);
            Scenes.txt(dc, 130, 71, Graphics.FONT_XTINY, text[0], Scenes.WHITE);
        }
        Scenes.fitTxt(dc, 130, 118, [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY]
                      as Array<Graphics.FontType>, named(text[1]), Scenes.BLUE, 200);
        dc.setColor(Scenes.WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(130, 140, Graphics.FONT_TINY, named(text[2]), Graphics.TEXT_JUSTIFY_CENTER);

        // story progress dots
        var n = STEPS.size();
        var x0 = 130 - (n - 1) * 4;
        for (var i = 0; i < n; i++) {
            dc.setColor(i <= step ? Scenes.BLUE : Scenes.DGREY, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x0 + i * 8, 222, i == step ? 3 : 2);
        }
        Scenes.txt(dc, 130, 240, Graphics.FONT_XTINY, "Any key: stop", Scenes.DGREY);
    }
}

class DemoPlayer {

    private var _timer as Timer.Timer = new Timer.Timer();
    private var _step as Number = -1;
    private var _card as Boolean = false;

    function initialize() {
    }

    function step() as Number {
        return _step < 0 ? 0 : _step;
    }

    function isCard() as Boolean {
        return _card;
    }

    function start() as Void {
        System.println("DEMO start");
        Demo.active = true;
        _step = -1;
        next();
    }

    function stop() as Void {
        _timer.stop();
        _card = false;
        Demo.active = false;
        Demo.resetInputs();
        WaterLog.resetAll();
        Places.clearLastPlace();
        Screen.page = Screen.PAGE_HOME;
        Screen.changed();
    }

    // Show the next step's title card.
    function next() as Void {
        _step = (_step + 1) % DemoTour.STEPS.size();
        _card = true;
        _timer.stop();
        _timer.start(method(:onCardDone), DemoTour.CARD_MS, false);
        Screen.changed();
    }

    // Card finished: apply the step and show the real screen.
    function onCardDone() as Void {
        _card = false;
        apply(_step);
        System.println("DEMO step " + (_step + 1).format("%d") + "/" + DemoTour.STEPS.size().format("%d") + " "
                       + DemoTour.named((DemoTour.STEPS[_step] as Array<String>)[1]));
        _timer.stop();
        _timer.start(method(:next), DemoTour.SHOW_MS, false);
        Screen.changed();
    }

    private function apply(step as Number) as Void {
        switch (step) {
            case 0: // Meet <name>: a fresh morning
                Demo.resetInputs();
                Demo.dayFrac = 0.05;
                Screen.page = Screen.PAGE_HOME;
                WaterLog.resetAll();
                break;
            case 1: // 7:30 Rise and sip
                Actions.logWater(Units.defaultAddMl());
                break;
            case 2: // 9:00 Oops! (log one too many, undo it)
                Demo.dayFrac = 0.15;
                WaterLog.add(Units.defaultAddMl(), null);
                Actions.undo();
                break;
            case 3: // 12:00 Busy morning -> thirsty
                Demo.dayFrac = 0.35;
                break;
            case 4: // 12:30 Drink now! (angry stomp + buzzes)
                Demo.dayFrac = 0.4;
                Screen.reaction = HamsterArt.REACT_ANGRY;
                DrinkAlert.angry();
                break;
            case 5: // 14:30 Red alert (last warning)
                Demo.dayFrac = 0.6;
                break;
            case 6: // 16:00 Fainted (collapsed)
                Demo.dayFrac = 0.9;
                break;
            case 7: // 16:05 One sip later... back! (then on track again)
                Demo.dayFrac = 0.2;
                Actions.logWater(Units.defaultAddMl());
                Screen.reaction = HamsterArt.REACT_REVIVE;
                break;
            case 8: // 17:30 At the gym (arrival reminder)
                Demo.place = Places.GYM;
                Screen.banner(Lang.format(WatchUi.loadResource(Rez.Strings.ArriveBanner) as String,
                                          [Units.amount(Hydration.GYM_DRINK_ML)]), 4000);
                DrinkAlert.play();
                break;
            case 9: // 17:45 Working hard (wheel)
                Demo.exerting = true;
                break;
            case 10: // 20:00 Goal reached! (rewards aren't really counted)
                Demo.exerting = false;
                Demo.place = null;
                Actions.logWater(Hydration.goalMl() - WaterLog.getMl());
                Screen.newItem = HamsterArt.ACC_PARTY_HAT;
                break;
            case 11: // Dress up
                Demo.hat = HamsterArt.ACC_CROWN;
                Demo.other = HamsterArt.ACC_GLASSES;
                Screen.page = Screen.PAGE_CLOSET;
                break;
            case 12: // Collect badges
                Demo.badges = (1 << Rewards.BADGE_FIRST) | (1 << Rewards.BADGE_STREAK3)
                              | (1 << Rewards.BADGE_STREAK7) | (1 << Rewards.BADGE_TOTAL10);
                Screen.page = Screen.PAGE_BADGES;
                break;
            case 13: // Your week
                Screen.page = Screen.PAGE_WEEK;
                break;
            default: // Keep <name> happy: back home, hydrated, sparkling
                Screen.page = Screen.PAGE_HOME;
                break;
        }
    }

}
