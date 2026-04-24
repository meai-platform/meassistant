import 'package:flutter/material.dart';
import '../../utils/meai_localizations.dart';
import 'amount_currency_widget.dart';
import 'rounded_container_widget.dart';

/// Spending limit alert card widget
class SpendingLimitAlertCard extends StatelessWidget {
  final String customerName;
  final String customerImageUrl;
  final String currency;
  final double limitAmountOnCategory;
  final double currentSpendOnCategory;
  final String? categoryImageUrl;
  final String? categoryName;
  final String descriptionOfCurrentStatus;
  final String? fontFamily;
  final String lang;

  const SpendingLimitAlertCard({
    super.key,
    required this.customerName,
    required this.customerImageUrl,
    this.currency = 'BHD',
    required this.limitAmountOnCategory,
    required this.currentSpendOnCategory,
    this.categoryImageUrl,
    this.categoryName,
    required this.descriptionOfCurrentStatus,
    this.fontFamily,
    this.lang = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final remaining = limitAmountOnCategory - currentSpendOnCategory;
    final progress = limitAmountOnCategory > 0 ? currentSpendOnCategory / limitAmountOnCategory : 0.0;
    final isOverLimit = progress > 1.0;

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
            // Header with category info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        categoryName ?? MeAiLocalizations.categoryLimit(lang),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff0f0f0f), // dark1000
                          fontFamily: fontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descriptionOfCurrentStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xff686878), // dark600
                          fontWeight: FontWeight.w300,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Spending progress
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
                            amount: currentSpendOnCategory.toStringAsFixed(3),
                            currencyColor: const Color(0xff0f0f0f), // dark1000
                            fontSize: 15,
                            fontFamily: fontFamily,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            MeAiLocalizations.spent(lang),
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
                            amount: limitAmountOnCategory.toStringAsFixed(3),
                            currencyColor: const Color(0xff0f0f0f), // dark1000
                            fontSize: 15,
                            fontFamily: fontFamily,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            MeAiLocalizations.limit(lang),
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
                  _buildProgressBar(isOverLimit),
                  const SizedBox(height: 20),
                  RoundedContainerWidget(
                    content: Row(
                      children: [
                        Text(
                          isOverLimit ? MeAiLocalizations.overspent(lang) : MeAiLocalizations.remaining(lang),
                          style: TextStyle(
                            color: const Color(0xff686878), // dark600
                            fontWeight: FontWeight.w300,
                            fontSize: 15,
                            fontFamily: fontFamily,
                          ),
                        ),
                        Expanded(child: Container()),
                        AmountCurrencyWidget(
                          amount: remaining.abs().toStringAsFixed(3),
                          amountColor: isOverLimit ? const Color(0xffF76C6C) : const Color(0xff009201), // red600 : grass600
                          fontSize: 18,
                          amountFontWeight: FontWeight.w500,
                          fontFamily: fontFamily,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildProgressBar(bool isOverLimit) {
    final spentPercent = limitAmountOnCategory > 0 
        ? ((currentSpendOnCategory / limitAmountOnCategory * 100).clamp(0, 100)).toInt() 
        : 0;
    final remainingPercent = limitAmountOnCategory > 0 
        ? (((limitAmountOnCategory - currentSpendOnCategory) / limitAmountOnCategory * 100).clamp(0, 100)).toInt() 
        : 0;

    return Row(
      children: [
        Expanded(
          flex: spentPercent,
          child: Container(
            decoration: BoxDecoration(
              color: isOverLimit ? const Color(0xffF76C6C) : const Color(0xff009201), // red600 : grass600
              borderRadius: BorderRadius.circular(2),
            ),
            height: 6,
          ),
        ),
        Expanded(
          flex: remainingPercent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xffF0F1F3), // dark50
              borderRadius: BorderRadius.circular(2),
            ),
            height: 6,
          ),
        ),
      ],
    );
  }
}

