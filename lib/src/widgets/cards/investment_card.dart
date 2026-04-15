import 'package:flutter/material.dart';
import '../../utils/meai_localizations.dart';
import 'amount_currency_widget.dart';
import 'rounded_container_widget.dart';
import 'separator_line_widget.dart';

/// Investment card widget
class InvestmentCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? period;
  final double expectedProfitRate;
  final double? amount;
  final double? expectedProfitAtMaturity;
  final double? amountAtMaturityWithProfit;
  final String? fontFamily;
  final String lang;

  const InvestmentCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.period,
    required this.expectedProfitRate,
    this.amount,
    this.expectedProfitAtMaturity,
    this.amountAtMaturityWithProfit,
    this.fontFamily,
    this.lang = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
      decoration: BoxDecoration(
        gradient: SweepGradient(
          startAngle: 0,
          endAngle: 6.28319, // 2 * pi
          colors: [
            const Color(0xFFA829F0), // top-left
            const Color(0xFF5E308B), // fade
            Colors.white.withOpacity(0.7), // top-right
            Colors.white.withOpacity(0.7), // bottom-left
            const Color(0xFFA829F0), // bottom-right
            const Color(0xFF5E308B), // fade
            Colors.white.withOpacity(0.7), // closing loop
          ],
          stops: const [0.0, 0.15, 0.35, 0.45, 0.50, 0.70, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(1), // Border thickness
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xfff6f4fe),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.trending_up, size: 24),
                          );
                        },
                      )
                    : Container(
                        child: const Icon(
                          Icons.trending_up,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: const Color(0xff0f0f0f), // dark1000
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          fontFamily: fontFamily,
                        ),
                      ),
                      Text(
                        MeAiLocalizations.investment(lang),
                        style: TextStyle(
                          color: const Color(0xFF9292A0), // dark400
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const SeparatorLineWidget(),
            const SizedBox(height: 10),
            Row(
              children: [
                if (period != null) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MeAiLocalizations.period(lang),
                          style: TextStyle(
                            color: const Color(0xFF9292A0), // dark400
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            fontFamily: fontFamily,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          period!,
                          style: TextStyle(
                            color: const Color(0xff0f0f0f), // dark1000
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MeAiLocalizations.expectedProfitRate(lang),
                        style: TextStyle(
                          color: const Color(0xFF9292A0), // dark400
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          fontFamily: fontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expectedProfitRate.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: const Color(0xff0f0f0f), // dark1000
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (amount != null || expectedProfitAtMaturity != null) const SizedBox(height: 16),
            Row(
              children: [
                if (amount != null) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MeAiLocalizations.amount(lang),
                          style: TextStyle(
                            color: const Color(0xFF9292A0), // dark400
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            fontFamily: fontFamily,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AmountCurrencyWidget(
                          amount: amount!.toStringAsFixed(3),
                          amountFontWeight: FontWeight.w600,
                          fontSize: 18,
                          currencyColor: const Color(0xFF9292A0), // dark400
                          amountColor: const Color(0xff0f0f0f), // dark1000
                          fontFamily: fontFamily,
                        ),
                      ],
                    ),
                  ),
                ],
                if (expectedProfitAtMaturity != null) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MeAiLocalizations.profitAtMaturity(lang),
                          style: TextStyle(
                            color: const Color(0xFF9292A0), // dark400
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            fontFamily: fontFamily,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AmountCurrencyWidget(
                          amount: expectedProfitAtMaturity!.toStringAsFixed(3),
                          amountFontWeight: FontWeight.w600,
                          fontSize: 18,
                          currencyColor: const Color(0xFF9292A0), // dark400
                          amountColor: const Color(0xff009201), // grass600
                          fontFamily: fontFamily,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (amountAtMaturityWithProfit != null) ...[
              const SizedBox(height: 16),
              RoundedContainerWidget(
                color: const Color(0xfff6f4fe), // mePurple25
                content: Column(
                  children: [
                    Text(
                      MeAiLocalizations.expectedAmountWithProfitAtMaturity(lang),
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF9292A0), // dark400
                        fontWeight: FontWeight.w300,
                        fontFamily: fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AmountCurrencyWidget(
                          amount: amountAtMaturityWithProfit!.toStringAsFixed(3),
                          fontSize: 24,
                          amountFontWeight: FontWeight.w500,
                          currencyColor: const Color(0xFF9292A0), // dark400
                          amountColor: const Color(0xff0f0f0f), // dark1000
                          fontFamily: fontFamily,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

