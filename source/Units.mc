import Toybox.Application;
import Toybox.Lang;

// Everything the user sees is in glasses of water, so nobody has to think
// about units. A glass is 250 ml; water is still stored in ml underneath.
// Amounts come in half-glass steps (1/2, 1, 2 on the quick-add screen).
(:background)
module Units {

    const GLASS_ML = 250;

    // What START / the "+1 glass" action adds.
    function defaultAddMl() as Number {
        return GLASS_ML;
    }

    // Quick-add choices: 1/2, 1 and 2 glasses.
    function quickAmountsMl() as Array<Number> {
        return [GLASS_ML / 2, GLASS_ML, GLASS_ML * 2];
    }

    // "3", "3.5" (half-glass steps).
    function glasses(ml as Number) as String {
        var halves = (ml * 2 + GLASS_ML / 2) / GLASS_ML;
        return (halves % 2 == 0) ? (halves / 2).format("%d") : (halves / 2).format("%d") + ".5";
    }

    // A single drink: "1/2 glass", "1 glass", "2 glasses".
    function amount(ml as Number) as String {
        if (ml * 2 == GLASS_ML) {
            return "1/2 glass";
        }
        var n = glasses(ml);
        return n + (n.equals("1") ? " glass" : " glasses");
    }

    // Just the number, for the quick-add circles: "1/2", "1", "2".
    function amountNumber(ml as Number) as String {
        return ml * 2 == GLASS_ML ? "1/2" : glasses(ml);
    }

    function label() as String {
        return "glasses";
    }

    // A total: "9 glasses" ("1 glass").
    function total(ml as Number) as String {
        return amount(ml);
    }

    // "3 / 9 glasses".
    function pair(ml as Number, goalMl as Number) as String {
        return glasses(ml) + " / " + glasses(goalMl) + " glasses";
    }
}
