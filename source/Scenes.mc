import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Scene pieces from the "hamster-looks" design: the room (wall, floor,
// window, cage water bottle showing today's level), our segmented water
// ring, text helpers, and the weekly and badges pages. Layout is for the 260x260 fēnix 7 Pro.
module Scenes {

    const OUT = 0x550000;
    const WHITE = 0xFFFFFF;
    const BLACK = 0x000000;
    const GREY = 0xAAAAAA;
    const DGREY = 0x555555;
    const BLUE = 0x00AAFF;
    const DBLUE = 0x0055AA;
    const RED = 0xFF5555;
    const ORANGE = 0xFFAA00;
    const YELLOW = 0xFFFF00;

    // Room themes: [wall, floor, text, bar]
    const THEME_DAY = [0xAAFFAA, 0x55AA55, BLACK, BLUE];
    const THEME_WARNING = [0xFF5555, 0xAA0000, WHITE, 0xAA0000];
    const THEME_COLLAPSED = [0xAAAAAA, 0x555555, BLACK, 0x555555];
    const THEME_NIGHT = [0x000055, 0x000000, WHITE, BLUE];
    const THEME_PARTY = [0xAAAAFF, 0x5555AA, BLACK, BLUE];
    const CLOSET_WALL = 0xAAFFFF;
    const CLOSET_FLOOR = 0x00AAAA;

    function themeFor(mood as Number) as Array<Number> {
        if (mood == Pet.MOOD_LAST_WARNING) { return THEME_WARNING as Array<Number>; }
        if (mood == Pet.MOOD_COLLAPSED) { return THEME_COLLAPSED as Array<Number>; }
        if (mood == Pet.MOOD_SLEEPING) { return THEME_NIGHT as Array<Number>; }
        return THEME_DAY as Array<Number>;
    }

    function txt(dc as Dc, x as Number, y as Number, font as Graphics.FontType, s as String, c as Number) as Void {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, s, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Draw text in the first font (largest first) that fits maxWidth.
    function fitTxt(dc as Dc, x as Number, y as Number, fonts as Array<Graphics.FontType>, s as String,
                    c as Number, maxWidth as Number) as Void {
        for (var i = 0; i < fonts.size(); i++) {
            if (i == fonts.size() - 1 || dc.getTextWidthInPixels(s, fonts[i]) <= maxWidth) {
                txt(dc, x, y, fonts[i], s, c);
                return;
            }
        }
    }

    // Wall, floor, window and (if level >= 0) the bottle at that fill level.
    function room(dc as Dc, wall as Number, floor as Number, level as Float, window as Boolean,
                  night as Boolean) as Void {
        dc.setColor(wall, wall);
        dc.clear();
        dc.setColor(floor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 188, 260, 72);
        if (window) {
            dc.setColor(OUT, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(32, 84, 38, 38);
            dc.setColor(night ? 0x0000AA : 0xAAFFFF, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(35, 87, 32, 32);
            if (night) {
                dc.setColor(YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(58, 96, 4);      // moon
            }
            dc.setColor(OUT, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(50, 87, 2, 32);
            dc.fillRectangle(35, 102, 32, 2);
        }
        if (level < 0) {
            return;
        }
        if (level > 1.0) { level = 1.0; }
        // cage-style water bottle shows today's level
        dc.setColor(DGREY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(203, 86, 20, 48, 6);
        dc.setColor(WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(205, 88, 16, 44, 5);
        var h = (44 * level).toNumber();
        if (h > 0) {
            dc.setColor(BLUE, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(205, 132 - h, 16, h, 4);
        }
        dc.setColor(DGREY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(213, 134, 213, 144);
        dc.drawLine(213, 144, 204, 144);
        dc.setPenWidth(1);
    }

    // Water ring around the edge: one segment per drink-sized amount
    // (segMl), filled clockwise from 7 o'clock to 5 o'clock, the current
    // segment partly filled. Blue, all green once the goal is met. The gap at
    // the bottom leaves room for the page dots.
    const RING_R = 120;
    const RING_START = 240;     // degrees, 7 o'clock
    const RING_SWEEP = 300;     // ... to 5 o'clock
    const RING_GAP = 3;

    function waterRing(dc as Dc, ml as Number, goalMl as Number, segMl as Number) as Void {
        var segs = (goalMl + segMl - 1) / segMl;
        if (segs < 1) { segs = 1; }
        var met = ml >= goalMl;
        var fillColor = met ? 0x00AA00 : BLUE;
        var seg = RING_SWEEP.toFloat() / segs;

        // black base so the ring reads on every room colour
        dc.setColor(BLACK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(18);
        dc.drawArc(130, 130, RING_R, Graphics.ARC_CLOCKWISE, RING_START + 2, RING_START - RING_SWEEP - 2);

        dc.setPenWidth(12);
        for (var i = 0; i < segs; i++) {
            var a0 = RING_START - i * seg - RING_GAP / 2.0;
            var a1 = RING_START - (i + 1) * seg + RING_GAP / 2.0;
            dc.setColor(DGREY, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(130, 130, RING_R, Graphics.ARC_CLOCKWISE, a0.toNumber(), a1.toNumber());
            var segFill = met ? 1.0 : (ml - i * segMl).toFloat() / segMl;
            if (segFill > 0) {
                if (segFill > 1.0) { segFill = 1.0; }
                var af = a0 - (a0 - a1) * segFill;
                if (a0 - af >= 1) {
                    dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
                    dc.drawArc(130, 130, RING_R, Graphics.ARC_CLOCKWISE, a0.toNumber(), af.toNumber());
                }
            }
        }
        dc.setPenWidth(1);
    }

    // Tipped-over empty cup beside a collapsed hamster.
    function tippedCup(dc as Dc) as Void {
        dc.setColor(DGREY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(48, 178, 70, 182);
        dc.drawLine(70, 182, 68, 196);
        dc.drawLine(68, 196, 46, 192);
        dc.setPenWidth(1);
    }

    // Small page dots, bottom centre (in the ring's gap).
    function pageDots(dc as Dc, index as Number, count as Number, c as Number) as Void {
        var x0 = 130 - (count - 1) * 5;
        for (var i = 0; i < count; i++) {
            dc.setColor(c, Graphics.COLOR_TRANSPARENT);
            if (i == index) {
                dc.fillCircle(x0 + i * 10, 248, 3);
            } else {
                dc.drawCircle(x0 + i * 10, 248, 3);
            }
        }
    }

    // ---------------------------------------------------------------------
    // Weekly tracker: last 7 days (today on the right). Blue = goal met,
    // red = missed, dark blue = today so far, grey stub = no data.

    function weekly(dc as Dc) as Void {
        dc.setColor(BLACK, BLACK);
        dc.clear();
        var letters = ["S", "M", "T", "W", "T", "F", "S"];
        var met = 0;
        var total = 0;
        var days = 0;
        for (var j = 0; j < 7; j++) {
            var n = 6 - j;                       // days ago
            var day = WaterLog.daysAgo(n);
            var r = WaterLog.dayRecord(day);
            var h = 4;
            var color = DGREY;
            if (r != null && r.size() >= 2 && r[1] > 0) {
                var frac = r[0].toFloat() / r[1];
                h = (72 * (frac > 1.0 ? 1.0 : frac)).toNumber();
                if (h < 4) { h = 4; }
                var isMet = r[0] >= r[1];
                if (isMet) { met++; }
                color = isMet ? BLUE : (n == 0 ? DBLUE : RED);
                total += r[0];
                days++;
            }
            var bx = 43 + j * 27;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(bx, 172 - h, 14, h, 3);
            var info = Gregorian.info(new Time.Moment(WaterLog.nowSec() - n * 86400), Time.FORMAT_SHORT);
            var dow = (info.day_of_week as Number) - 1;
            txt(dc, bx + 7, 192, Graphics.FONT_XTINY, letters[dow] as String, n == 0 ? WHITE : GREY);
        }
        txt(dc, 130, 38, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.WeekTitle) as String, GREY);
        txt(dc, 130, 66, Graphics.FONT_TINY,
            Lang.format(WatchUi.loadResource(Rez.Strings.WeekDaysMet) as String, [met]), WHITE);
        var avg = days > 0 ? total / days : 0;
        txt(dc, 130, 226, Graphics.FONT_XTINY,
            Lang.format(WatchUi.loadResource(Rez.Strings.WeekAvg) as String, [Units.total(avg)]), GREY);
    }

    // ---------------------------------------------------------------------
    // Badges: 3 x 3 trophy shelf, earned in gold, locked greyed out.

    function badgesPage(dc as Dc) as Void {
        dc.setColor(BLACK, BLACK);
        dc.clear();
        txt(dc, 130, 32, Graphics.FONT_TINY, WatchUi.loadResource(Rez.Strings.BadgesTitle) as String, WHITE);
        for (var k = 0; k < Rewards.BADGE_COUNT; k++) {
            var gx = 74 + (k % 3) * 56;
            var gy = 80 + (k / 3) * 52;
            var earned = Rewards.hasBadge(k);
            dc.setColor(earned ? ORANGE : DGREY, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(gx, gy, 22);
            dc.setColor(earned ? 0xFFFF55 : BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(gx, gy, 18);
            txt(dc, gx, gy, Graphics.FONT_XTINY, Rewards.BADGE_LABELS[k] as String, earned ? BLACK : GREY);
        }
        txt(dc, 130, 228, Graphics.FONT_XTINY,
            Lang.format(WatchUi.loadResource(Rez.Strings.BadgesEarned) as String,
                        [Rewards.badgeCount(), Rewards.BADGE_COUNT]), GREY);
    }
}
