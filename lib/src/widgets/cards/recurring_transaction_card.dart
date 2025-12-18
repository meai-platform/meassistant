import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'amount_currency_widget.dart';
import 'rounded_container_widget.dart';
import 'recurring_icon.dart';

/// Recurring transaction card widget
class RecurringTransactionCard extends StatelessWidget {
  final String? merchantImageUrl;
  final String? categoryName;
  final String? merchantName;
  final double recurringTransactionAmount;
  final String currency;
  final double overallSpentAmount;
  final int numberOfTransactions;
  final String firstPaymentDate;
  final String expectedNextPaymentDate;
  final String? fontFamily;

  const RecurringTransactionCard({
    super.key,
    this.merchantImageUrl,
    this.categoryName,
    this.merchantName,
    required this.recurringTransactionAmount,
    this.currency = 'BHD',
    required this.overallSpentAmount,
    required this.numberOfTransactions,
    required this.firstPaymentDate,
    required this.expectedNextPaymentDate,
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
            // Header with merchant info and recurring amount
            Row(
              children: [
                Container(
                  child: merchantImageUrl != null
                      ? RecurringIcon(img: merchantImageUrl!)
                      : Stack(
                          children: [
                            Center(
                              child: Icon(
                                _getIconForCategory(categoryName ?? ''),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.repeat,
                                  color: Colors.orange,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchantName ?? 'Recurring Trn',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xff26262B), // dark900
                          fontFamily: fontFamily,
                        ),
                      ),
                      if (categoryName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          categoryName!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xff686878), // dark600
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                AmountCurrencyWidget(
                  amount: '-${recurringTransactionAmount.toStringAsFixed(3)}',
                  fontSize: 24,
                  amountFontWeight: FontWeight.w600,
                  fontFamily: fontFamily,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Details section
            RoundedContainerWidget(
              color: const Color(0xfff6f4fe), // mePurple25
              content: Column(
                children: [
                  _buildAmountDetailRow('Overall you spent', '${overallSpentAmount.toStringAsFixed(3)}'),
                  const SizedBox(height: 16),
                  _buildDetailRow('Transactions', '$numberOfTransactions times'),
                  const SizedBox(height: 16),
                  _buildDetailRow('First payment', _formatDate(firstPaymentDate)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Next payment', _formatDate(expectedNextPaymentDate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: const Color(0xff686878), // dark600
              fontFamily: fontFamily,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w300,
            color: const Color(0xff0f0f0f), // dark1000
            fontFamily: fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: const Color(0xff686878), // dark600
              fontFamily: fontFamily,
            ),
          ),
        ),
        AmountCurrencyWidget(
          amount: value,
          fontSize: 16,
          amountFontWeight: FontWeight.w500,
          fontFamily: fontFamily,
        ),
      ],
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
      case 'food':
        return Icons.restaurant;
      case 'coffee':
        return Icons.local_cafe;
      case 'entertainment':
        return Icons.sports_esports;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.local_hospital;
      case 'fitness':
        return Icons.fitness_center;
      case 'real estate':
        return Icons.home;
      case 'investment':
        return Icons.trending_up;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.store;
    }
  }

  String _formatDate(String dateString) {
    try {
      // Try parsing as yyyy-MM-dd first (as per me-card-app Application.dateFormat)
      DateFormat inputFormat = DateFormat("yyyy-MM-dd");
      DateTime? date = inputFormat.tryParse(dateString);
      
      // If that fails, try standard DateTime.parse
      if (date == null) {
        date = DateTime.tryParse(dateString);
      }
      
      // Format as dd MMM yyyy (as per me-card-app Application.friendlyDateFormat2)
      if (date != null) {
        DateFormat outputFormat = DateFormat("dd MMM yyyy");
        return outputFormat.format(date);
      }
      
      return dateString;
    } catch (e) {
      return dateString;
    }
  }
}

