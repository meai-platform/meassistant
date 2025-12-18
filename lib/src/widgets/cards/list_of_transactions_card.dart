import 'package:flutter/material.dart';
import 'amount_currency_widget.dart';

/// List of transactions card widget
class ListOfTransactionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String? fontFamily;

  const ListOfTransactionsCard({
    super.key,
    required this.transactions,
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
            // Transaction items
            ...transactions.map<Widget>((transaction) {
              String? merchantImageUrl = transaction['merchantImageUrl'] as String?;
              String? categoryName = transaction['categoryName'] as String?;
              double? amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
              String? currency = transaction['currency'] as String? ?? 'BHD';
              String? merchantName = transaction['merchantName'] as String?;
              String? transactionDescription = transaction['transactionDescription'] as String?;
              String? categoryImageUrl = transaction['categoryImageUrl'] as String?;
              String? entryType = transaction['entryType'] as String?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      child: merchantImageUrl != null || categoryImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                merchantImageUrl ?? categoryImageUrl!,
                                width: 30,
                                height: 30,
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFED401).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.account_balance_wallet, size: 18),
                                  );
                                },
                              ),
                            )
                          : ClipOval(
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFED401).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_balance_wallet, size: 18),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchantName ?? transactionDescription ?? 
                            '${entryType != null && entryType!.toLowerCase() == 'd' ? 'Debit' : 'Credit'} transaction',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff26262B), // dark900
                              fontFamily: fontFamily,
                            ),
                          ),
                          if (categoryName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              categoryName!,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xff686878), // dark600
                                fontWeight: FontWeight.w300,
                                fontFamily: fontFamily,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AmountCurrencyWidget(
                      amount: '${entryType != null && entryType!.toLowerCase() == 'd' ? '-' : ''}${amount.toStringAsFixed(3)}',
                      fontSize: 18,
                      amountFontWeight: FontWeight.w500,
                      amountColor: const Color(0xff26262B), // dark900
                      fontFamily: fontFamily,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

