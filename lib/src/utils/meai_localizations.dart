/// Localization strings for the MeAi Assistant SDK.
/// Supports English (en) and Arabic (ar) languages.
class MeAiLocalizations {
  const MeAiLocalizations._();

  static bool _isAr(String lang) => lang == 'ar';

  // ── Modal / Chat UI ───────────────────────────────────────────────────────

  static String analyzingMessage(String lang) =>
      _isAr(lang) ? 'جاري تحليل رسالتك' : 'Analyzing your message';

  static String fetchingData(String lang) =>
      _isAr(lang) ? 'جاري جلب البيانات الشخصية' : 'Fetching personalized relevant data';

  static String analyzingData(String lang) =>
      _isAr(lang) ? 'جاري تحليل البيانات' : 'Analyzing data';

  static String preparingResponse(String lang) =>
      _isAr(lang) ? 'جاري تحضير الإجابة النهائية' : 'Preparing final response';

  static String footerText(String lang) => _isAr(lang)
      ? 'أنت تتحدث مع مساعد مالي ذكاء اصطناعي - مدعوم من me.Ai'
      : "You're chatting with an AI Financial Assistant - Powered by me.Ai";

  // ── Default config strings ────────────────────────────────────────────────

  static String defaultIntroText(String lang) => _isAr(lang)
      ? 'مرحباً! أنا مساعدك المالي الذكي.'
      : "Hello! I'm your smart money assistant.";

  static String defaultTextFieldHint(String lang) =>
      _isAr(lang) ? 'اسألني شيئاً...' : 'Ask something...';

  // ── Recurring transaction card ────────────────────────────────────────────

  static String recurringTrn(String lang) =>
      _isAr(lang) ? 'معاملة متكررة' : 'Recurring Trn';

  static String overallYouSpent(String lang) =>
      _isAr(lang) ? 'إجمالي ما أنفقت' : 'Overall you spent';

  static String transactions(String lang) =>
      _isAr(lang) ? 'المعاملات' : 'Transactions';

  static String timesCount(String lang, int count) =>
      _isAr(lang) ? '$count مرة' : '$count times';

  static String firstPayment(String lang) =>
      _isAr(lang) ? 'أول دفعة' : 'First payment';

  static String nextPayment(String lang) =>
      _isAr(lang) ? 'الدفعة القادمة' : 'Next payment';

  // ── Saving goal card ──────────────────────────────────────────────────────

  static String saved(String lang) => _isAr(lang) ? 'محفوظ' : 'SAVED';

  static String goal(String lang) => _isAr(lang) ? 'الهدف' : 'GOAL';

  static String remaining(String lang) => _isAr(lang) ? 'المتبقي' : 'Remaining';

  static String savingsGoal(String lang) =>
      _isAr(lang) ? 'هدف الادخار' : 'Savings Goal';

  // ── Investment card ───────────────────────────────────────────────────────

  static String investment(String lang) =>
      _isAr(lang) ? 'استثمار' : 'Investment';

  static String period(String lang) => _isAr(lang) ? 'الفترة' : 'Period';

  static String expectedProfitRate(String lang) =>
      _isAr(lang) ? 'معدل الربح المتوقع' : 'Expected profit rate';

  static String amount(String lang) => _isAr(lang) ? 'المبلغ' : 'Amount';

  static String profitAtMaturity(String lang) =>
      _isAr(lang) ? 'الربح عند الاستحقاق' : 'Profit at maturity';

  static String expectedAmountWithProfitAtMaturity(String lang) =>
      _isAr(lang)
          ? 'المبلغ المتوقع مع الربح عند الاستحقاق'
          : 'Expected amount with profit at maturity';

  // ── Spending limit alert card ─────────────────────────────────────────────

  static String categoryLimit(String lang) =>
      _isAr(lang) ? 'حد الفئة' : 'Category limit';

  static String spent(String lang) => _isAr(lang) ? 'أُنفق' : 'SPENT';

  static String limit(String lang) => _isAr(lang) ? 'الحد' : 'LIMIT';

  static String overspent(String lang) =>
      _isAr(lang) ? 'تجاوز الحد' : 'Overspent';

  // ── Transaction cards ─────────────────────────────────────────────────────

  static String debit(String lang) => _isAr(lang) ? 'مدين' : 'Debit';

  static String credit(String lang) => _isAr(lang) ? 'دائن' : 'Credit';

  static String transactionSuffix(String lang) =>
      _isAr(lang) ? ' معاملة' : ' transaction';

  static String customer(String lang) => _isAr(lang) ? 'العميل' : 'Customer';
}
