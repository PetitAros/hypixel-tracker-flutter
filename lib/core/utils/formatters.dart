class Formatters {
  Formatters._();

  // 1234.5 -> "1.2k", 2500000 -> "2.50M", 12.34 -> "12.3"
  static String compact(num value) {
    final abs = value.abs();
    if (abs >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
    if (abs >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
    if (abs >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}k';
    return value is int ? '$value' : value.toStringAsFixed(1);
  }

  // "2d 4h", "3h 12m", "12m", "Ended"
  static String timeLeft(Duration value) {
    if (value <= Duration.zero) return 'Ended';
    if (value.inDays > 0) return '${value.inDays}d ${value.inHours % 24}h';
    if (value.inHours > 0) return '${value.inHours}h ${value.inMinutes % 60}m';
    if (value.inMinutes > 0) return '${value.inMinutes}m';
    return '<1m';
  }

  // "b876ec32e396476ba1158438d83c67d4" -> "b876ec32-e396-476b-a115-8438d83c67d4"
  // Mojang sends UUIDs without dashes; anything else is returned unchanged.
  static String uuid(String value) {
    if (value.length != 32) return value;
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  // "09/10 14:05"
  static String dateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
