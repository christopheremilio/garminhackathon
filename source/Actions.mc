import Toybox.Lang;

// User actions shared by the buttons, the quick-add screen, the in-app
// reminder and the demo. Each one changes the data and picks the hamster's
// reaction.
module Actions {

    // Log a drink today: revive if it had collapsed, party if this drink
    // reaches the goal, otherwise sip.
    function logWater(ml as Number) as Void {
        var wasAway = Pet.isAway();
        var wasCollapsed = Pet.currentMood() == Pet.MOOD_COLLAPSED;
        var wasMet = WaterLog.goalReached();
        WaterLog.add(ml, null);
        Screen.newItem = Rewards.checkDay(WaterLog.today());
        Screen.reactAmount = ml;
        if (wasAway) {
            Screen.react(HamsterArt.REACT_WALK_IN);     // WaterLog.add brought Coco back
        } else if (wasCollapsed) {
            Screen.react(HamsterArt.REACT_REVIVE);
        } else if (!wasMet && WaterLog.goalReached()) {
            Screen.react(HamsterArt.REACT_GOAL);
        } else {
            Screen.react(HamsterArt.REACT_SIP);
        }
    }

    function undo() as Void {
        WaterLog.undoLast();
        Screen.react(HamsterArt.REACT_TILT);
    }

    function snooze() as Void {
        WaterLog.snooze(WaterLog.nowSec());
        Screen.changed();
    }

    function resetToday() as Void {
        WaterLog.resetAll();
        WaterLog.startClock();     // no instant reminder after resetting
        Places.clearLastPlace();   // lets arrival reminders fire again
        Screen.changed();
    }
}
