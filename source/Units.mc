import Toybox.Application;
import Toybox.Lang;

// Display units. Water is always stored in ml; this only changes how it's
// shown and which preset amounts are offered (ml: 150/250/500, oz: 5/8/16).
(:background)
module Units {

    enum {
        ML,
        OZ
    }

    const KEY_UNIT = "unit";
    const ML_PER_OZ = 29.5735;

    function unit() as Number {
        var v = Storage.getValue(KEY_UNIT);
        return (v instanceof Number && v == OZ) ? OZ : ML;
    }

    function toggle() as Number {
        var u = unit() == ML ? OZ : ML;
        Storage.setValue(KEY_UNIT, u);
        return u;
    }

    function isOz() as Boolean {
        return unit() == OZ;
    }

    function ozToMl(oz as Number) as Number {
        return (oz * ML_PER_OZ + 0.5).toNumber();
    }

    function mlToOz(ml as Number) as Number {
        return (ml / ML_PER_OZ + 0.5).toNumber();
    }

    // Preset amounts in ml for the current unit.
    function quickAmountsMl() as Array<Number> {
        return isOz() ? [ozToMl(5), ozToMl(8), ozToMl(16)] : [150, 250, 500];
    }

    // What START / "+250" adds.
    function defaultAddMl() as Number {
        return isOz() ? ozToMl(8) : 250;
    }

    // A single drink: "250 ml" / "8 oz".
    function amount(ml as Number) as String {
        return isOz() ? mlToOz(ml).format("%d") + " oz" : ml.format("%d") + " ml";
    }

    // Just the number of a drink (for the quick-add circles): "250" / "8".
    function amountNumber(ml as Number) as String {
        return isOz() ? mlToOz(ml).format("%d") : ml.format("%d");
    }

    function label() as String {
        return isOz() ? "oz" : "ml";
    }

    // A total without unit: "1.2" (litres) / "41" (oz).
    function totalNumber(ml as Number) as String {
        return isOz() ? mlToOz(ml).format("%d") : (ml / 100 / 10.0).format("%.1f");
    }

    // A total with unit: "1.2 L" / "41 oz".
    function total(ml as Number) as String {
        return totalNumber(ml) + (isOz() ? " oz" : " L");
    }

    // "1.2 / 2.0 L" / "41 / 68 oz".
    function pair(ml as Number, goalMl as Number) as String {
        return totalNumber(ml) + " / " + total(goalMl);
    }
}
