class CalculationResult {
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final double taxAmount;
  final double additionalChargesTotal;
  final double reimbursablesTotal;
  final double rawTotalAmount;
  final double totalAmount;
  final double depositAmount;
  final double balanceDue;
  final double whtAmount;
  final double netAmountPayable;

  CalculationResult({
    required this.subtotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.taxAmount,
    this.additionalChargesTotal = 0.0,
    this.reimbursablesTotal = 0.0,
    required this.rawTotalAmount,
    required this.totalAmount,
    required this.depositAmount,
    required this.balanceDue,
    this.whtAmount = 0.0,
    this.netAmountPayable = 0.0,
  });
}

class DocumentCalculator {
  static double calculateLineTotal({
    required double quantity,
    required double unitPrice,
    double discountPercent = 0.0,
  }) {
    final rawTotal = quantity * unitPrice;
    if (discountPercent <= 0) return rawTotal;
    final discount = rawTotal * (discountPercent / 100.0);
    return (rawTotal - discount).clamp(0.0, double.infinity);
  }

  static double applyRounding(double amount, String rule) {
    switch (rule.toLowerCase()) {
      case 'nearest 1':
      case '1':
        return amount.roundToDouble();
      case 'nearest 5':
      case '5':
        return (amount / 5.0).roundToDouble() * 5.0;
      case 'nearest 10':
      case '10':
        return (amount / 10.0).roundToDouble() * 10.0;
      case 'nearest 100':
      case '100':
        return (amount / 100.0).roundToDouble() * 100.0;
      case 'none':
      default:
        return amount;
    }
  }

  static CalculationResult calculate({
    required List<double> lineTotals,
    double docDiscountPercent = 0.0,
    double docDiscountFixed = 0.0,
    bool isTaxEnabled = true,
    double taxPercent = 16.0,
    bool isTaxInclusive = false,
    double depositPercent = 0.0,
    double depositFixed = 0.0,
    double additionalChargesTotal = 0.0,
    double reimbursablesTotal = 0.0,
    String roundingRule = 'none',
    double whtPercent = 0.0,
    bool whtCalculateOnFeesOnly = true,
    bool isWhtPostVat = false,
  }) {
    // 1. Subtotal from lines
    final subtotal = lineTotals.fold<double>(0.0, (sum, val) => sum + val);

    // 2. Document-level discount
    double calculatedDiscount = 0.0;
    if (docDiscountPercent > 0) {
      calculatedDiscount = subtotal * (docDiscountPercent / 100.0);
    } else if (docDiscountFixed > 0) {
      calculatedDiscount = docDiscountFixed;
    }
    calculatedDiscount = calculatedDiscount.clamp(0.0, subtotal);
    final discountedSubtotal = subtotal - calculatedDiscount;

    // 3. Tax Calculation (16% VAT default)
    double calculatedTax = 0.0;
    double taxableBase = discountedSubtotal;

    if (isTaxEnabled && taxPercent > 0) {
      if (isTaxInclusive) {
        calculatedTax =
            taxableBase - (taxableBase / (1.0 + (taxPercent / 100.0)));
      } else {
        calculatedTax = taxableBase * (taxPercent / 100.0);
      }
    }

    // 4. Gross total before rounding
    double rawTotal = isTaxInclusive
        ? taxableBase + additionalChargesTotal + reimbursablesTotal
        : taxableBase +
              calculatedTax +
              additionalChargesTotal +
              reimbursablesTotal;

    // 5. Apply Rounding
    final total = applyRounding(rawTotal, roundingRule);

    // 6. Withholding Tax (WHT) calculation
    double whtBase = whtCalculateOnFeesOnly
        ? discountedSubtotal
        : (isWhtPostVat ? total : (taxableBase + calculatedTax));
    double calculatedWht = 0.0;
    if (whtPercent > 0) {
      calculatedWht = whtBase * (whtPercent / 100.0);
    }
    final netPayable = (total - calculatedWht).clamp(0.0, double.infinity);

    // 7. Deposit & Balance Due Calculation
    double calculatedDeposit = 0.0;
    if (depositPercent > 0) {
      calculatedDeposit = total * (depositPercent / 100.0);
    } else if (depositFixed > 0) {
      calculatedDeposit = depositFixed;
    }
    calculatedDeposit = calculatedDeposit.clamp(0.0, total);
    final balance = (total - calculatedDeposit).clamp(0.0, double.infinity);

    return CalculationResult(
      subtotal: subtotal,
      discountAmount: calculatedDiscount,
      taxableAmount: discountedSubtotal,
      taxAmount: calculatedTax,
      additionalChargesTotal: additionalChargesTotal,
      reimbursablesTotal: reimbursablesTotal,
      rawTotalAmount: rawTotal,
      totalAmount: total,
      depositAmount: calculatedDeposit,
      balanceDue: balance,
      whtAmount: calculatedWht,
      netAmountPayable: netPayable,
    );
  }
}
