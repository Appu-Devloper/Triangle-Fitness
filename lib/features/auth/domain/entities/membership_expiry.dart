int? daysUntilMembershipExpiry(DateTime? endDate, DateTime now) {
  if (endDate == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  final endDay = DateTime(endDate.year, endDate.month, endDate.day);
  return endDay.difference(today).inDays;
}

String membershipExpiryCountdown(DateTime? endDate, DateTime now) {
  final days = daysUntilMembershipExpiry(endDate, now);
  if (days == null) return 'Not available';
  if (days == 0) return 'Today';
  if (days == 1) return '1 day';
  if (days > 1) return '$days days';
  if (days == -1) return 'Expired 1 day ago';
  return 'Expired ${days.abs()} days ago';
}

String membershipExpirySummary(DateTime? endDate, DateTime now) {
  final days = daysUntilMembershipExpiry(endDate, now);
  if (days == null) return 'Expiry unavailable';
  if (days < 0) {
    final elapsed = days.abs();
    return elapsed == 1 ? 'Expired 1 day ago' : 'Expired $elapsed days ago';
  }
  if (days == 0) return 'Ends today';
  if (days == 1) return '1 day remaining';
  return '$days days remaining';
}
