import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// The hamster, ported from the "hamster-looks" design (cream body, orange
// head patch, brown outline, cheeks that grow as you drink; the design's
// blue water-drop tuft was removed at the user's request) with our animations layered on top. All motion is computed from the
// current time `t` (ms, System.getTimer()), so it looks the same however
// often the screen redraws; framePeriod() says how often that should be.
//
// Colours use only the fēnix 7 Pro's 64-colour palette (00/55/AA/FF).
// Drawing happens in hamster-local coordinates scaled by `s` around (x, y);
// collapsed rotates the hamster onto its side.
module HamsterArt {

    // Reactions to things the user does.
    enum {
        REACT_NONE,
        REACT_SIP,     // logged water: puffed cheeks + hop
        REACT_TILT,    // undo: confused wobble
        REACT_REVIVE,  // first drink after collapsing: "<name> is back!"
        REACT_GOAL,    // just reached today's goal: party
        REACT_ANGRY    // drink now!: jumping up and down in anger
    }

    const FACE_ANGRY = 100;       // face used during REACT_ANGRY
    const ANGRY_JUMP_MS = 500;    // one angry jump (DrinkAlert buzzes on each landing)
    const ANGRY_MS = 3000;

    // Accessories, in unlock order (one every 3 goal days, see Rewards).
    // Hats: party hat, crown, flower, sweatband, cap. Others: the rest
    // (the plant is drawn in the room, not on the hamster).
    enum {
        ACC_NONE,
        ACC_PARTY_HAT,
        ACC_BOW,
        ACC_GLASSES,
        ACC_SCARF,
        ACC_CROWN,
        ACC_FLOWER,
        ACC_SUNGLASSES,
        ACC_SWEATBAND,
        ACC_BOW_TIE,
        ACC_CAP,
        ACC_PLANT,
        ACC_MEDAL
    }

    const SIP_MS = 1200;
    const TILT_MS = 900;
    const REVIVE_MS = 3000;
    const GOAL_MS = 3500;
    const HOP_MS = 500;
    const HYDRATED_HOP_EVERY_MS = 2500;
    const ON_TRACK_HOP_EVERY_MS = 6000;
    const BLINK_EVERY_MS = 4000;
    const BLINK_MS = 260;

    const OUT = 0x550000;
    const CREAM = 0xFFFFAA;
    const ORANGE = 0xFFAA00;
    const PINK = 0xFFAAAA;
    const HOT_PINK = 0xFF55AA;
    const NOSE = 0xAA0055;
    const BLUE = 0x00AAFF;
    const TEAR = 0x55AAFF;
    const BLACK = 0x000000;
    const WHITE = 0xFFFFFF;

    // Per-draw transform (module state, set at the start of draw()).
    var mX as Number = 0;
    var mY as Number = 0;
    var mS as Float = 1.0;
    var mLie as Boolean = false;

    // ---------------------------------------------------------------------
    // Timing

    function reactionMs(reaction as Number) as Number {
        if (reaction == REACT_SIP) { return SIP_MS; }
        if (reaction == REACT_TILT) { return TILT_MS; }
        if (reaction == REACT_REVIVE) { return REVIVE_MS; }
        if (reaction == REACT_GOAL) { return GOAL_MS; }
        if (reaction == REACT_ANGRY) { return ANGRY_MS; }
        return 0;
    }

    // Milliseconds until the next frame is needed.
    function framePeriod(mood as Number, running as Boolean, t as Number, reaction as Number) as Number {
        if (reaction != REACT_NONE) {
            return 80;
        }
        if (running) {
            return 125;
        }
        var every = hopEvery(mood);
        if (every > 0) {
            var q = t % every;
            if (q < HOP_MS || q > every - 300) {
                return 80;
            }
        }
        if (mood == Pet.MOOD_COLLAPSED) {
            return 1000;
        }
        return mood == Pet.MOOD_SLEEPING ? 500 : 250;
    }

    function hopEvery(mood as Number) as Number {
        if (mood == Pet.MOOD_HYDRATED) { return HYDRATED_HOP_EVERY_MS; }
        if (mood == Pet.MOOD_ON_TRACK) { return ON_TRACK_HOP_EVERY_MS; }
        return 0;
    }

    // Height of a hop at time q (0..HOP_MS), as a negative y offset in px.
    function hopAt(q as Number) as Number {
        if (q < 0 || q >= HOP_MS) {
            return 0;
        }
        return -(Math.sin(Math.PI * q / HOP_MS) * 8).toNumber();
    }

    function wave(t as Number, periodMs as Number, amp as Float) as Number {
        return Math.round(Math.sin(2 * Math.PI * (t % periodMs) / periodMs) * amp).toNumber();
    }

    // ---------------------------------------------------------------------
    // Local-coordinate helpers (from the design's drawing code)

    function px(lx as Numeric, ly as Numeric) as Number {
        return mLie ? (mX - ly * mS).toNumber() : (mX + lx * mS).toNumber();
    }

    function py(lx as Numeric, ly as Numeric) as Number {
        return mLie ? (mY + lx * mS).toNumber() : (mY + ly * mS).toNumber();
    }

    function ell(dc as Dc, lx as Numeric, ly as Numeric, rx as Numeric, ry as Numeric, c as Number) as Void {
        var a = (rx * mS).toNumber();
        var b = (ry * mS).toNumber();
        if (mLie) {
            var tmp = a;
            a = b;
            b = tmp;
        }
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(px(lx, ly), py(lx, ly), a, b);
    }

    // Ellipse with the thin brown outline.
    function oell(dc as Dc, lx as Numeric, ly as Numeric, rx as Numeric, ry as Numeric, c as Number) as Void {
        ell(dc, lx, ly, rx + 1.7, ry + 1.7, OUT);
        ell(dc, lx, ly, rx, ry, c);
    }

    function ln(dc as Dc, x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, c as Number, w as Number) as Void {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(w);
        dc.drawLine(px(x1, y1), py(x1, y1), px(x2, y2), py(x2, y2));
        dc.setPenWidth(1);
    }

    function poly(dc as Dc, pts as Array<Array<Numeric> >, c as Number) as Void {
        var out = new Array<[Numeric, Numeric]>[pts.size()];
        for (var i = 0; i < pts.size(); i++) {
            out[i] = [px(pts[i][0], pts[i][1]), py(pts[i][0], pts[i][1])] as [Numeric, Numeric];
        }
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(out);
    }

    function arc(dc as Dc, lx as Numeric, ly as Numeric, r as Numeric, a0 as Number, a1 as Number, c as Number, w as Number) as Void {
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(w);
        dc.drawArc(px(lx, ly), py(lx, ly), (r * mS).toNumber(), Graphics.ARC_COUNTER_CLOCKWISE, a0, a1);
        dc.setPenWidth(1);
    }

    function drop(dc as Dc, lx as Numeric, ly as Numeric, r as Numeric, c as Number) as Void {
        ell(dc, lx, ly, r, r, c);
        poly(dc, [[lx - r, ly - 1], [lx, ly - r * 2.4], [lx + r, ly - 1]] as Array<Array<Numeric> >, c);
    }

    // ---------------------------------------------------------------------
    // The hamster
    //
    //  s        scale (1.0 = design size; about 80 x 110 px)
    //  hat      hat accessory (ACC_* or ACC_NONE)
    //  other    other accessory (ACC_* or ACC_NONE)
    //  fill     share of today's goal drunk, 0..1 (cheeks grow with it)
    //  running  in the hamster wheel (working hard)
    //  t        current time in ms; reaction / rt = active reaction and
    //           ms since it started

    function draw(dc as Dc, x as Number, y as Number, s as Float, mood as Number,
                  hat as Number, other as Number, fill as Float, running as Boolean, t as Number, reaction as Number, rt as Number) as Void {
        var sleeping = mood == Pet.MOOD_SLEEPING;
        var face = mood;
        if (reaction == REACT_SIP || reaction == REACT_REVIVE || reaction == REACT_GOAL) {
            face = Pet.MOOD_HYDRATED;   // happy while reacting
        } else if (reaction == REACT_ANGRY) {
            face = FACE_ANGRY;
        }
        var collapsed = face == Pet.MOOD_COLLAPSED;

        // --- pose ---------------------------------------------------------
        var dx = 0;
        var dy = 0;
        if (!collapsed) {
            dy = sleeping ? wave(t, 4000, 2.0) : wave(t, 2400, 1.5);   // breathing
            var every = hopEvery(face);
            if (every > 0 && reaction == REACT_NONE) {
                dy += hopAt(t % every);
            }
            if (reaction == REACT_SIP) {
                dy += hopAt(rt - (SIP_MS - HOP_MS));
            } else if (reaction == REACT_REVIVE || reaction == REACT_GOAL) {
                dy += hopAt(rt % 700);
            } else if (reaction == REACT_TILT) {
                dx = wave(rt, TILT_MS / 2, 4.0);
            } else if (reaction == REACT_ANGRY) {
                // stomping jumps, landing every ANGRY_JUMP_MS, with a shake
                var q = rt % ANGRY_JUMP_MS;
                dy = -(Math.sin(Math.PI * q / ANGRY_JUMP_MS) * 16).toNumber();
                dx = ((rt / 60) % 2) == 0 ? 2 : -2;
            }
            if (running) {
                dy = ((t / 125) % 2) * 2;
            }
        }

        mX = x + dx;
        mY = y + dy;
        mS = s;
        mLie = collapsed;
        var pen = s >= 0.9 ? 3 : 2;

        // Head and cheeks grow as the day's water goes up (the cheek gauge),
        // and puff extra while sipping.
        if (fill > 1.0) { fill = 1.0; }
        var puff = 36 + 8 * fill;
        var cheek = 7 + 3 * fill;
        if (reaction == REACT_SIP && rt < SIP_MS - HOP_MS) {
            cheek += 2 + ((rt / 150) % 2);
        }
        var blinking = reaction == REACT_NONE && !sleeping && (t % BLINK_EVERY_MS) < BLINK_MS;
        var step = running ? (((t / 125) % 2) == 0 ? 4 : -4) : 0;
        if (reaction == REACT_ANGRY) {
            step = ((rt / ANGRY_JUMP_MS) % 2) == 0 ? 3 : -3;   // stomp
        }

        // Ears
        oell(dc, -24, -26, 10, 10, ORANGE);
        oell(dc, 24, -26, 10, 10, ORANGE);
        ell(dc, -24, -26, 5, 5, PINK);
        ell(dc, 24, -26, 5, 5, PINK);
        // Feet, body, belly, paws
        oell(dc, -14 + step, 70, 9, 5, PINK);
        oell(dc, 14 - step, 70, 9, 5, PINK);
        oell(dc, 0, 44, 28, 26, CREAM);
        ell(dc, 0, 49, 16, 16, WHITE);
        if (face != Pet.MOOD_LAST_WARNING) {
            oell(dc, -27, 38, 7, 5, CREAM);
            oell(dc, 27, 38, 7, 5, CREAM);
        }
        // Head and markings
        oell(dc, 0, 0, puff, 31, CREAM);
        ell(dc, 0, -21, 20, 8, ORANGE);
        ell(dc, -27, 9, cheek, cheek, PINK);
        ell(dc, 27, 9, cheek, cheek, PINK);
        ell(dc, 0, 4, 3, 2, NOSE);

        drawFace(dc, face, pen, blinking, t);
        drawAccessory(dc, other);
        drawAccessory(dc, hat);

        // Extras in screen space
        if (reaction == REACT_ANGRY) {
            // "!!" and steam puffing from the ears
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            dc.drawText(px(44, -44), py(44, -44), Graphics.FONT_SMALL, "!!",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            var steam = (rt / 200) % 3;
            ell(dc, -34 - steam * 3, -38 - steam * 4, 4 + steam, 3 + steam, WHITE);
            ell(dc, 34 + steam * 3, -38 - steam * 4, 4 + steam, 3 + steam, WHITE);
        } else if (reaction == REACT_TILT) {
            dc.setColor(BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(px(36, -50), py(36, -50), Graphics.FONT_XTINY, "?",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (sleeping) {
            drawZ(dc, px(34, -40), py(34, -40), t);
            drawZ(dc, px(34, -40), py(34, -40), t + 1500);
        }
        mLie = false;
    }

    function drawFace(dc as Dc, mood as Number, pen as Number, blinking as Boolean, t as Number) as Void {
        if (mood == FACE_ANGRY) {
            // furious: eyes under brows slanting down to the middle, frown,
            // red cheeks
            ell(dc, -14, -2, 5, 5, BLACK);
            ell(dc, 14, -2, 5, 5, BLACK);
            ln(dc, -23, -14, -7, -8, BLACK, pen);
            ln(dc, 23, -14, 7, -8, BLACK, pen);
            arc(dc, 0, 18, 7, 25, 155, BLACK, 2);
            ell(dc, -27, 9, 8, 8, 0xFF5555);
            ell(dc, 27, 9, 8, 8, 0xFF5555);
            return;
        }
        if (mood == Pet.MOOD_HYDRATED) {
            // closed happy eyes, cat smile
            arc(dc, -14, -1, 5, 0, 180, BLACK, pen);
            arc(dc, 14, -1, 5, 0, 180, BLACK, pen);
            arc(dc, -4, 9, 4, 180, 360, BLACK, 2);
            arc(dc, 4, 9, 4, 180, 360, BLACK, 2);
        } else if (mood == Pet.MOOD_ON_TRACK || mood == Pet.MOOD_SLEEPING) {
            if (blinking || mood == Pet.MOOD_SLEEPING) {
                ln(dc, -18, -3, -10, -3, BLACK, pen);
                ln(dc, 10, -3, 18, -3, BLACK, pen);
            } else {
                ell(dc, -14, -3, 4, 4, BLACK);
                ell(dc, 14, -3, 4, 4, BLACK);
            }
            arc(dc, -4, 9, 4, 180, 360, BLACK, 2);
            arc(dc, 4, 9, 4, 180, 360, BLACK, 2);
        } else if (mood == Pet.MOOD_THIRSTY) {
            // wide eyes, worried brows, tongue out, sweat drop sliding down
            if (blinking) {
                ln(dc, -20, -3, -8, -3, BLACK, pen);
                ln(dc, 8, -3, 20, -3, BLACK, pen);
            } else {
                ell(dc, -14, -3, 6, 6, BLACK);
                ell(dc, 14, -3, 6, 6, BLACK);
                ell(dc, -12, -5, 2, 2, WHITE);
                ell(dc, 16, -5, 2, 2, WHITE);
            }
            ln(dc, -22, -12, -10, -15, BLACK, 2);
            ln(dc, 22, -12, 10, -15, BLACK, 2);
            ell(dc, 0, 14, 6, 5, BLACK);
            ell(dc, 0, 18, 4, 5, HOT_PINK);
            var p = (t % 1800) / 1800.0;
            if (p < 0.85) {
                drop(dc, 40, -14 + 16 * p, 4, TEAR);
            }
        } else if (mood == Pet.MOOD_LAST_WARNING) {
            // crying, pointing a toy water pistol at you
            ell(dc, -14, -3, 6, 6, BLACK);
            ell(dc, 14, -3, 6, 6, BLACK);
            ell(dc, -12, -5, 2, 2, WHITE);
            ell(dc, 16, -5, 2, 2, WHITE);
            var p2 = (t % 1200) / 1200.0;
            drop(dc, -16, 12 + 10 * p2, 4, TEAR);
            drop(dc, 16, 12 + 10 * ((t + 600) % 1200) / 1200.0, 4, TEAR);
            arc(dc, 0, 17, 6, 20, 160, BLACK, 2);
            // toy water pistol: teal body, orange tip, visible tank
            ell(dc, 2, 32, 10, 7, OUT);
            ell(dc, 2, 32, 8, 5, 0xAAFFFF);
            poly(dc, [[-25, 34], [13, 34], [13, 61], [0, 61], [0, 48], [-25, 48]] as Array<Array<Numeric> >, OUT);
            poly(dc, [[-23, 36], [11, 36], [11, 59], [2, 59], [2, 46], [-23, 46]] as Array<Array<Numeric> >, 0x00AAAA);
            poly(dc, [[-31, 37], [-23, 37], [-23, 45], [-31, 45]] as Array<Array<Numeric> >, ORANGE);
            if (((t / 250) % 2) == 0) {     // squirt flickers
                ln(dc, -35, 39, -44, 36, TEAR, 2);
                ln(dc, -35, 43, -45, 46, TEAR, 2);
            }
            oell(dc, -8, 52, 7, 5, CREAM);
            oell(dc, 14, 50, 7, 5, CREAM);
        } else {
            // collapsed: crossed eyes, tongue out
            ln(dc, -18, -7, -10, 1, BLACK, pen);
            ln(dc, -18, 1, -10, -7, BLACK, pen);
            ln(dc, 10, -7, 18, 1, BLACK, pen);
            ln(dc, 10, 1, 18, -7, BLACK, pen);
            ln(dc, -6, 13, 6, 13, BLACK, 2);
            ell(dc, 0, 18, 4, 5, HOT_PINK);
        }
    }

    function drawAccessory(dc as Dc, acc as Number) as Void {
        var P = HOT_PINK;
        if (acc == ACC_PARTY_HAT) {
            poly(dc, [[-15, -26], [0, -58], [15, -26]] as Array<Array<Numeric> >, OUT);
            poly(dc, [[-11, -28], [0, -53], [11, -28]] as Array<Array<Numeric> >, P);
            ell(dc, 0, -57, 5, 5, ORANGE);
        } else if (acc == ACC_CROWN) {
            poly(dc, [[-17, -25], [-17, -44], [-8, -35], [0, -48], [8, -35], [17, -44], [17, -25]] as Array<Array<Numeric> >, OUT);
            poly(dc, [[-14, -27], [-14, -39], [-8, -32], [0, -43], [8, -32], [14, -39], [14, -27]] as Array<Array<Numeric> >, ORANGE);
        } else if (acc == ACC_FLOWER) {
            // flower tucked by the right ear
            ell(dc, 14, -34, 5, 5, WHITE);
            ell(dc, 22, -38, 5, 5, WHITE);
            ell(dc, 22, -30, 5, 5, WHITE);
            ell(dc, 30, -34, 5, 5, WHITE);
            ell(dc, 22, -34, 4, 4, 0xFFFF00);
        } else if (acc == ACC_SWEATBAND) {
            ell(dc, 0, -22, 33, 7, OUT);
            ell(dc, 0, -22, 31, 5, 0xFF0000);
            ln(dc, -28, -22, 28, -22, WHITE, 2);
        } else if (acc == ACC_CAP) {
            ell(dc, 0, -27, 25, 13, OUT);
            ell(dc, 0, -27, 23, 11, 0x0055FF);
            poly(dc, [[10, -22], [42, -20], [40, -15], [10, -17]] as Array<Array<Numeric> >, 0x0000AA);
            ell(dc, 0, -37, 3, 3, WHITE);
        } else if (acc == ACC_BOW) {
            poly(dc, [[0, 30], [-14, 23], [-14, 37]] as Array<Array<Numeric> >, P);
            poly(dc, [[0, 30], [14, 23], [14, 37]] as Array<Array<Numeric> >, P);
            ell(dc, 0, 30, 3, 3, NOSE);
        } else if (acc == ACC_BOW_TIE) {
            poly(dc, [[0, 30], [-11, 24], [-11, 36]] as Array<Array<Numeric> >, 0x0000AA);
            poly(dc, [[0, 30], [11, 24], [11, 36]] as Array<Array<Numeric> >, 0x0000AA);
            ell(dc, 0, 30, 3, 3, BLACK);
        } else if (acc == ACC_GLASSES) {
            arc(dc, -14, -3, 10, 0, 360, BLACK, 2);
            arc(dc, 14, -3, 10, 0, 360, BLACK, 2);
            ln(dc, -4, -3, 4, -3, BLACK, 2);
        } else if (acc == ACC_SUNGLASSES) {
            ell(dc, -14, -3, 10, 8, BLACK);
            ell(dc, 14, -3, 10, 8, BLACK);
            ln(dc, -4, -4, 4, -4, BLACK, 3);
            ell(dc, -18, -6, 3, 2, 0x555555);
            ell(dc, 10, -6, 3, 2, 0x555555);
        } else if (acc == ACC_SCARF) {
            ell(dc, 0, 30, 27, 7, OUT);
            ell(dc, 0, 30, 25, 5, 0xFF0000);
            poly(dc, [[8, 32], [18, 32], [20, 54], [10, 54]] as Array<Array<Numeric> >, 0xAA0000);
        } else if (acc == ACC_MEDAL) {
            ln(dc, -8, 26, 0, 40, 0x0055FF, 3);
            ln(dc, 8, 26, 0, 40, 0x0055FF, 3);
            ell(dc, 0, 44, 7, 7, OUT);
            ell(dc, 0, 44, 6, 6, 0xFFAA00);
            ell(dc, 0, 44, 3, 3, 0xFFFF55);
        }
        // ACC_PLANT is drawn in the room by the view (plant()).
    }

    // Potted plant for the room (bottom-left of the floor).
    function plant(dc as Dc, x as Number, y as Number) as Void {
        dc.setColor(0x00AA00, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(x - 8, y - 22, 6, 12);
        dc.fillEllipse(x + 8, y - 22, 6, 12);
        dc.fillEllipse(x, y - 28, 6, 14);
        dc.setColor(OUT, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x - 13, y - 12], [x + 13, y - 12], [x + 9, y + 6], [x - 9, y + 6]]);
        dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x - 11, y - 10], [x + 11, y - 10], [x + 7, y + 4], [x - 7, y + 4]]);
    }

    // ---------------------------------------------------------------------
    // Scene pieces

    // Hamster wheel (drawn behind the hamster while working hard).
    function drawWheel(dc as Dc, x as Number, y as Number, r as Number, t as Number) as Void {
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawCircle(x, y, r);
        dc.setPenWidth(1);
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        var base = (t % 1000) / 1000.0 * 2 * Math.PI;
        for (var i = 0; i < 6; i++) {
            var a = base + i * Math.PI / 3;
            dc.drawLine(x, y, x + (Math.cos(a) * r).toNumber(), y + (Math.sin(a) * r).toNumber());
        }
        // stand
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(x, y, x - r / 2, y + r + 8);
        dc.drawLine(x, y, x + r / 2, y + r + 8);
        dc.setPenWidth(1);
    }

    // A "z" that floats up and fades out over 3 s.
    function drawZ(dc as Dc, x as Number, y as Number, t as Number) as Void {
        var p = (t % 3000) / 3000.0;
        if (p > 0.9) {
            return;
        }
        dc.setColor(p < 0.6 ? 0xFFFFFF : 0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + (10 * p).toNumber(), y - (24 * p).toNumber(), Graphics.FONT_XTINY, "z",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Four-point sparkle star; `twinkle` (0/1) makes it pulse.
    function star(dc as Dc, x as Number, y as Number, r as Number, c as Number) as Void {
        var q = r / 3;
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x, y - r], [x + q, y - q], [x + r, y], [x + q, y + q],
                        [x, y + r], [x - q, y + q], [x - r, y], [x - q, y - q]]);
    }
}
