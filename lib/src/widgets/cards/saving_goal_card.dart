import 'package:flutter/material.dart';
import '../../utils/meai_localizations.dart';
import 'amount_currency_widget.dart';
import 'rounded_container_widget.dart';

/// Saving goal card widget
class SavingGoalCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double amountSaved;
  final double amountRemaining;
  final double targetAmount;
  final String targetDate;
  final String? fontFamily;
  final String lang;

  const SavingGoalCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.amountSaved,
    required this.amountRemaining,
    required this.targetAmount,
    required this.targetDate,
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
            Colors.white.withValues(alpha: 0.7), // top-right
            Colors.white.withValues(alpha: 0.7), // bottom-left
            const Color(0xFFA829F0), // bottom-right
            const Color(0xFF5E308B), // fade
            Colors.white.withValues(alpha: 0.7), // closing loop
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
            // Header with goal info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  child: imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            imageUrl!,
                            width: 25,
                            height: 25,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 25,
                                height: 25,
                                decoration: const BoxDecoration(
                                  color: Color(0xfff6f4fe),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.savings, size: 15),
                              );
                            },
                          ),
                        )
                      : ClipOval(
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              color: Color(0xfff6f4fe),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.savings, size: 15),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff0f0f0f), // dark1000
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Progress section
            Column(
              children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AmountCurrencyWidget(
                            amount: amountSaved.toStringAsFixed(3),
                            currencyColor: const Color(0xff0f0f0f), // dark1000
                            fontSize: 15,
                            fontFamily: fontFamily,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            MeAiLocalizations.saved(lang),
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9292A0), // dark400
                              fontFamily: fontFamily,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AmountCurrencyWidget(
                            amount: targetAmount.toStringAsFixed(3),
                            currencyColor: const Color(0xff0f0f0f), // dark1000
                            fontSize: 15,
                            fontFamily: fontFamily,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            MeAiLocalizations.goal(lang),
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9292A0), // dark400
                              fontFamily: fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildProgressBar(),
                  if (amountRemaining > 0) ...[
                    const SizedBox(height: 20),
                    RoundedContainerWidget(
                      paddingVertical: 10,
                      content: Row(
                        children: [
                          Text(
                            MeAiLocalizations.remaining(lang),
                            style: TextStyle(
                              color: const Color(0xff686878), // dark600
                              fontWeight: FontWeight.w300,
                              fontSize: 15,
                              fontFamily: fontFamily,
                            ),
                          ),
                          Expanded(child: Container()),
                          AmountCurrencyWidget(
                            amount: amountRemaining.abs().toStringAsFixed(3),
                            amountColor: const Color(0xff8d41f1), // mePurple800
                            fontSize: 18,
                            amountFontWeight: FontWeight.w500,
                            fontFamily: fontFamily,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildProgressBar() {
    final savedPercent = targetAmount > 0 ? (amountSaved / targetAmount * 100).toInt() : 0;
    final remainingPercent = targetAmount > 0 ? ((targetAmount - amountSaved) / targetAmount * 100).toInt() : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF0F1F3), // dark50
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: savedPercent.clamp(0, 100),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xff009201), // grass600
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              height: 12,
            ),
          ),
          Expanded(
            flex: remainingPercent.clamp(0, 100),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xffF0F1F3), // dark50
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              height: 12,
            ),
          ),
        ],
      ),
    );
  }
}

