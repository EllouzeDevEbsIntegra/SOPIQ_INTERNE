package com.poscaisse.service;

import java.math.BigDecimal;
import java.math.RoundingMode;

/** Financial helpers: all amounts are scale-3 BigDecimal (TND millimes). */
public final class Money {
    private Money() {}
    public static final int SCALE = 3;
    public static final BigDecimal HUNDRED = new BigDecimal("100");

    public static BigDecimal r(BigDecimal v) { return (v == null ? BigDecimal.ZERO : v).setScale(SCALE, RoundingMode.HALF_UP); }
    public static BigDecimal nz(BigDecimal v) { return v == null ? BigDecimal.ZERO : v; }
    public static BigDecimal pct(BigDecimal base, BigDecimal percent) {
        if (base == null || percent == null || percent.signum() == 0) return BigDecimal.ZERO.setScale(SCALE);
        return r(base.multiply(percent).divide(HUNDRED, 6, RoundingMode.HALF_UP));
    }
    /** Tax portion of a tax-inclusive amount. */
    public static BigDecimal taxIncluded(BigDecimal grossInclTax, BigDecimal ratePercent) {
        if (grossInclTax == null || ratePercent == null || ratePercent.signum() == 0) return BigDecimal.ZERO.setScale(SCALE);
        BigDecimal divisor = HUNDRED.add(ratePercent);
        return r(grossInclTax.subtract(grossInclTax.multiply(HUNDRED).divide(divisor, 6, RoundingMode.HALF_UP)));
    }
    public static boolean isPositive(BigDecimal v) { return v != null && v.signum() > 0; }
}
