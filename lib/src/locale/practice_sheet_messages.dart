import '../../l10n/app_localizations.dart';

/// 字帖生成提示（由 UI 层根据 [AppLocalizations] 渲染为文案）。
sealed class PracticeSheetMessage {
  const PracticeSheetMessage();
}

class HintEmptyInput extends PracticeSheetMessage {
  const HintEmptyInput();
}

class HintDictionaryLoadFailed extends PracticeSheetMessage {
  const HintDictionaryLoadFailed(this.error);
  final Object error;
}

class HintInvalidInput extends PracticeSheetMessage {
  const HintInvalidInput();
}

class HintNoMatchingChars extends PracticeSheetMessage {
  const HintNoMatchingChars(this.dictionaryPath);
  final String dictionaryPath;
}

class HintMissingChars extends PracticeSheetMessage {
  const HintMissingChars(this.chars);
  final List<String> chars;
}

class HintSkippedOverflow extends PracticeSheetMessage {
  const HintSkippedOverflow({
    required this.maxRows,
    required this.skipped,
  });
  final int maxRows;
  final int skipped;
}

class HintPhysicalOverflow extends PracticeSheetMessage {
  const HintPhysicalOverflow({
    required this.usedRows,
    required this.maxRows,
  });
  final int usedRows;
  final int maxRows;
}

String formatPracticeSheetMessages(
  AppLocalizations l10n,
  List<PracticeSheetMessage> messages,
) {
  if (messages.isEmpty) return '';
  return messages
      .map((m) => _formatOne(l10n, m))
      .join(l10n.hintSeparator);
}

String _formatOne(AppLocalizations l10n, PracticeSheetMessage message) {
  return switch (message) {
    HintEmptyInput() => l10n.hintEmptyInput,
    HintDictionaryLoadFailed(:final error) =>
      l10n.hintDictionaryLoadFailed('$error'),
    HintInvalidInput() => l10n.hintInvalidInput,
    HintNoMatchingChars(:final dictionaryPath) =>
      l10n.hintNoMatchingChars(dictionaryPath),
    HintMissingChars(:final chars) =>
      l10n.hintMissingChars(chars.join(l10n.listSeparator)),
    HintSkippedOverflow(:final maxRows, :final skipped) =>
      l10n.hintSkippedOverflow(maxRows, skipped),
    HintPhysicalOverflow(:final usedRows, :final maxRows) =>
      l10n.hintPhysicalOverflow(usedRows, maxRows),
  };
}
