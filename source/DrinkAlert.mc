import Toybox.Attention;
import Toybox.Lang;
import Toybox.System;

// "Time to drink" alert played by the foreground app. Not (:background):
// Toybox.Attention isn't available to background services.
module DrinkAlert {

    const SOUND_ON = true;   // set false for vibration only (no bell)

    // "Time to drink": a single ring of a bell plus a double buzz.
    // The bell respects the watch's own Sounds setting (tonesOn).
    function play() as Void {
        bell();
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(75, 300),
                new Attention.VibeProfile(0, 150),
                new Attention.VibeProfile(75, 300)
            ] as Array<Attention.VibeProfile>);
        }
    }

    // One ring of a bell. Watch speakers only play plain tones, so: a short
    // bright strike, then the bell's note ringing out in shorter and shorter
    // pulses so it sounds like it fades away.
    function bell() as Void {
        if (!SOUND_ON || !System.getDeviceSettings().tonesOn) {
            return;
        }
        if (Attention has :ToneProfile) {
            Attention.playTone({
                :toneProfile => [
                    new Attention.ToneProfile(3520, 35),    // strike
                    new Attention.ToneProfile(2093, 220),   // ring...
                    new Attention.ToneProfile(0, 20),
                    new Attention.ToneProfile(2093, 150),
                    new Attention.ToneProfile(0, 30),
                    new Attention.ToneProfile(2093, 90),
                    new Attention.ToneProfile(0, 40),
                    new Attention.ToneProfile(2093, 50)     // ...fading
                ] as Array<Attention.ToneProfile>
            });
        } else if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALERT_HI);
        }
    }

    // The angry "drink now!" alert: the bell, then a buzz on every landing
    // of the hamster's angry jumps (HamsterArt.ANGRY_JUMP_MS apart).
    // Attention.vibrate() takes at most 8 VibeProfiles, so one call covers
    // 4 jumps (4 x buzz + gap); call angryBuzzes() again to keep going.
    const ANGRY_BUZZES = 4;
    const ANGRY_BUZZ_SPAN_MS = 2000;   // ANGRY_BUZZES * HamsterArt.ANGRY_JUMP_MS

    function angry() as Void {
        bell();
        angryBuzzes();
    }

    function angryBuzzes() as Void {
        if (Attention has :vibrate) {
            var p = [] as Array<Attention.VibeProfile>;
            var gap = HamsterArt.ANGRY_JUMP_MS - 120;
            for (var i = 0; i < ANGRY_BUZZES; i++) {
                p.add(new Attention.VibeProfile(100, 120));
                p.add(new Attention.VibeProfile(0, gap));
            }
            Attention.vibrate(p);
        }
    }

}
