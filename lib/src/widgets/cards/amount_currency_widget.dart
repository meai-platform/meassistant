import 'package:flutter/material.dart';

/// Widget for displaying amount with currency
class AmountCurrencyWidget extends StatelessWidget {
  const AmountCurrencyWidget({
    super.key,
    this.currency = "BHD",
    required this.amount,
    this.fontSize = 18,
    this.currencyColor = const Color(0xFF9292A0), // dark400
    this.amountColor = const Color(0xff26262B), // dark900
    this.currencyFontWeight = FontWeight.w300,
    this.amountFontWeight = FontWeight.w500,
    this.hideCurrency = false,
    this.isSmallerFractions = false,
    this.showPositiveSign = false,
    this.isCenterAlign = false,
    this.fontFamily,
  });

  final String currency;
  final String amount;
  final double fontSize;
  final Color currencyColor;
  final Color amountColor;
  final FontWeight currencyFontWeight;
  final FontWeight amountFontWeight;
  final bool hideCurrency;
  final bool isSmallerFractions;
  final bool showPositiveSign;
  final bool isCenterAlign;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final parts = amount.split(".");
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : "000";

    // Always render the amount LTR so that currency + number ordering
    // (e.g. "BHD 12.500") is preserved even when the parent card is RTL.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment:
            isCenterAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (!hideCurrency)
            Text(
              currency,
              style: TextStyle(
                color: currencyColor,
                fontWeight: currencyFontWeight,
                fontSize: fontSize * (isSmallerFractions ? 0.4 : 0.5),
                fontFamily: fontFamily,
              ),
            ),
          if (!hideCurrency) const SizedBox(width: 3),
          if (showPositiveSign && double.tryParse(amount) != null && double.parse(amount) > 0)
            Text(
              "+",
              style: TextStyle(
                color: amountColor,
                fontWeight: amountFontWeight,
                fontSize: fontSize,
                fontFamily: fontFamily,
              ),
            ),
          Text(
            "$integerPart.",
            style: TextStyle(
              color: amountColor,
              fontWeight: amountFontWeight,
              fontSize: fontSize,
              fontFamily: fontFamily,
            ),
          ),
          Text(
            decimalPart,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w400,
              fontSize: fontSize * (isSmallerFractions ? 0.5 : 0.66),
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

