import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/meai_localizations.dart';
import '../utils/text_direction_utils.dart';
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
  final TextDirection? textDirection;

  /// Language code ('en' or 'ar') used to localise card widget labels.
  final String lang;

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
    this.textDirection,
    this.lang = 'en',
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
          final text = segment.text!;
          final dir = widget.textDirection ?? textDirectionForContent(text);
          return Text(text, style: widget.style, textDirection: dir);
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
      
      Widget? customWidget = _getCustomWidgetByIndex(objectIndex);

      if (customWidget != null) {
        usedObjectIndices.add(objectIndex);
        segments.add(TextSegment.widget(customWidget));
      } else {
        // If no custom widget found, remove the placeholder from the text
        // Don't add anything to segments, effectively removing it
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
          final built = _buildWidgetFromTypeAndData(customObjectsTypes[i], customObjects[i]);
          if (built != null) segments.add(TextSegment.widget(built));
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
            final built = _buildWidgetFromTypeAndData(customObjectsTypes[key], customObjects[key]);
            if (built != null) segments.add(TextSegment.widget(built));
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

    try {
      // Handle List format
      if (customObjects is List && customObjectsTypes is List) {
        if (index >= 0 && index < customObjects.length && index < customObjectsTypes.length) {
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
    } catch (e) {
      // If there's an error building the widget, return null to fall back to default
      return null;
    }

    return null;
  }

  /// Helper function to safely convert a value to double.
  /// Handles both num and String containing numbers.
  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Builds a card widget from the given [type] and [data].
  /// Returns null if critical fields are missing or the data cannot be rendered safely,
  /// so callers can skip the object entirely rather than show a broken widget.
  Widget? _buildWidgetFromTypeAndData(dynamic type, dynamic data) {
    try {
      // Delegate to the host app's custom builder first.
      if (widget.customObjectWidgetBuilder != null) {
        final objectType = type.toString().toUpperCase();
        final customWidget = widget.customObjectWidgetBuilder!(objectType, data);
        if (customWidget != null) return customWidget;
      }

      // All built-in types require data to be a Map.
      if (data is! Map) return null;

      final widgetType = type.toString().toUpperCase();

      switch (widgetType) {
        case 'TRANSACTION':
          // amount must be parseable to avoid a meaningless zero-value card.
          if (_parseToDouble(data['amount']) == null) return null;
          return TransactionCard(
            merchantImageUrl: data['merchantImageUrl'] as String?,
            categoryName: data['categoryName'] as String?,
            merchantName: data['merchantName'] as String?,
            transactionDescription: data['transactionDescription'] as String?,
            categoryImageUrl: data['categoryImageUrl'] as String?,
            entryType: data['entryType'] as String?,
            amount: _parseToDouble(data['amount'])!,
            currency: data['currency'] as String? ?? 'BHD',
            fontFamily: widget.fontFamily,
            lang: widget.lang,
          );

        case 'RECURRING_TRANSACTION':
          // Core financial figures and dates are required.
          if (_parseToDouble(data['recurringTransactionAmount']) == null) return null;
          if (_parseToDouble(data['overallSpentAmount']) == null) return null;
          if (data['firstPaymentDate'] == null || data['expectedNextPaymentDate'] == null) return null;
          return RecurringTransactionCard(
            merchantImageUrl: data['merchantImageUrl'] as String?,
            merchantName: data['merchantName'] as String?,
            categoryName: data['categoryName'] as String?,
            recurringTransactionAmount: _parseToDouble(data['recurringTransactionAmount'])!,
            currency: data['currency'] as String? ?? 'BHD',
            overallSpentAmount: _parseToDouble(data['overallSpentAmount'])!,
            numberOfTransactions: data['numberOfTransactions'] as int? ?? 0,
            firstPaymentDate: data['firstPaymentDate'].toString(),
            expectedNextPaymentDate: data['expectedNextPaymentDate'].toString(),
            fontFamily: widget.fontFamily,
            lang: widget.lang,
          );

        case 'SAVING_GOAL':
          // All three amounts are required to render a meaningful progress bar.
          if (_parseToDouble(data['amountSaved']) == null) return null;
          if (_parseToDouble(data['amountRemaining']) == null) return null;
          if (_parseToDouble(data['targetAmount']) == null) return null;
          return SavingGoalCard(
            name: data['name'] as String? ?? MeAiLocalizations.savingsGoal(widget.lang),
            imageUrl: data['imageUrl'] as String?,
            amountSaved: _parseToDouble(data['amountSaved'])!,
            amountRemaining: _parseToDouble(data['amountRemaining'])!,
            targetAmount: _parseToDouble(data['targetAmount'])!,
            targetDate: data['targetDate'] as String? ?? '',
            fontFamily: widget.fontFamily,
            lang: widget.lang,
          );

        case 'INVESTMENT':
          // expectedProfitRate is the primary metric of this card.
          if (_parseToDouble(data['expectedProfitRate']) == null) return null;
          return InvestmentCard(
            title: data['title'] as String? ?? MeAiLocalizations.investment(widget.lang),
            imageUrl: data['imageUrl'] as String?,
            period: data['period'] as String?,
            expectedProfitRate: _parseToDouble(data['expectedProfitRate'])!,
            amount: _parseToDouble(data['amount']),
            expectedProfitAtMaturity: _parseToDouble(data['expectedProfitAtMaturity']),
            amountAtMaturityWithProfit: _parseToDouble(data['amountAtMaturityWithProfit']),
            fontFamily: widget.fontFamily,
            lang: widget.lang,
          );

        case 'AMOUNT_VALUE':
          // The entire purpose of this card is to display an amount.
          if (_parseToDouble(data['amount']) == null) return null;
          return AmountValueCard(
            title: data['title'] as String? ?? MeAiLocalizations.amount(widget.lang),
            imageUrl: data['imageUrl'] as String?,
            amount: _parseToDouble(data['amount'])!,
            currency: data['currency'] as String? ?? 'BHD',
            fontFamily: widget.fontFamily,
          );

        case 'SPENDING_LIMIT_ALERT':
          // descriptionOfCurrentStatus is non-nullable in the widget constructor.
          // Both limit figures are required for the progress bar.
          if (data['descriptionOfCurrentStatus'] == null) return null;
          if (_parseToDouble(data['limitAmountOnCategory']) == null) return null;
          if (_parseToDouble(data['currentSpendOnCategory']) == null) return null;
          return SpendingLimitAlertCard(
            customerName: data['customerName'] as String? ?? MeAiLocalizations.customer(widget.lang),
            customerImageUrl: data['customerImageUrl'] as String? ?? '',
            categoryImageUrl: data['categoryImageUrl'] as String?,
            categoryName: data['categoryName'] as String?,
            descriptionOfCurrentStatus: data['descriptionOfCurrentStatus'].toString(),
            currency: data['currency'] as String? ?? 'BHD',
            limitAmountOnCategory: _parseToDouble(data['limitAmountOnCategory'])!,
            currentSpendOnCategory: _parseToDouble(data['currentSpendOnCategory'])!,
            fontFamily: widget.fontFamily,
            lang: widget.lang,
          );

        case 'LIST_OF_TRANSACTIONS':
          // A non-empty list of transactions is required.
          final rawList = data['transactions'];
          if (rawList is! List || rawList.isEmpty) return null;
          return ListOfTransactionsCard(
            transactions: rawList.cast<Map<String, dynamic>>(),
            fontFamily: widget.fontFamily,
            lang: widget.lang,
          );

        case 'TABLE':
          final rowsData = data['tableRows'];
          if (rowsData is! List) return null;
          final tableRows = rowsData
              .map<List<String>>((row) {
                if (row is List) return row.map((c) => c.toString()).toList();
                if (row is Map) return row.values.map((c) => c.toString()).toList();
                return <String>[];
              })
              .where((row) => row.isNotEmpty)
              .toList();
          if (tableRows.isEmpty) return null;
          return TableCard(tableRows: tableRows, fontFamily: widget.fontFamily);

        default:
          return null;
      }
    } catch (e) {
      debugPrint('MeAi: skipping custom object — error building widget ($type): $e');
      return null;
    }
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
          final dir = widget.textDirection ?? textDirectionForContent(text);
          if (_visibleWidgets.isEmpty || _visibleWidgets.last is! Text) {
            // Add new text widget if last item is not text
            _visibleWidgets.add(Text(visibleText, style: widget.style, textDirection: dir));
          } else {
            // Replace last text widget with updated version
            _visibleWidgets[_visibleWidgets.length - 1] = Text(visibleText, style: widget.style, textDirection: dir);
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
        final maxScroll = widget.scrollController.position.maxScrollExtent;
        if (maxScroll.isFinite && maxScroll >= 0) {
          widget.scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
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
    final isRtl = (widget.textDirection ?? textDirectionForContent(widget.fullText)) == TextDirection.rtl;
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: _visibleWidgets,
      ),
    );
  }
}

