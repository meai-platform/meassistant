import 'package:flutter/material.dart';
import 'amount_currency_widget.dart';

/// Amount value card widget
class AmountValueCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final double amount;
  final String currency;
  final String? fontFamily;

  const AmountValueCard({
    super.key,
    required this.title,
    this.imageUrl,
    required this.amount,
    this.currency = 'BHD',
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            if (imageUrl != null) ...[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF7C3AED),
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
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
                  amount: amount.toStringAsFixed(3),
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
    );
  }
}

