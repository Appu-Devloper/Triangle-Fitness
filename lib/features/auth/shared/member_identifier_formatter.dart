const memberCodePrefix = 'TF';
const receiptNoPrefix = 'REC-';
String editableMemberCodeValue(String value) {
  final normalized = normalizeMemberCode(value);
  return normalized.startsWith(memberCodePrefix)
      ? normalized.substring(memberCodePrefix.length)
      : normalized;
}
String editableReceiptNoValue(String value) {
  final normalized = normalizeReceiptNo(value);
  return normalized.startsWith(receiptNoPrefix)
      ? normalized.substring(receiptNoPrefix.length)
      : normalized;
}

String normalizeMemberCode(
  String value, {
  bool keepPrefixOnEmpty = false,
}) {
  final text = value.trim().toUpperCase();
  if (text.isEmpty) return keepPrefixOnEmpty ? memberCodePrefix : '';
  final suffix = text.replaceFirst(RegExp(r'^TF[-\s_]*'), '');
  return suffix.isEmpty && keepPrefixOnEmpty
      ? memberCodePrefix
      : '$memberCodePrefix$suffix';
}

String normalizeReceiptNo(
  String value, {
  bool keepPrefixOnEmpty = false,
}) {
  final text = value.trim().toUpperCase();
  if (text.isEmpty) return keepPrefixOnEmpty ? receiptNoPrefix : '';
  final suffix = text.replaceFirst(RegExp(r'^REC[-\s_]*'), '');
  return suffix.isEmpty && keepPrefixOnEmpty
      ? receiptNoPrefix
      : '$receiptNoPrefix$suffix';
}

bool hasMeaningfulMemberCode(String value) =>
    normalizeMemberCode(value).length > memberCodePrefix.length;

bool hasMeaningfulReceiptNo(String value) =>
    normalizeReceiptNo(value).length > receiptNoPrefix.length;

String memberAuthPasswordFromReceipt(String value) {
  final normalized = normalizeReceiptNo(value);
  if (normalized.length >= 6) return normalized;
  return normalized.padRight(6, '0');
}

List<String> receiptPasswordCandidates(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return const [];
  final normalized = normalizeReceiptNo(trimmed);
  final derived = memberAuthPasswordFromReceipt(trimmed);
  final candidates = <String>[];
  for (final candidate in [derived, trimmed, normalized]) {
    if (candidate.isEmpty) continue;
    if (!candidates.contains(candidate)) candidates.add(candidate);
  }
  return candidates;
}

