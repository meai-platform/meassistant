import 'dart:async';
import 'package:flutter/material.dart';
import '../models/assistant_response.dart';
import 'cards/transaction_card.dart';
import 'cards/recurring_transaction_card.dart';
import 'cards/saving_goal_card.dart';
import 'cards/investment_card.dart';
import 'cards/amount_value_card.dart';
import 'cards/spending_limit_alert_card.dart';
import 'cards/list_of_transactions_card.dart';
import 'cards/table_card.dart';

/// Text segment that can be either text or a widget
class TextSegment {
  final String? text;
  final Widget? widget;
  final bool isWidget;

  TextSegment.text(this.text)
      : widget = null,
        isWidget = false;
  TextSegment.widget(this.widget)
      : text = null,
        isWidget = true;
}

/// Widget that displays text with a typing animation effect and supports custom objects
class TypingText extends StatefulWidget {
  final String fullText;
  final Duration speed;
  final TextStyle? style;
  final ScrollController scrollController;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;
  final bool showFullContentImmediately;
  final AssistantResponse? assistantResponse;
  final Widget? Function(String objectType, dynamic objectData)? customObjectWidgetBuilder;
  final String? fontFamily;

  const TypingText({
    super.key,
    required this.fullText,
    required this.scrollController,
    this.speed = const Duration(milliseconds: 35),
    this.style,
    this.onComplete,
    this.onStart,
    this.showFullContentImmediately = false,
    this.assistantResponse,
    this.customObjectWidgetBuilder,
    this.fontFamily,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  List<TextSegment> _segments = [];
  List<Widget> _visibleWidgets = [];
  Timer? _timer;
  int _currentSegmentIndex = 0;
  int _currentCharIndex = 0;
  bool _started = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _parseTextWithPlaceholders();
    if (widget.showFullContentImmediately) {
      _showFullContentImmediately();
    } else {
      _startTyping();
    }
  }

  void _showFullContentImmediately() {
    setState(() {
      _visibleWidgets = _segments.map((segment) {
        if (segment.isWidget) {
          return segment.widget!;
        } else {
          return Text(segment.text!, style: widget.style);
        }
      }).toList();
      _completed = true;
    });
  }

  void _parseTextWithPlaceholders() {
    String remainingText = widget.fullText;
    List<TextSegment> segments = [];
    Set<int> usedObjectIndices = {};

    // Find all placeholders in the format #OBJ1#, #OBJ2#, etc.
    RegExp placeholderRegex = RegExp(r'#OBJ(\d+)#(\.?)(,?)( ?)');

    int lastEnd = 0;
    for (Match match in placeholderRegex.allMatches(remainingText)) {
      // Add text before the placeholder
      if (match.start > lastEnd) {
        String textBefore = remainingText.substring(lastEnd, match.start);
        if (textBefore.isNotEmpty) {
          segments.add(TextSegment.text(textBefore));
        }
      }

      // Get the object index from the placeholder
      int objectIndex = int.parse(match.group(1)!) - 1; // Convert to 0-based index
      usedObjectIndices.add(objectIndex);

      Widget? customWidget = _getCustomWidgetByIndex(objectIndex);

      if (customWidget != null) {
        segments.add(TextSegment.widget(customWidget));
      } else {
        // If no custom widget found, keep the placeholder as text
        segments.add(TextSegment.text(match.group(0)!));
      }

      lastEnd = match.end;
    }

    // Add remaining text after the last placeholder
    if (lastEnd < remainingText.length) {
      String textAfter = remainingText.substring(lastEnd);
      if (textAfter.isNotEmpty) {
        segments.add(TextSegment.text(textAfter));
      }
    }

    // Add any unused objects at the end
    _addUnusedObjectsAtEnd(segments, usedObjectIndices);

    // If no placeholders found, treat entire text as one segment
    if (segments.isEmpty) {
      segments.add(TextSegment.text(widget.fullText));
    }

    _segments = segments;
  }

  void _addUnusedObjectsAtEnd(List<TextSegment> segments, Set<int> usedObjectIndices) {
    if (widget.assistantResponse == null) return;

    final customObjects = widget.assistantResponse!.customObjects;
    final customObjectsTypes = widget.assistantResponse!.customObjectsTypes;

    if (customObjects == null || customObjectsTypes == null) return;

    // Handle List format
    if (customObjects is List && customObjectsTypes is List) {
      for (int i = 0; i < customObjects.length && i < customObjectsTypes.length; i++) {
        if (!usedObjectIndices.contains(i)) {
          Widget widget = _buildWidgetFromTypeAndData(customObjectsTypes[i], customObjects[i]);
          segments.add(TextSegment.widget(widget));
        }
      }
    }
    // Handle Map format (if objects are stored as maps with numeric keys)
    else if (customObjects is Map && customObjectsTypes is Map) {
      // Sort keys to maintain order
      List<String> sortedKeys = customObjects.keys.map((k) => k.toString()).toList()..sort();

      for (int i = 0; i < sortedKeys.length; i++) {
        if (!usedObjectIndices.contains(i)) {
          String key = sortedKeys[i];
          if (customObjects.containsKey(key) && customObjectsTypes.containsKey(key)) {
            Widget widget = _buildWidgetFromTypeAndData(customObjectsTypes[key], customObjects[key]);
            segments.add(TextSegment.widget(widget));
          }
        }
      }
    }
  }

  Widget? _getCustomWidgetByIndex(int index) {
    if (widget.assistantResponse == null) return null;

    final customObjects = widget.assistantResponse!.customObjects;
    final customObjectsTypes = widget.assistantResponse!.customObjectsTypes;

    if (customObjects == null || customObjectsTypes == null) return null;

    // Handle List format
    if (customObjects is List && customObjectsTypes is List) {
      if (index < customObjects.length && index < customObjectsTypes.length) {
        return _buildWidgetFromTypeAndData(customObjectsTypes[index], customObjects[index]);
      }
    }
    // Handle Map format with numeric keys
    else if (customObjects is Map && customObjectsTypes is Map) {
      String key = index.toString();
      if (customObjects.containsKey(key) && customObjectsTypes.containsKey(key)) {
        return _buildWidgetFromTypeAndData(customObjectsTypes[key], customObjects[key]);
      }
    }

    return null;
  }

  Widget _buildWidgetFromTypeAndData(dynamic type, dynamic data) {
    // Use custom widget builder if provided
    if (widget.customObjectWidgetBuilder != null) {
      String objectType = type.toString().toUpperCase();
      Widget? customWidget = widget.customObjectWidgetBuilder!(objectType, data);
      if (customWidget != null) {
        return customWidget;
      }
    }

    // Use default card widgets based on type
    String widgetType = type.toString().toUpperCase();
    
    switch (widgetType) {
      case 'TRANSACTION':
        return TransactionCard(
          merchantImageUrl: data['merchantImageUrl'] as String?,
          categoryName: data['categoryName'] as String?,
          merchantName: data['merchantName'] as String?,
          transactionDescription: data['transactionDescription'] as String?,
          categoryImageUrl: data['categoryImageUrl'] as String?,
          entryType: data['entryType'] as String?,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          currency: data['currency'] as String? ?? 'BHD',
          fontFamily: widget.fontFamily,
        );

      case 'RECURRING_TRANSACTION':
        return RecurringTransactionCard(
          merchantImageUrl: data['merchantImageUrl'] as String?,
          merchantName: data['merchantName'] as String?,
          categoryName: data['categoryName'] as String?,
          recurringTransactionAmount: (data['recurringTransactionAmount'] as num?)?.toDouble() ?? 0.0,
          currency: data['currency'] as String? ?? 'BHD',
          overallSpentAmount: (data['overallSpentAmount'] as num?)?.toDouble() ?? 0.0,
          numberOfTransactions: data['numberOfTransactions'] as int? ?? 0,
          firstPaymentDate: data['firstPaymentDate'] as String? ?? '',
          expectedNextPaymentDate: data['expectedNextPaymentDate'] as String? ?? '',
          fontFamily: widget.fontFamily,
        );

      case 'SAVING_GOAL':
        return SavingGoalCard(
          name: data['name'] as String? ?? 'Savings Goal',
          imageUrl: data['imageUrl'] as String?,
          amountSaved: (data['amountSaved'] as num?)?.toDouble() ?? 0.0,
          amountRemaining: (data['amountRemaining'] as num?)?.toDouble() ?? 0.0,
          targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
          targetDate: data['targetDate'] as String? ?? '',
          fontFamily: widget.fontFamily,
        );

      case 'INVESTMENT':
        return InvestmentCard(
          title: data['title'] as String? ?? 'Investment',
          imageUrl: data['imageUrl'] as String?,
          period: data['period'] as String?,
          expectedProfitRate: (data['expectedProfitRate'] as num?)?.toDouble() ?? 0.0,
          amount: (data['amount'] as num?)?.toDouble(),
          expectedProfitAtMaturity: (data['expectedProfitAtMaturity'] as num?)?.toDouble(),
          amountAtMaturityWithProfit: (data['amountAtMaturityWithProfit'] as num?)?.toDouble(),
          fontFamily: widget.fontFamily,
        );

      case 'AMOUNT_VALUE':
        return AmountValueCard(
          title: data['title'] as String? ?? 'Amount',
          imageUrl: data['imageUrl'] as String?,
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          currency: data['currency'] as String? ?? 'BHD',
          fontFamily: widget.fontFamily,
        );

      case 'SPENDING_LIMIT_ALERT':
        return SpendingLimitAlertCard(
          customerName: data['customerName'] as String? ?? 'Customer',
          customerImageUrl: data['customerImageUrl'] as String? ?? '',
          categoryImageUrl: data['categoryImageUrl'] as String?,
          categoryName: data['categoryName'] as String?,
          descriptionOfCurrentStatus: data['descriptionOfCurrentStatus'] as String,
          currency: data['currency'] as String? ?? 'BHD',
          limitAmountOnCategory: (data['limitAmountOnCategory'] as num?)?.toDouble() ?? 0.0,
          currentSpendOnCategory: (data['currentSpendOnCategory'] as num?)?.toDouble() ?? 0.0,
          fontFamily: widget.fontFamily,
        );

      case 'LIST_OF_TRANSACTIONS':
        return ListOfTransactionsCard(
          transactions: (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [],
          fontFamily: widget.fontFamily,
        );

      case 'TABLE':
        // Convert tableRows to List<List<String>>
        List<List<String>> tableRows = [];
        if (data['tableRows'] != null && data['tableRows'] is List) {
          tableRows = (data['tableRows'] as List).map((row) {
            if (row is List) {
              return row.map((cell) => cell.toString()).toList();
            }
            return <String>[];
          }).toList();
        }
        return TableCard(
          tableRows: tableRows,
          fontFamily: widget.fontFamily,
        );

      default:
        return _buildDefaultWidget(data);
    }
  }

  Widget _buildDefaultWidget(dynamic data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        data.toString(),
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (!_started) {
        _started = true;
        widget.onStart?.call();
      }

      bool didAddSomething = false;
      if (_currentSegmentIndex >= _segments.length) {
        // Finished all segments
        timer.cancel();
        if (!_completed) {
          _completed = true;
          widget.onComplete?.call();
        }
        return;
      }

      final currentSegment = _segments[_currentSegmentIndex];

      if (currentSegment.isWidget) {
        // Directly add widget segment
        _visibleWidgets.add(currentSegment.widget!);
        _currentSegmentIndex++;
        _currentCharIndex = 0;
        didAddSomething = true;
      } else {
        // Typing a text segment
        final text = currentSegment.text!;
        if (_currentCharIndex < text.length) {
          final visibleText = text.substring(0, _currentCharIndex + 1);
          if (_visibleWidgets.isEmpty || _visibleWidgets.last is! Text) {
            // Add new text widget if last item is not text
            _visibleWidgets.add(Text(visibleText, style: widget.style));
          } else {
            // Replace last text widget with updated version
            _visibleWidgets[_visibleWidgets.length - 1] = Text(visibleText, style: widget.style);
          }

          _currentCharIndex++;
          didAddSomething = true;
        } else {
          // Finished this text segment
          _currentSegmentIndex++;
          _currentCharIndex = 0;
        }
      }

      if (didAddSomething) {
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _visibleWidgets,
    );
  }
}

