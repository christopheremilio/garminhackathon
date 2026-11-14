import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Main screen, in the "hamster-looks" design. Two pages (UP/DOWN):
//   Home   - the hamster in its room: name / mood line, a rotating info line,
//            the bottle and water bar for today. Room turns red at "last
//            warning" and grey when collapsed; night room while asleep.
//   Weekly - the last 7 days.
//   Closet - the hamster in its accessories (START: dress up).
//   Badges - the trophy shelf.
//
// Performance: one animation timer redraws the screen (slow when idle, fast
// only while the hamster moves). The numbers are cached and recalculated
// every STATE_REFRESH_MS or when Screen.changed() is called.
class HelloFenixView extends WatchUi.View {

    const STATE_REFRESH_MS = 30000;
    const ROTATE_MS = 4000;         // info line rotation

    private var _timer as Timer.Timer?;
    private var _period as Number = 0;
    private var _demoStarted as Boolean = false;
    private var _namePrompted as Boolean = false;
    private var _remindedDue as Boolean = false;
    private var _showReminder as Boolean = false;

    // Cached state
    private var _stateAt as Number = 0;
    private var _ml as Number = 0;
    private var _goal as Number = 2000;
    private var _bonus as Number = 0;
    private var _exerting as Boolean = false;
    private var _place as Number? = null;
    private var _interval as Number = 60;
    private var _drinkMl as Number? = null;
    private var _due as Boolean = false;
    private var _mood as Number = Pet.MOOD_ON_TRACK;
    private var _streak as Number = 0;
    private var _name as String = Prefs.DEFAULT_NAME;
    private var _recordedGoal as Number = 0;

    // Current hamster reaction
    private var _reaction as Number = HamsterArt.REACT_NONE;
    private var _reactStart as Number = 0;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        if (!_demoStarted) {
            _demoStarted = true;
            if (Autopilot.ENABLED) {
                Autopilot.start();          // scripted UI test, instead of the demo
            } else if (Demo.ENABLED) {
                DemoTour.start();
            }
        }
        Screen.dirty = true;
        WaterLog.markForeground(true);
        setPeriod(250);
        if (Places.anySaved() && !Places.FAKE_GPS) {
            Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
        }
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _period = 0;
        WaterLog.markForeground(false);
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }

    function onPosition(info as Position.Info) as Void {
        // Record where we are so the background doesn't later send an
        // "arrived" reminder for a place you've already opened the app at.
        Places.checkArrival();
        Screen.changed();
    }

    // Timer callback. Screens are pushed from here, not from onUpdate.
    function onTick() as Void {
        if (!_namePrompted && !Demo.active && !Autopilot.active && !Prefs.onboarded()) {
            _namePrompted = true;
            Onboarding.start();
            return;
        }
        if (_showReminder) {
            // Re-check at the moment of showing: the queued reminder may be
            // stale (water logged, setup just finished, snoozed...).
            _showReminder = false;
            if (Prefs.onboarded() && !WaterLog.isSnoozed()
                    && WaterLog.isDue(Hydration.intervalMin(_exerting, _place))) {
                showReminder();
                return;
            }
        }
        WatchUi.requestUpdate();
    }

    private function setPeriod(ms as Number) as Void {
        if (ms == _period && _timer != null) {
            return;
        }
        if (_timer != null) {
            _timer.stop();
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), ms, true);
        _period = ms;
    }

    private function refreshState(now as Number) as Void {
        _stateAt = now;
        WaterLog.markForeground(true);    // keep "app is open" fresh (see WaterLog)
        Screen.dirty = false;
        _ml = WaterLog.getMl();
        _goal = Hydration.goalMl();
        _bonus = Hydration.bonusMl();
        _exerting = Hydration.isExerting();
        _place = Places.currentPlace();
        _interval = Hydration.intervalMin(_exerting, _place);
        _drinkMl = Hydration.suggestedDrinkMl(_exerting, _place);
        _due = WaterLog.isDue(_interval);
        _mood = Pet.moodFor([Hydration.petScore(_ml, _goal)], _ml >= _goal, Prefs.isNight());
        _streak = WaterLog.streak();
        _name = Prefs.name();
        if (_goal != _recordedGoal && !Demo.active) {
            _recordedGoal = _goal;
            WaterLog.recordToday();
        }

        // In-app reminder once each time a drink becomes due while we're on
        // screen: the reminder screen (angry jumping hamster, chime, buzzes).
        // The demo plays its own.
        if (_due && !_remindedDue && !WaterLog.isSnoozed() && !Demo.active && Prefs.onboarded()) {
            _remindedDue = true;
            _showReminder = true;
        } else if (!_due) {
            _remindedDue = false;
        }
    }

    function onUpdate(dc as Dc) as Void {
        var now = System.getTimer();

        if (DemoTour.showingCard()) {
            DemoTour.drawCard(dc);
            setPeriod(250);
            return;
        }
        if (Screen.dirty || now - _stateAt >= STATE_REFRESH_MS) {
            refreshState(now);
        }
        if (Screen.reaction != HamsterArt.REACT_NONE) {
            _reaction = Screen.reaction;
            _reactStart = now;
            Screen.reaction = HamsterArt.REACT_NONE;
        }
        var rt = now - _reactStart;
        if (_reaction != HamsterArt.REACT_NONE && rt >= HamsterArt.reactionMs(_reaction)) {
            _reaction = HamsterArt.REACT_NONE;
        }

        if (Screen.page == Screen.PAGE_WEEK) {
            Scenes.weekly(dc);
            Scenes.pageDots(dc, Screen.page, Screen.PAGES, Scenes.GREY);
            setPeriod(1000);
            return;
        }
        if (Screen.page == Screen.PAGE_BADGES) {
            Scenes.badgesPage(dc);
            Scenes.pageDots(dc, Screen.page, Screen.PAGES, Scenes.GREY);
            setPeriod(1000);
            return;
        }
        if (Screen.page == Screen.PAGE_CLOSET) {
            drawClosetPage(dc, now);
            Scenes.pageDots(dc, Screen.page, Screen.PAGES, Scenes.BLACK);
            setPeriod(HamsterArt.framePeriod(Pet.MOOD_ON_TRACK, false, now, HamsterArt.REACT_NONE));
            return;
        }

        if (_reaction == HamsterArt.REACT_GOAL) {
            drawGoalReward(dc, now, rt);
        } else {
            drawHome(dc, now, rt);
        }
        if (Demo.active) {
            Scenes.txt(dc, 130, 10, Graphics.FONT_XTINY, "DEMO", Scenes.ORANGE);
        }
        setPeriod(HamsterArt.framePeriod(_mood, _exerting && _mood != Pet.MOOD_SLEEPING, now, _reaction));
    }

    // ---------------------------------------------------------------------
    // Home room

    private function drawHome(dc as Dc, now as Number, rt as Number) as Void {
        var reviving = _reaction == HamsterArt.REACT_REVIVE;
        var mood = reviving ? Pet.MOOD_HYDRATED : _mood;
        var theme = Scenes.themeFor(reviving ? Pet.MOOD_ON_TRACK : _mood);
        var textColor = theme[2];
        var fill = _goal > 0 ? _ml.toFloat() / _goal : 0.0;
        var night = _mood == Pet.MOOD_SLEEPING;

        Scenes.room(dc, theme[0], theme[1], fill, true, night);

        // Line 1: name, or "<name> is thirsty" etc.
        var line1 = reviving ? fmt(Rez.Strings.TitleBack, [_name]) : titleFor(_mood);
        Scenes.fitTxt(dc, 130, 44, [Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<Graphics.FontType>,
                      line1, textColor, 130);
        // Line 2: urgent message, else a rotating info line.
        var line2 = reviving
            ? (_streak > 0 ? fmt(Rez.Strings.StreakDays, [_streak]) : str(Rez.Strings.NewStreak))
            : infoLine(now);
        Scenes.fitTxt(dc, 130, 66, [Graphics.FONT_XTINY] as Array<Graphics.FontType>, line2, textColor, 170);

        // The hamster (wheel while working hard, lying down when collapsed),
        // wearing its accessories; the plant sits in the room.
        var hat = Rewards.wornHat();
        var other = Rewards.wornOther();
        if (other == HamsterArt.ACC_PLANT) {
            HamsterArt.plant(dc, 194, 206);
            other = HamsterArt.ACC_NONE;
        }
        var running = _exerting && !night && !reviving;
        if (mood == Pet.MOOD_COLLAPSED) {
            Scenes.tippedCup(dc);
            HamsterArt.draw(dc, 160, 158, 1.15, mood, hat, other, fill, false, now, _reaction, rt);
        } else if (running) {
            HamsterArt.drawWheel(dc, 130, 140, 66, now);
            HamsterArt.draw(dc, 130, 122, 0.85, mood, hat, other, fill, true, now, _reaction, rt);
        } else {
            HamsterArt.draw(dc, 130, 132, 1.1, mood, hat, other, fill, false, now, _reaction, rt);
        }

        // Sparkles when hydrated / reviving (twinkle by alternating size).
        if (mood == Pet.MOOD_HYDRATED) {
            var tw = ((now / 400) % 2) * 3;
            HamsterArt.star(dc, 196, 66, 6 + tw, Scenes.ORANGE);
            HamsterArt.star(dc, 62, 150, 7 - tw / 2, Scenes.ORANGE);
        }
        // "+250" floats up after logging.
        if (_reaction == HamsterArt.REACT_SIP) {
            Scenes.txt(dc, 84, 84 - rt / 30, Graphics.FONT_XTINY,
                       "+" + Units.amount(Screen.reactAmount), Scenes.DBLUE);
        }

        // Today's water: the ring around the edge, amounts underneath.
        Scenes.waterRing(dc, _ml, _goal, Units.defaultAddMl());
        Scenes.txt(dc, 130, 226, Graphics.FONT_XTINY, Units.pair(_ml, _goal), textColor);
        Scenes.pageDots(dc, Screen.page, Screen.PAGES, textColor);
    }

    // Goal reached: party room, party hat, stars, streak.
    private function drawGoalReward(dc as Dc, now as Number, rt as Number) as Void {
        var theme = Scenes.THEME_PARTY;
        Scenes.room(dc, theme[0] as Number, theme[1] as Number, -1.0, false, false);
        Scenes.txt(dc, 130, 28, Graphics.FONT_TINY, str(Rez.Strings.GoalReachedTitle), Scenes.BLACK);
        var other = Rewards.wornOther();
        HamsterArt.draw(dc, 130, 126, 1.1, Pet.MOOD_HYDRATED, HamsterArt.ACC_PARTY_HAT,
                        other == HamsterArt.ACC_PLANT ? HamsterArt.ACC_NONE : other, 1.0, false,
                        now, _reaction, rt);
        var tw = ((now / 300) % 2) * 3;
        HamsterArt.star(dc, 52, 100, 10 - tw, Scenes.YELLOW);
        HamsterArt.star(dc, 74, 60, 7 + tw, Scenes.YELLOW);
        HamsterArt.star(dc, 186, 62, 8 - tw, Scenes.YELLOW);
        HamsterArt.star(dc, 60, 160, 7 + tw, Scenes.YELLOW);
        var bottom = Screen.newItem != null
            ? fmt(Rez.Strings.NewItem, [Rewards.itemName(Screen.newItem as Number)])
            : fmt(Rez.Strings.StreakDays, [_streak]);
        Scenes.txt(dc, 130, 230, Graphics.FONT_XTINY, bottom, Scenes.WHITE);
    }

    // Closet page: the hamster in what it's wearing; START opens the closet.
    private function drawClosetPage(dc as Dc, now as Number) as Void {
        Scenes.room(dc, Scenes.CLOSET_WALL, Scenes.CLOSET_FLOOR, -1.0, false, false);
        Scenes.txt(dc, 130, 28, Graphics.FONT_TINY, str(Rez.Strings.ClosetTitle), Scenes.BLACK);
        var hat = Rewards.wornHat();
        var other = Rewards.wornOther();
        if (other == HamsterArt.ACC_PLANT) {
            HamsterArt.plant(dc, 200, 196);
            other = HamsterArt.ACC_NONE;
        }
        HamsterArt.draw(dc, 130, 124, 1.1, Pet.MOOD_ON_TRACK, hat, other, 0.6, false, now,
                        HamsterArt.REACT_NONE, 0);
        Scenes.txt(dc, 130, 212, Graphics.FONT_XTINY, str(Rez.Strings.ClosetHint), Scenes.WHITE);
        Scenes.txt(dc, 130, 232, Graphics.FONT_XTINY,
                   fmt(Rez.Strings.UnlockedOf, [Rewards.unlockedCount(), Rewards.ITEM_COUNT]), Scenes.WHITE);
    }

    // ---------------------------------------------------------------------
    // Text

    private function str(id as ResourceId) as String {
        return WatchUi.loadResource(id) as String;
    }

    private function fmt(id as ResourceId, args as Array) as String {
        return Lang.format(str(id), args);
    }

    private function titleFor(mood as Number) as String {
        if (mood == Pet.MOOD_THIRSTY) { return fmt(Rez.Strings.TitleThirsty, [_name]); }
        if (mood == Pet.MOOD_LAST_WARNING) { return fmt(Rez.Strings.TitleCryingHome, [_name]); }
        if (mood == Pet.MOOD_COLLAPSED) { return fmt(Rez.Strings.TitleCollapsed, [_name]); }
        if (mood == Pet.MOOD_SLEEPING) { return fmt(Rez.Strings.TitleAsleep, [_name]); }
        return _name;
    }

    // Urgent lines first; otherwise rotate through what's relevant.
    private function infoLine(now as Number) as String {
        var b = Screen.bannerText;
        if (b != null && now < Screen.bannerUntil) {
            return b;
        }
        if (_mood == Pet.MOOD_COLLAPSED) { return str(Rez.Strings.DrinkToRevive); }
        if (_mood == Pet.MOOD_LAST_WARNING) { return str(Rez.Strings.DrinkNowShort); }
        if (_mood == Pet.MOOD_SLEEPING) {
            return fmt(Rez.Strings.SleepingUntil, [Prefs.hourLabel(Prefs.wakeHour())]);
        }
        if (_due) {
            return _drinkMl != null ? fmt(Rez.Strings.DrinkNowExertion, [Units.amount(_drinkMl as Number)]) : str(Rez.Strings.DrinkNow);
        }
        var lines = [] as Array<String>;
        if (_ml >= _goal) {
            lines.add(str(Rez.Strings.GoalMet));
        }
        if (_exerting) {
            lines.add(str(Rez.Strings.Exerting));
        }
        if (_place != null) {
            lines.add(fmt(Rez.Strings.AtPlace, [placeName(_place as Number)]));
        }
        if (_bonus > 0) {
            lines.add(fmt(Rez.Strings.ActivityBonus, [Units.total(_bonus)]));
        }
        if (_streak > 0) {
            lines.add(fmt(Rez.Strings.StreakDays, [_streak]));
        }
        if (_ml < _goal) {
            var mins = (WaterLog.secondsUntilDue(_interval) + 59) / 60;
            lines.add(fmt(Rez.Strings.NextIn, [mins]));
        }
        if (lines.size() == 0) {
            return "";
        }
        return lines[(now / ROTATE_MS) % lines.size()];
    }
}
